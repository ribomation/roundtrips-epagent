#!/usr/bin/perl
#
#   Unit tests of collecting metrics
#
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../main/perl";
use RoundTrips;
use_ok('RoundTrips');

my $roundTrips = new RoundTrips();
ok(defined $roundTrips, 'obj defined');

{ ### $roundTrips->collectMetrics(...)
    my $metrics = {};
    $roundTrips->metricPrefix('RT');
    $roundTrips->collectMetrics($metrics, '/ctx', '/uri/abc', 1234, 204);

    my $name = 'ALL:Requests per Interval';
    ok(defined $metrics->{$name}, 'ALL:reqs defined');
    is($metrics->{$name}->name, 'RT|'.$name, 'ALL:reqs name');
    is($metrics->{$name}->type, 'PerIntervalCounter', 'ALL:reqs type');
    is($metrics->{$name}->value, 1, 'ALL:reqs value');

    is($metrics->{'/ctx|/uri/abc:Average Time [ms]'}->value, 1234, 'avg time');
    is($metrics->{'/ctx|/uri/abc|StatusCode:204'}->value, 1, 'avg time');

    ##print STDOUT "--- [collectMetrics] Metrics ---\n";
    foreach my $m (values %$metrics) {
        next unless $m->canEmit;
        ##print STDOUT "XML: ", $m->asXML, "\n";
    }
}

{ ### $roundTrips->collectHistogram(...)
    my $metrics = {};
    $roundTrips->metricPrefix('RT');
    $roundTrips->thresholds('100,500,1000');
    $roundTrips->collectHistogram($metrics, '/ctx', '/uri/abc', 42);
    $roundTrips->collectHistogram($metrics, '/ctx', '/uri/abc', 323);
    $roundTrips->collectHistogram($metrics, '/ctx', '/uri/abc', 723);
    $roundTrips->collectHistogram($metrics, '/ctx', '/uri/abc', 1123);

    is($metrics->{'/ctx|/uri/abc|Time Distribution:H0) 0 - 100 [ms]'}->value, 1, 'histo value');
    is($metrics->{'/ctx|/uri/abc|Time Distribution:H2) 500 - 1000 [ms]'}->value, 1, 'histo value');
    is($metrics->{'ALL|Time Distribution:H3) 1000 - oo [ms]'}->value, 1, 'histo value');

    ##print STDOUT "--- [collectHistogram] Histogram ---\n";
    foreach my $m (values %$metrics) {
        next unless $m->canEmit;
        ##print STDOUT "XML: ", $m->asXML, "\n";
    }
}

done_testing();
