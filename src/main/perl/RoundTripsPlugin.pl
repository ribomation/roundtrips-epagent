#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';
use FindBin;
use lib ("$FindBin::Bin", "$FindBin::Bin/../lib/site_perl");
use RoundTrips;

my $reader = new RoundTrips();
$reader->parseCommandLineArgs();
$reader->validate();
$reader->run();
