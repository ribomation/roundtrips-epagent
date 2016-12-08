#!/usr/bin/perl
#
#   Unit tests of the extractData function
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

{
    my %noResult = $roundTrips->extractData('this should not match');
    ok(!$noResult{success}, 'no test data: !success');
}

{
    my $testData = q{131.177.117.139 - - [05/Dec/2016:08:17:30 +0100] "GET /loop54/v1/similarvideos?format=smooth_sd&fromIndex=0&oneCoverObjectId=1769852875&parental=true&playId=-1&toIndex=24 HTTP/1.1" 200 4860 "https://pilot.soneraviihde.fi/store/video/7125660" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko" 642304 "chyVYFJT8p7cfvn0nYY8JrvhtG9pG2Sb12D1RJVy1pMzh5h2x5SX!1738450180"};
    my %result = $roundTrips->extractData($testData);
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

{
    my $logline = q{66.102.9.158 - - [04/Dec/2016:20:15:45 +0100] "GET /change/CHANGE_EMAIL/dwdkarlsson@gmail.com/fc9e5f5b144a759a9f71a368197e624ccc3a0826 HTTP/1.1" 200 2491 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36 Google Favicon" 629 "-"};

    my %result = $roundTrips->extractData($logline);
    ok(%result, 'test data: got result');
    ok($result{success}, 'test data: success');

    is($result{ip}, '66.102.9.158', 'test data: ip');
    is($result{code}, '200', 'test data: code');
    is($result{size}, '2491', 'test data: size');
    is($result{time}, '629', 'test data: time');
}


done_testing();
