package RoundTrips;
use strict;
use warnings FATAL => 'all';
use Carp;
use Getopt::Long qw(:config pass_through);

use Metric;
use base qw(LogReader);

# Constructor
# Usage: my $obj = new RoundTrips();
sub new {
    my ($target) = @_;
    my $class = ref($target) || $target;
    my $this = $class->SUPER::new();

    return $this;
}

# Method: parseCommandLineArgs
# Usage : $m->parseCommandLineArgs();
sub parseCommandLineArgs {
    my ($this) = @_;

    my $thresholds = '1000,5000,10000';
    GetOptions(
        'thresholds=s' => \$thresholds
    );
    $this->thresholds( LogReader::trim($thresholds) );
    $this->SUPER::parseCommandLineArgs();
}

# Property: thresholds
# Usage   : $m->thresholds('100,500,1000')
# Remarks : Histogram buckets
sub thresholds {
    my ($this, $value) = @_;

    if (defined $value) {
        my @buckets = split /,/, $value;
        unshift @buckets, 0 unless $buckets[0] == 0; #ensure there is a '0' first
        $this->{thresholds} = \@buckets;
    }
    return $this->{thresholds};
}


# Method : processLine
# Usage  : $m->processLine($logline, $metrics)
# Remarks: Parses a single logfile line and populates the metrics
sub processLine {
    my ($this, $logline, $metrics) = @_;

    my %data = $this->extract($logline);
    return unless $data{success};
    return if $this->shouldSkip(\%data);

    $data{time} = int($data{time} / 1000.0 + 0.5);
    $data{uri} = $this->stripQueryPart($data{uri});
    $data{uri} = $this->normalizeUri($data{uri});
    $this->separateContext(\%data);

    $this->collectMetrics  ($metrics, $data{ctx}, $data{uri}, $data{time}, $data{code});
    $this->collectHistogram($metrics, $data{ctx}, $data{uri}, $data{time})
}


# Method  : extract
# Usage   : $m->extract($logline)
# Returns :
# Remarks : Extracts all 'relevant' payload parts from the logline
sub extract {
    my ($this, $logline) = @_;
    die 'empty log line' unless $logline;

    #131.177.117.139 - - [05/Dec/2016:08:17:30 +0100] "GET /loop54/v1/similarvideos?format=smooth_sd&fromIndex=0&oneCoverObjectId=1769852875&parental=true&playId=-1&toIndex=24 HTTP/1.1" 200 4860 "https://pilot.soneraviihde.fi/store/video/7125660" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko" 642304 "chyVYFJT8p7cfvn0nYY8JrvhtG9pG2Sb12D1RJVy1pMzh5h2x5SX!1738450180"
    my $REGEX = qr{\A
        (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})        #[1] 131.177.117.139
        [\s-]+                                      #' - - '
        \[([ +:/\d\w]+)\]                           #[2] [05/Dec/2016:08:17:30 +0100]
        \s"(\w+)\s([^"]+)\s[^"]+"                   #[3,4] "OP URI HTTPVERS"
        \s+(\d+)                                    #[5] CODE
        \s+(\d+)                                    #[6] TIME
        .+
        \z}x;

    if ($logline =~ $REGEX) {
        my %result;
        $result{success} = 1;
        $result{ip} = $1;
        $result{date} = $2;
        $result{op} = $3;
        $result{uri} = $4;
        $result{code} = $5;
        $result{time} = $6;
        return %result;
    }

    return (success => 0);
}

# Method  : shouldSkip
# Usage   : $m->shouldSkip(\%data)
# Returns : 1 IF skip current logline
# Remarks : checks if any of the data items indicates the logline should be skipped
sub shouldSkip {
    my ($this, $data) = @_;
    return 1 if $data->{uri} =~ qr{\A/\z}x;
    return 1 if $data->{uri} =~ qr{\A/assets/.+}x;
    return 1 if $data->{uri} =~ qr{\A/static/.+}x;
    return 1 if $data->{uri} =~ qr{\A/templates.+}x;
    return 1 if $data->{uri} =~ qr{\.json\z}x;
    return 1 if $data->{uri} =~ qr{\.js\z}x;
    return 1 if $data->{uri} =~ qr{\.css\z}x;

    return 0;
}

# Method  : stripQueryPart
# Usage   : $m->stripQueryPart($uri)
# Returns : URI without the ?suffix
# Remarks :
sub stripQueryPart {
    my ($this, $uri) = @_;
    my $pos = index $uri, '?';
    return $uri if $pos < 0;
    return substr $uri, 0, $pos;
}

# Method  : separateContext
# Usage   : $m->separateContext(\%data)
# Returns :
# Remarks : splits the $data{uri} into context and remaining uri
#           /ctx/uri/abc --> (/ctx, /uri/abc)
sub separateContext {
    my ($this, $data) = @_;
    my $uri = $data->{uri};

    my $pos = index $uri, '/', 1;
    if ($pos < 0) {
        $data->{ctx} = $uri;
        $data->{uri}     = '';
        return;
    }

    $data->{ctx} = substr $uri, 0, $pos;
    $data->{uri}     = substr $uri, $pos;
}

# Method  : normalizeUri
# Usage   : $m->normalizeUri($uri)
# Returns : URI stripped from numeric IDs
# Remarks :
sub normalizeUri {
    my ($this, $uri) = @_;
    $uri =~ s|/[\d,]+|/_|g;
    return $uri;
}

# Method  : collectMetrics
# Usage   : $m->collectMetrics($metrics, $context, $uri, $time, $code)
# Returns :
# Remarks : reports all non-histogram metrics.
#           $context    the first URI component
#           $uri        remaining part of the URI
#           $time       respons time in millisecs
#           $code       HTTP status code
sub collectMetrics {
    my ($this, $metrics, $ctx, $uri, $time, $code) = @_;

    $this->findMetric($metrics, "$ctx|$uri:Requests per Interval", 'PerIntervalCounter')->collect(1);
    $this->findMetric($metrics, "$ctx|$uri|StatusCode:$code"     , 'PerIntervalCounter')->collect(1);
    $this->findMetric($metrics, "$ctx|$uri:Average Time [ms]"    , 'IntAverage'        )->collect($time);

    $this->findMetric($metrics, "ALL:Requests per Interval"      , 'PerIntervalCounter')->collect(1);
    $this->findMetric($metrics, "ALL|StatusCode:$code"           , 'PerIntervalCounter')->collect(1);
    $this->findMetric($metrics, "ALL:Average Time [ms]"          , 'IntAverage'        )->collect($time);
}

# Method  : collectHistogram
# Usage   : $m->collectHistogram($metrics, $context, $uri, $time)
# Returns :
# Remarks : reports all histogram metrics.
#           $context    the first URI component
#           $uri        remaining part of the URI
#           $time       respons time in millisecs
sub collectHistogram {
    my ($this, $metrics, $ctx, $uri, $time) = @_;
    my @histogram  = @{ $this->thresholds() };
    my $numBuckets = $#histogram;

    for (my $k = $numBuckets; $k >= 0; $k--) {
        my $lowerBound = $histogram[$k];
        my $upperBound = ($k < $numBuckets) ? $histogram[$k + 1] : 'oo';

        if ($lowerBound <= $time) {
            my $name = "Time Distribution:H$k) $lowerBound - $upperBound [ms]";
            $this->findMetric($metrics, "$ctx|$uri|$name", 'PerIntervalCounter')->collect(1);
            $this->findMetric($metrics, "ALL|$name", 'PerIntervalCounter')->collect(1);
            return;
        }
    }
}




1;
