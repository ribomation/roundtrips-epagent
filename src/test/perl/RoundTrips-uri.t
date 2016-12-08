#!/usr/bin/perl
#
#   Unit tests of URI related functions
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

# Hej Jens, såg att det var några fler fall där vi behöver “normalisera” URI för restanrop, “tokens” och “servicetickets” under /rest.
# Skickar några exempel strax ur apache-loggen
# vi såg några fler skumma URI:er, HBO, tv4 med flera. har du loggrader för dessa också. så tar jag dem i samma svep
# Det är fler än dessa. Egentligen allt som inte börjar på följande:
#    /com /rest /restlogin /iptv /jaxlet /continuewatching
# Lite lurigt när bilderna laddas på detta sättet numera. Innan gick de alla via Igloos ImageCache:

## should be normalized
# 90.230.19.208 - - [07/Dec/2016:16:12:00 +0100] "GET /rest/secure/token/mm77ri6r5oh8idhhptlmonlbjg01f5fi8pjto1ummtodtu1jgfu?deviceType=WEB HTTP/1.1" 200 360 "https://playplus.telia.se/live" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko" 12212 "YlDhYLXNpFtYQGKHxDv2pwnq2T2Sj8TCxBJPfnhgv7D7TqQy9xbT!-1287588519"
# 83.209.120.93 - - [07/Dec/2016:16:12:21 +0100] "GET /rest/secure/token/ae5s54bp4k56o97hdn7kam6h5k069nt58ehfcdih32pnrfo5i2r?deviceType=WEB HTTP/1.1" 200 358 "https://playplus.telia.se/live" "Mozilla/5.0 (Windows NT 6.3; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0" 14462 "p1hnYFMNyMHvNPhcy5G4Mvr2GSghtskDjfM4b8yDm95pX0YL4TMF!-43935605"
# 80.76.155.25 - - [07/Dec/2016:16:14:30 +0100] "GET /rest/v1/encrypted/servicetickets/b9bff25d6199196a4bc92a35ada05f7c/channelsticket HTTP/1.1" 200 675 "-" "-" 20934 "2bKpYLnWFTs24Rpw3y0vzTKk8052SpM6rSX3PdlWQzQRyZpR79T1!-43935605"
# 80.76.155.25 - - [07/Dec/2016:16:14:32 +0100] "GET /engagement/rest/v1/encrypted/servicetickets/353b6d70a820806d29174d526ad164d5/activestream HTTP/1.1" 200 20 "-" "-" 48536 "-"

