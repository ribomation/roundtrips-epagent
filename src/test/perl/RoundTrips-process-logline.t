#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../main/perl";
use RoundTrips;
use_ok('RoundTrips');

my $roundTrips = new RoundTrips();
ok(defined $roundTrips, 'obj defined');
ok($roundTrips->isa('RoundTrips'), 'correct type');

{ ### $roundTrips->processLine($logline, $metrics)
    $roundTrips->metricPrefix('RT');
    $roundTrips->thresholds('100,500,1000');

    my $metrics = {};
    my $logline = '131.177.117.139 - - [05/Dec/2016:08:16:04 +0100] "GET /rest/secure/mediarentals?listAllActive=true&deviceType=WEB HTTP/1.1" 200 19 "https://pilot.soneraviihde.fi/store" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko" 9034811 "chyVYFJT8p7cfvn0nYY8JrvhtG9pG2Sb12D1RJVy1pMzh5h2x5SX!1738450180"';
    $roundTrips->processLine($logline, $metrics);

    is($metrics->{'/rest|/secure/mediarentals:Average Time [ms]'}->value, 9035, 'process line: avg time (1)');

    ##print STDOUT "--- [processLine] Metrics ---\n";
    foreach my $m (values %$metrics) {
        next unless $m->canEmit;
        ##print STDOUT "XML: ", $m->asXML, "\n";
    }
}

{
    $roundTrips->metricPrefix('RT');
    $roundTrips->thresholds('100,500,1000');

    my $metrics = {};
    my $logline = '131.177.117.139 - - [05/Dec/2016:08:15:58 +0100] "GET /rest/livechannels?deviceType=WEB HTTP/1.1" 200 64581 "https://pilot.soneraviihde.fi/live" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko" 7992 "-"';
    $roundTrips->processLine($logline, $metrics);
    is($metrics->{'/rest|/livechannels:Average Time [ms]'}->value, 8, 'process line: avg time (2)');

    $metrics = {};
    $logline = '131.177.117.139 - - [05/Dec/2016:08:35:00 +0100] "GET /npvr/rest/v1/recordings/123456/programs?deviceType=WEB&ids=12132978,12132979,12133543,12133544 HTTP/1.1" 200 11742 "https://pilot.soneraviihde.fi/store/video/7176369?player=fullscreen" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko" 6831 "chyVYFJT8p7cfvn0nYY8JrvhtG9pG2Sb12D1RJVy1pMzh5h2x5SX!1738450180"';
    $roundTrips->processLine($logline, $metrics);
    is($metrics->{'/npvr|/rest/v1/recordings/_/programs:Average Time [ms]'}->value, 7, 'process line: avg time (3)');
}

done_testing();
