package LogReader;
use strict;
use warnings FATAL => 'all';
use Carp;
use Fcntl qw( SEEK_SET SEEK_END );
use Getopt::Long qw(:config pass_through);
use File::stat;

######################################
# Constructor
# ------------------------------------
sub new {
    my ($target) = @_;
    my $class    = ref($target) || $target;    
    my $this     = bless {}, $class;
    
    return $this;
}

sub parseCommandLineArgs {
    my ($this) = @_;
	
	my $file         = undef;
    my $pattern      = undef;
    my $url          = undef;
    my $dir          = '.';
    my $prefix       = 'AdaptableLogReader';
    my $debug        = 0;
    my $sleep        = 1;
	
	GetOptions(
        'file=s'            => \$file,
        'dir=s'             => \$dir,
        'pattern=s'         => \$pattern,
        'url:s'             => \$url,
        'prefix:s'          => \$prefix,
        'sleep:i'           => \$sleep,
        'debug!'            => \$debug,
    ); 
    
    $this->filename( trim($file) )   if defined $file;
    $this->pattern( trim($pattern) ) if defined $pattern;
    $this->url( trim($url) )         if defined $url;
    $this->dir( trim($dir) );
    $this->metricPrefix( trim($prefix) );
    $this->debug($debug);
    $this->sleep($sleep);
}

sub trim {
	my ($txt) = @_;
	$txt =~ s/^\'//;
	$txt =~ s/\'$//;
	$txt =~ s/^\"//;
	$txt =~ s/\"$//;
	return $txt;	
}

sub validate {
    my ($this) = @_;

    croak "No file name or pattern specified."
		if isBlank($this->filename) && isBlank($this->pattern);
		
    croak "Metric prefix must not be empty."
		if isBlank($this->metricPrefix);
}

######################################
# Properties
# ------------------------------------

# Name of file to read from (MANDATORY unless a pattern is defined)
sub filename {
    my ($this, $value) = @_;    
    if (defined $value) {
        croak "Cannot open logfile '$value'"  unless openable($value);
        $this->{filename} = $value;
    }
    return $this->{filename};
}

# File name pattern. 
# Used to scan the log dir for the latest file.
sub pattern {
	my ($this, $value) = @_;
	$this->{pattern}    = $value  if defined $value;
	return $this->{pattern};
}

# Log directory. 
# Used in combination with pattern to find the latest file.
sub dir {
	my ($this, $value) = @_;
	if (defined $value) {
        croak "Not a directory '$value'"  unless -d $value;
        $this->{dir} = $value;
    }
	return $this->{dir};
}

# Name of EPA URL to push metric data to, instead of writing to STDOUT.
sub url {
    my ($this, $value) = @_;
    $this->{url} = checkSlash( $value ) if defined $value;
    return $this->{url};    
}

# Prefix of new metric names
sub metricPrefix {
    my ($this, $value) = @_;
    $this->{prefix}    = $value  if defined $value;
    return $this->{prefix};
}

# Should we print out diagnostic degug messages
sub debug {
    my ($this, $value) = @_;
    $this->{debug} = $value if defined $value;
    return $this->{debug};    
}

sub fromStart {
    my ($this, $value) = @_;
    $this->{fromStart} = $value if defined $value;
    return $this->{fromStart} || 0;
}

sub exitAtEnd {
    my ($this, $value) = @_;
    $this->{exitAtEnd} = $value if defined $value;
    return $this->{exitAtEnd} || 0;
}

# Sleep time in seconds between each read batch.
sub sleep {
    my ($this, $value) = @_;
    $this->{sleep} = $value if defined $value;
    return $this->{sleep};    
}


