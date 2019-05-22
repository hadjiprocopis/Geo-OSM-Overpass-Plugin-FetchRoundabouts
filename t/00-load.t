#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Geo::OSM::Overpass::Plugin::FetchRoundabouts' ) || print "Bail out!\n";
}

diag( "Testing Geo::OSM::Overpass::Plugin::FetchRoundabouts $Geo::OSM::Overpass::Plugin::FetchRoundabouts::VERSION, Perl $], $^X" );