## should be skipped
# 81.236.57.11 - - [07/Dec/2016:16:23:24 +0100] "GET /HBO/1004515.jpg HTTP/1.0" 200 199120 "-" "-" 5895 "-" - - - - - - -
# 81.236.57.21 - - [07/Dec/2016:16:21:21 +0100] "GET /tv4plus/2458341.jpg HTTP/1.0" 200 106417 "-" "-" 3747 "-" - - - - - - -
# 81.236.57.11 - - [07/Dec/2016:16:21:22 +0100] "GET /tv4faktaxl/2460160.jpg HTTP/1.0" 200 228896 "-" "-" 8408 "-" - - - - - - -
# 81.236.57.21 - - [07/Dec/2016:16:23:29 +0100] "GET //tv4/2460230.jpg HTTP/1.0" 200 288103 "-" "-" 6473 "-" - - - - - - -
# 81.236.57.11 - - [07/Dec/2016:16:23:15 +0100] "GET /SF%20Anytime/2482160.jpg HTTP/1.0" 200 166039 "-" "-" 5492 "-" - - - - - - -
# 81.236.57.11 - - [07/Dec/2016:16:23:29 +0100] "GET /SFBarnensFavoriter/1762463.jpg HTTP/1.0" 200 908092 "-" "-" 16290 "-" - - - - - - -
# 81.236.57.21 - - [07/Dec/2016:15:52:10 +0100] "GET /boomerang/1812487.jpg HTTP/1.0" 200 231313 "-" "-" 36906 "-" - - - - - - -
# 81.236.57.11 - - [07/Dec/2016:10:25:07 +0100] "GET /cirkushd/2248907.jpg HTTP/1.0" 200 645933 "-" "-" 18823 "-" - - - - - - -
# 81.236.57.21 - - [07/Dec/2016:10:36:47 +0100] "GET /cirkus/905936.jpg HTTP/1.0" 200 591173 "-" "-" 15846 "-" - - - - - - -
# 81.236.57.21 - - [07/Dec/2016:16:23:15 +0100] "GET /timbuktu/185742.jpg HTTP/1.0" 200 35931 "-" "-" 4691 "-" - - - - - - -
# 81.236.57.21 - - [07/Dec/2016:15:32:40 +0100] "GET /tv12/2460299.jpg HTTP/1.0" 200 67520 "-" "-" 119 "-" - - - - - - -
# 81.236.57.11 - - [07/Dec/2016:16:14:07 +0100] "GET /viasat2/1214097.jpg HTTP/1.0" 200 383 "-" "-" 114 "-" - - - - - - -
# 81.236.57.21 - - [07/Dec/2016:15:42:08 +0100] "GET /tv7/2467459.jpg HTTP/1.0" 200 278095 "-" "-" 6404 "-" - - - - - - -
# 10.157.18.113 - - [07/Dec/2016:16:31:37 +0100] "GET /Imagecache.html?url=/images/SVoD_images/SVTr/supershowen_708x1024.jpg&width=178&height=265 HTTP/1.1" 200 27776 "http://iptvlogin.telia.se/iptvgui/guiV6_19_9_4529_swe/index.html" "KreaTVWebKit/534 (Motorola STB; Linux)" 125 "WhdLYFgh27vX2w7bnw1FjpLvwTmpqnrCyyQhrqpT8SxQXqvkn5qR!1857407369!1480941754278" - - - - - - -


{
    ### $roundTrips->shouldSkipURI($uri)
    my @URIs = (
        '/HBO/1004515.jpg',
        '/tv4plus/2458341.jpg',
        '/tv4faktaxl/2460160.jpg',
        '//tv4/2460230.jpg',
        '/SF%20Anytime/2482160.jpg',
        '/SFBarnensFavoriter/1762463.jpg',
        '/boomerang/1812487.jpg',
        '/cirkushd/2248907.jpg',
        '/cirkus/905936.jpg',
        '/timbuktu/185742.jpg',
        '/tv12/2460299.jpg',
        '/viasat2/1214097.jpg',
        '/tv7/2467459.jpg',
        '/Imagecache.html',
        '/',
        '/...',
        '/assets/whatever...',
        '/static/whatever...',
        '/templates.whatever...',
        '/tve.2.9.0-RC7.151.css',
        '/logic.2.9.0-RC7.151.js',
        '/.well-known/assetlinks',
    );

    foreach my $uri (@URIs) {
        is($roundTrips->shouldSkipURI($uri), 1, "should skip URI '$uri'");
    }
}

{
    ### $roundTrips->stripQueryFromURI($uri)
    my $data = [
        [ '/rest/whatever', '/rest/whatever' ],
        [ '/rest/whatever?a=1&bb=22', '/rest/whatever' ],
        [
            '/rest/livechannels/136,138,139,142,144,150,154,155,156,157,159,160,161,162,163,164,166,168,171,172,174,176,178,179,183,184,185,186,187,1879,188,1880,1882,1883,1884,1885,197,2119446120,601,602,604,605,606,610,613,614,615,616,617,618,619,620,621,622,623,626,627,629,632,633,636,637,638,639,640,643,644,645,646,647,648,678,679,697,698,699,702,706,707,708,719,720,721,729,730,731,732,733,734,735,736,737,738,779486864,779490117,839798335/epg?deviceType=WEB&fromTime=1480975200000&hoursForward=24'
            ,
            '/rest/livechannels/136,138,139,142,144,150,154,155,156,157,159,160,161,162,163,164,166,168,171,172,174,176,178,179,183,184,185,186,187,1879,188,1880,1882,1883,1884,1885,197,2119446120,601,602,604,605,606,610,613,614,615,616,617,618,619,620,621,622,623,626,627,629,632,633,636,637,638,639,640,643,644,645,646,647,648,678,679,697,698,699,702,706,707,708,719,720,721,729,730,731,732,733,734,735,736,737,738,779486864,779490117,839798335/epg'
        ],
    ];

    foreach my $pair (@$data) {
        my ($uri, $strippedUri) = @$pair;
        is($roundTrips->stripQueryFromURI($uri), $strippedUri, "should be stripped to '$strippedUri'");
    }
}

