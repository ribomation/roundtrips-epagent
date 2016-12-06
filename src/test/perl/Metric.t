#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;                 # locate this script
use lib "$FindBin::Bin/../../main/perl";  # use the parent directory
use Metric;
use_ok('Metric');

my $metric = new Metric('tst:value', 'IntAverage');
ok(defined $metric,             'obj defined');
ok($metric->isa('Metric'),      'correct type');

is($metric->value(), 0, 'before collect');

$metric->collect(42);
is($metric->value(), 42, 'after collect');
is($metric->asSimple(), 'tst:value=42', 'simple format');
is($metric->asXML(), qq(<metric type="IntAverage" name="tst:value" value="42"/>), 'XML format');

$metric->clear();
is($metric->value(), 0, 'after clear');

$metric->collectDelta(2);
$metric->collectDelta(3);
is($metric->value(), 5, 'after two delta');

$metric->clear();
is($metric->value(), 0, 'after clear');

$metric->increment();
$metric->increment();
$metric->increment();
$metric->decrement();
is($metric->value(), 2, 'after 3 inc and 1 dec');

done_testing();
