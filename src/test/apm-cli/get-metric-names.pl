#!/usr/bin/perl
use strict;

my $host = 'aa377iptvwily1p.ddc.teliasonera.net';
my $port = 5021;
my $user = 'admin';
my $pwd  = '';

my $auth    = qq{-Dhost=$host -Dport=$port -Duser=$user -Dpassword=$pwd};
my $jvmCmd  = qq{java -Xmx512M $auth -jar CLWorkstation.jar -i};
my $clwCmd  = qq{get historical data from agents matching (.*EPA.*) and metrics matching (.*RoundTrips.*) for past 1 minute with frequency of 60 seconds\n};
my $tmpFile = "/tmp/metrics_$$.txt";
my $sysCmd  = qq{echo '$clwCmd' | $jvmCmd > $tmpFile};

system $sysCmd;

my @metrics = ();
open CSV, $tmpFile or die "cannot open '$tmpFile': $!\n";
while (<CSV>) {
    chomp;
    next if /^\s*$/;
    next if length($_) < 5;
    next if /^Domain/;

    # Domain,     Host,           Process, AgentName, Resource,                         MetricName,       Record Type, Period, Intended End Timestamp,      Actual Start Timestamp,      Actual End Timestamp,         Value Count, Value Type, Integer Value, Integer Min, Integer Max, Float Value, Float Min, Float Max, String Value, Date Value
    # SuperDomain,aa377iptvweb03p,EPA,     OTT-FI,    RoundTrips|/rest|/images/hotspots,Average Time [ms],Unknown,     60,     Thu Dec 08 14:19:54 GMT 2016,Thu Dec 08 14:18:45 GMT 2016,Thu Dec 08 14:19:45 GMT 2016, 2,           Integer,    8,             7,           9,,,,,
    # 0           1               2        3          4                                 5                 6            7       8                            9                            10                           11            12          13             14           15
    my @fields = split /,/;
    push @metrics, $fields[4];
}
close CSV;
print "got $#metrics lines in $tmpFile\n";

my %tmp   = ();
my @uniq  = grep { ! $tmp{$_}++ } @metrics;
my @names = sort @uniq;

print "--- Metrics ---\n";
my $cnt = 1;
foreach my $m (@names) {
    print "$cnt) $m\n";
    $cnt++;
}
