#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw/ tempfile tempdir /;
use FindBin;
use lib "$FindBin::Bin/../../main/perl";  # use the parent directory

use RoundTrips;
use_ok('RoundTrips');

my $tmpDir     = tempdir();
my $stdoutFile = "$tmpDir/metrics.log";
print "Metrics File: $stdoutFile\n";

`mkdir -p $tmpDir`;
`rm -f $stdoutFile` if -r $stdoutFile;
`touch $stdoutFile`;

open (my $STDOLD, ">&STDOUT")   or die "cannot dup STDOUT: $!";      #copy STDOUT to another filehandle
open (STDOUT, '>', $stdoutFile) or die "cannot redirect STDOUT: $!"; # redirect STDOUT

my $reader = new RoundTrips();

$reader->parseCommandLineArgs();
$reader->metricPrefix('TST');
$reader->pattern('^access.log$');
$reader->dir("$FindBin::Bin/../data");
$reader->debug(0);
$reader->fromStart(1);
$reader->exitAtEnd(1);

$reader->validate();
$reader->run();

open (STDOUT, '>&', $STDOLD); #restore STDOUT

open (METRICS, $stdoutFile) or die "cannot open $stdoutFile: $!";
my @metrics = <METRICS>;
close (METRICS);

is($#metrics, 1223, 'metrics count');
#print "--- Metrics ---\n@metrics\n";

done_testing();