######################################
# Main worker loop
# ------------------------------------
sub run {
    my ($this)      = @_;
    my $metrics     = {};
    my $state       = {};
	my $curFilePos  = 0;
	my $curFileName = $this->lookupFileName;

	$this->initialize($metrics, $state);

	if ($curFileName && -r $curFileName) {
		$curFilePos = -s $curFileName; #move to END
        $curFilePos = 0  if $this->fromStart;
	} else {
		my $showMsg = 1;
		do {
			print STDERR "Waiting for logfile: " . (defined($this->pattern) ? "dir=".$this->dir.", pattern=".$this->pattern : $this->filename ) . "\n"  
			           if ($showMsg || $this->debug);
			$showMsg = 0;
			
			CORE::sleep(10); #wait 10 secs and try again
			$curFileName = $this->lookupFileName;
		} while ( !($curFileName && -r $curFileName) );
	}
	print STDERR "Log File: '".$curFileName."'\n";
	
	while (1) {
		my $candidate = $this->lookupFileName;
		
		if ($candidate ne $curFileName) { #newer file?
			$curFileName = $candidate;
			$curFilePos = 0;
			print STDERR "New Log File: '".$curFileName."'\n";
		}
		
		my $endPos = -s $curFileName || 0;
		if ($endPos < $curFilePos) { #file truncated?
			$curFilePos = 0;
		}
	
		my $rc = open LOG, '<', $curFileName;
		if (!$rc) {
			croak "Cannot open file '" . $curFileName . "': $!\n"  if -e $curFileName;
			next; #try again
		}
		
		seek LOG, $curFilePos, SEEK_SET;
		print STDERR "[mainLoop] curFilePos=$curFilePos\n"  if $this->debug;
		my $logline;
		while (defined($logline = <LOG>)) {         #read one line
			last  if substr($logline, -1) ne "\n";  #break if no NEWLINE found
			$curFilePos = tell LOG;					#save cur pos
			chomp($logline);                        #chop off NEWLINE
			next if $logline =~ /^\s*$/;     		#skip empty lines
			
			print STDERR "[mainLoop] BEGIN '$logline'\n"  if $this->debug;		
			$this->beforeProcess($metrics, $state);
			$this->processLine($logline, $metrics, $state);
			$this->betweenProcessAndEmit($metrics, $state);
			$this->emitMetrics($metrics);
			$this->afterEmit($metrics, $state);
			print STDERR "[mainLoop] DONE '$logline'\n"  if $this->debug;
		}
		close LOG;

        last if $this->exitAtEnd;
		CORE::sleep( $this->sleep );
	}
}


######################################
# Support methods
# ------------------------------------
sub emitMetrics {
    my ($this, $metrics) = @_;

    foreach my $metric (values %$metrics) {
		next  unless $metric->canEmit;
		
        if ($this->url) {
			# my $url = $this->url . $metric->asURI;
            # my $response = get($url);
            # carp "Cannot perform HTTP GET using '$url'" unless defined $response;
        } else {
            print STDOUT $metric->asXML, "\n";
            print STDERR "[emitMetrics] ",$metric->asXML, "\n"  if $this->debug;
        }
		
		$metric->doneEmit;
    } 
}

sub findMetric {
    my ($this, $repo, $name, $type) = @_;

	$repo->{$name} = new Metric($this->metricPrefix . '|' . $name, $type) 
		unless defined $repo->{$name};
	
    return $repo->{$name};
}

sub removeMetric {
	my ($this, $repo, $name) = @_;
	undef $repo->{$name};
}

######################################
# Overloadable methods
# ------------------------------------
sub processLine {
    my ($this, $logline, $metrics, $state) = @_;
	die "Must implement processLine(logline, metrics, state)\n";
}

# --- Hooks ---
sub initialize {
    my ($this, $metrics, $state) = @_;
}
sub beforeProcess {
    my ($this, $metrics, $state) = @_;
}
sub betweenProcessAndEmit {
    my ($this, $metrics, $state) = @_;
}
sub afterEmit {
    my ($this, $metrics, $state) = @_;
}

######################################
# File methods
# ------------------------------------
sub lookupFileName {
	my ($this) = @_;
	return findNewestFile($this->dir, $this->pattern)  if (defined $this->pattern);
	return 0  if !(-r $this->filename);
	return $this->filename;
}

sub findNewestFile {
	my ($dir, $pattern) = @_;
	
	opendir DIR, $dir 
		or croak "Cannot open dir '$dir' :$!\n";
	my @files = 
		sort {stat("$dir/$b")->mtime cmp stat("$dir/$a")->mtime}
		grep { /$pattern/ }
		readdir DIR;
	closedir DIR;
	
	return 0   if (scalar(@files) == 0);
	return $dir . '/' . shift(@files);
}

######################################
# Helpers
# ------------------------------------
sub checkSlash {
    my $url = shift;
    $url = $url . '/' unless $url =~ m|.+/$|;
    return $url;
}
sub isBlank {
    my $txt = shift;
    return !(defined $txt) || ($txt =~ /^\s*$/);
}
sub openable {
	my $file = shift;
	open(FILE, '<', $file) || return 0;
	close FILE;
	return 1;
}

######################################
1;