{
    ### $roundTrips->splitURI($uri)
    my $data = [
        [ '/rest/livechannels/136,138', [ '/rest', '/livechannels/136,138' ] ],
        [ '/one/', [ '/one', '/' ] ],
        [ '/one.css', [ '/one.css', '' ] ],
    ];

    foreach my $pair (@$data) {
        my ($uri, $combo) = @$pair;
        my ($ctx, $rst) = $roundTrips->splitURI($uri);
        is($ctx, $combo->[0], "should split '$uri' into ctx='$combo->[0]'");
        is($rst, $combo->[1], "should split '$uri' into rst='$combo->[1]'");
    }
}

{### $roundTrips->normalizeURI($uri)
    my $data = [
        [
            '/loop54/v1/categories/32475/titles',
            '/loop54/v1/categories/_/titles'
        ],
        [
            '/rest/vodstores/2926387866/videocategories/32475',
            '/rest/vodstores/_/videocategories/_'
        ],
        [
            '/rest/livechannels/136,138,139,142,144,150,154,155,156,157,159,160,161,162,163,164,166,168,171,172,174,176,178,179,183,184,185,186,187,1879,188,1880,1882,1883,1884,1885,197,2119446120,601,602,604,605,606,610,613,614,615,616,617,618,619,620,621,622,623,626,627,629,632,633,636,637,638,639,640,643,644,645,646,647,648,678,679,697,698,699,702,706,707,708,719,720,721,729,730,731,732,733,734,735,736,737,738,779486864,779490117,839798335/epg',
            '/rest/livechannels/_/epg'
        ],
        [
            '/change/FORGOTTEN_PWD/hemis@telia.com/d1f18739f0ccd376a94a8f9a209be1e619146ed3',
            '/change/FORGOTTEN_PWD/_'
        ],
        [
            '/change/FORGOTTEN_PWD/larssontvtime/76ed63d47b97cd832cea67746e5be6fc3fc1a831',
            '/change/FORGOTTEN_PWD/_'
        ],
        [
            '/change/CHANGE_EMAIL/jorijori/da21313b4949ef2a76a18d5a755b54fb01ab6146',
            '/change/CHANGE_EMAIL/_'
        ],
        [
            '/change/CHANGE_EMAIL/dwdkarlsson@gmail.com/fc9e5f5b144a759a9f71a368197e624ccc3a0826',
            '/change/CHANGE_EMAIL/_'
        ],
        [
            '/rest/secure/token/mm77ri6r5oh8idhhptlmonlbjg01f5fi8pjto1ummtodtu1jgfu',
            '/rest/secure/token/_'
        ],
        [
            '/rest/secure/token/ae5s54bp4k56o97hdn7kam6h5k069nt58ehfcdih32pnrfo5i2r',
            '/rest/secure/token/_'
        ],
        [
            '/rest/v1/encrypted/servicetickets/b9bff25d6199196a4bc92a35ada05f7c/channelsticket',
            '/rest/v1/encrypted/servicetickets/_/channelsticket'
        ],
        [
            '/engagement/rest/v1/encrypted/servicetickets/353b6d70a820806d29174d526ad164d5/activestream',
            '/engagement/rest/v1/encrypted/servicetickets/_/activestream'
        ],
    ];

    foreach my $pair (@$data) {
        my ($uri, $normalizedUri) = @$pair;
        is($roundTrips->normalizeURI($uri), $normalizedUri, "should normalize '$uri' to '$normalizedUri'");
    }
}



done_testing();
