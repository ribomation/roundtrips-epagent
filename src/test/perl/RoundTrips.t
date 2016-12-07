#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use FindBin;                 # locate this script
use lib "$FindBin::Bin/../../main/perl";  # use the parent directory
use RoundTrips;
use_ok('RoundTrips');

my $roundTrips = new RoundTrips();
ok(defined $roundTrips, 'obj defined');
ok($roundTrips->isa('RoundTrips'), 'correct type');

{ ### $roundTrips->extract()
    my %noResult = $roundTrips->extract('this should not match');
    ok(!$noResult{success}, 'no test data: !success');

    my $testData = q{131.177.117.139 - - [05/Dec/2016:08:17:30 +0100] "GET /loop54/v1/similarvideos?format=smooth_sd&fromIndex=0&oneCoverObjectId=1769852875&parental=true&playId=-1&toIndex=24 HTTP/1.1" 200 4860 "https://pilot.soneraviihde.fi/store/video/7125660" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko" 642304 "chyVYFJT8p7cfvn0nYY8JrvhtG9pG2Sb12D1RJVy1pMzh5h2x5SX!1738450180"};
    my %result = $roundTrips->extract($testData);
    ok(%result, 'test data: got result');
    ok($result{success}, 'test data: success');
    is($result{ip}, '131.177.117.139', 'test data: ip');
    is($result{date}, '05/Dec/2016:08:17:30 +0100', 'test data: date');
    is($result{op}, 'GET', 'test data: op');
    is($result{code}, '200', 'test data: code');
    is($result{size}, '4860', 'test data: time');
    is($result{time}, '642304', 'test data: time');
    is(substr($result{uri}, 0, 7), '/loop54', 'test data: uri prefix');
}

{ ### $roundTrips->extract()
    my $logline = q{66.102.9.158 - - [04/Dec/2016:20:15:45 +0100] "GET /change/CHANGE_EMAIL/dwdkarlsson@gmail.com/fc9e5f5b144a759a9f71a368197e624ccc3a0826 HTTP/1.1" 200 2491 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36 Google Favicon" 629 "-"};

    my %result = $roundTrips->extract($logline);
    ok(%result, 'test data: got result');
    ok($result{success}, 'test data: success');

    is($result{ip}, '66.102.9.158', 'test data: ip');
    is($result{code}, '200', 'test data: code');
    is($result{size}, '2491', 'test data: size');
    is($result{time}, '629', 'test data: time');
}

{ ### $roundTrips->shouldSkip()
    my %data;
    $data{success} = 1;

    $data{uri} = '/';
    is($roundTrips->shouldSkip(\%data), 1, 'skipping / (ROOT)');

    $data{uri} = '/assets/whatever...';
    is($roundTrips->shouldSkip(\%data), 1, 'skipping /assets/...');

    $data{uri} = '/static/whatever...';
    is($roundTrips->shouldSkip(\%data), 1, 'skipping /static/...');

    $data{uri} = '/templates.whatever...';
    is($roundTrips->shouldSkip(\%data), 1, 'skipping /templates...');

    $data{uri} = '/tve.2.9.0-RC7.151.css';
    is($roundTrips->shouldSkip(\%data), 1, 'skipping ...*.css');

    $data{uri} = '/logic.2.9.0-RC7.151.js';
    is($roundTrips->shouldSkip(\%data), 1, 'skipping ...*.js');
}

{ ### $roundTrips->shouldSkip()
    # additional URIs
    my %data;
    $data{success} = 1;

    $data{uri} = '/...';
    is($roundTrips->shouldSkip(\%data), 1, 'skipping /... (ROOT + DOTs)');

    $data{uri} = '/.well-known/assetlinks';
    is($roundTrips->shouldSkip(\%data), 1, 'skipping .well-known');

}

{ ### $roundTrips->stripQueryPart($uri)
    my $uri = '/rest/whatever';
    is($roundTrips->stripQueryPart($uri), '/rest/whatever', 'stripping absent query');

    $uri = '/rest/whatever?a=1&bb=22';
    is($roundTrips->stripQueryPart($uri), '/rest/whatever', 'stripping query string');

    $uri = '/rest/livechannels/136,138,139,142,144,150,154,155,156,157,159,160,161,162,163,164,166,168,171,172,174,176,178,179,183,184,185,186,187,1879,188,1880,1882,1883,1884,1885,197,2119446120,601,602,604,605,606,610,613,614,615,616,617,618,619,620,621,622,623,626,627,629,632,633,636,637,638,639,640,643,644,645,646,647,648,678,679,697,698,699,702,706,707,708,719,720,721,729,730,731,732,733,734,735,736,737,738,779486864,779490117,839798335/epg?deviceType=WEB&fromTime=1480975200000&hoursForward=24';
    my $uri2 = '/rest/livechannels/136,138,139,142,144,150,154,155,156,157,159,160,161,162,163,164,166,168,171,172,174,176,178,179,183,184,185,186,187,1879,188,1880,1882,1883,1884,1885,197,2119446120,601,602,604,605,606,610,613,614,615,616,617,618,619,620,621,622,623,626,627,629,632,633,636,637,638,639,640,643,644,645,646,647,648,678,679,697,698,699,702,706,707,708,719,720,721,729,730,731,732,733,734,735,736,737,738,779486864,779490117,839798335/epg';
    is($roundTrips->stripQueryPart($uri), $uri2, 'stripping long query string');
}

{ ### $roundTrips->separateContext(\%data)
    my %data;
    $data{uri} = '/rest/livechannels/136,138';

    $roundTrips->separateContext(\%data);
    is($data{ctx}, '/rest'                , 'separate ctx: ctx');
    is($data{uri}, '/livechannels/136,138', 'separate ctx: uri');

    $data{ctx} = undef;
    $data{uri} = '/one/';
    $roundTrips->separateContext(\%data);
    is($data{ctx}, '/one'    , 'separate ctx /one/: /one');
    is($data{uri}, '/'       , 'separate ctx /one/: /');

    $data{ctx} = undef;
    $data{uri} = '/one.css';
    $roundTrips->separateContext(\%data);
    is($data{ctx}, '/one.css'    , 'separate ctx /one.css: /one.css');
    is($data{uri}, ''            , 'separate ctx /one.css: EMPTY');
}

{ ### $roundTrips->normalizeUri(URI)
    my $uri = '/loop54/v1/categories/32475/titles';
    is($roundTrips->normalizeUri($uri), '/loop54/v1/categories/_/titles', 'normalize: one ID');

    $uri = '/rest/vodstores/2926387866/videocategories/32475';
    is($roundTrips->normalizeUri($uri), '/rest/vodstores/_/videocategories/_', 'normalize: two ID');

    $uri = '/rest/livechannels/136,138,139,142,144,150,154,155,156,157,159,160,161,162,163,164,166,168,171,172,174,176,178,179,183,184,185,186,187,1879,188,1880,1882,1883,1884,1885,197,2119446120,601,602,604,605,606,610,613,614,615,616,617,618,619,620,621,622,623,626,627,629,632,633,636,637,638,639,640,643,644,645,646,647,648,678,679,697,698,699,702,706,707,708,719,720,721,729,730,731,732,733,734,735,736,737,738,779486864,779490117,839798335/epg';
    is($roundTrips->normalizeUri($uri), '/rest/livechannels/_/epg', 'normalize: many IDs');
}

{ ### $roundTrips->normalizeUri(URI)
    # handle URIs with non-numeric IDs, such as email and userid

    my $uri = '/change/FORGOTTEN_PWD/hemis@telia.com/d1f18739f0ccd376a94a8f9a209be1e619146ed3';
    is($roundTrips->normalizeUri($uri), '/change/FORGOTTEN_PWD/_', 'normalize: email and link-id');

    $uri = '/change/FORGOTTEN_PWD/larssontvtime/76ed63d47b97cd832cea67746e5be6fc3fc1a831';
    is($roundTrips->normalizeUri($uri), '/change/FORGOTTEN_PWD/_', 'normalize: email');

    $uri = '/change/CHANGE_EMAIL/jorijori/da21313b4949ef2a76a18d5a755b54fb01ab6146';
    is($roundTrips->normalizeUri($uri), '/change/CHANGE_EMAIL/_', 'normalize: email');

    $uri = '/change/CHANGE_EMAIL/dwdkarlsson@gmail.com/fc9e5f5b144a759a9f71a368197e624ccc3a0826';
    is($roundTrips->normalizeUri($uri), '/change/CHANGE_EMAIL/_', 'normalize: email');
}


{ ### $roundTrips->collectMetrics(...)
    my $metrics = {};
    $roundTrips->metricPrefix('RT');
    $roundTrips->collectMetrics($metrics, '/ctx', '/uri/abc', 1234, 204);
    ##print Dumper($metrics);

    my $name = 'ALL:Requests per Interval';
    ok(defined $metrics->{$name}, 'ALL:reqs defined');
    is($metrics->{$name}->name, 'RT|'.$name, 'ALL:reqs name');
    is($metrics->{$name}->type, 'PerIntervalCounter', 'ALL:reqs type');
    is($metrics->{$name}->value, 1, 'ALL:reqs value');

    is($metrics->{'/ctx|/uri/abc:Average Time [ms]'}->value, 1234, 'avg time');
    is($metrics->{'/ctx|/uri/abc|StatusCode:204'}->value, 1, 'avg time');

    print STDOUT "--- [collectMetrics] Metrics ---\n";
    foreach my $m (values %$metrics) {
        next unless $m->canEmit;
        print STDOUT "XML: ", $m->asXML, "\n";
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

    print STDOUT "--- [collectHistogram] Histogram ---\n";
    foreach my $m (values %$metrics) {
        next unless $m->canEmit;
        print STDOUT "XML: ", $m->asXML, "\n";
    }
}

{ ### $roundTrips->processLine($logline, $metrics)
    $roundTrips->metricPrefix('RT');
    $roundTrips->thresholds('100,500,1000');

    my $metrics = {};
    my $logline = '131.177.117.139 - - [05/Dec/2016:08:16:04 +0100] "GET /rest/secure/mediarentals?listAllActive=true&deviceType=WEB HTTP/1.1" 200 19 "https://pilot.soneraviihde.fi/store" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko" 9034811 "chyVYFJT8p7cfvn0nYY8JrvhtG9pG2Sb12D1RJVy1pMzh5h2x5SX!1738450180"';
    $roundTrips->processLine($logline, $metrics);

    is($metrics->{'/rest|/secure/mediarentals:Average Time [ms]'}->value, 9035, 'process line: avg time (1)');

    print STDOUT "--- [processLine] Metrics ---\n";
    foreach my $m (values %$metrics) {
        next unless $m->canEmit;
        print STDOUT "XML: ", $m->asXML, "\n";
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
