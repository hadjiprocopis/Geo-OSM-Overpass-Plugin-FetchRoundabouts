#!/usr/bin/env perl

use strict;
use warnings;

use lib 'blib/lib';

use Test::More;

use Geo::OSM::Overpass;
use Geo::OSM::Overpass::Plugin::FetchRoundabouts;
use Geo::BoundingBox;

my $num_tests = 0;

my $bbox = Geo::BoundingBox->new();
ok(defined $bbox && 'Geo::BoundingBox' eq ref $bbox, 'Geo::BoundingBox->new()'.": called") or BAIL_OUT('Geo::BoundingBox->new()'.": failed, can not continue."); $num_tests++;
# this is LAT,LON convention
ok(1 == $bbox->bounded_by(
	[35.121112, 33.333467,  35.122235, 33.336375]
), 'bbox->bounded_by()'." : called"); $num_tests++;

my $eng = Geo::OSM::Overpass->new();
ok(defined $eng && 'Geo::OSM::Overpass' eq ref $eng, 'Geo::OSM::Overpass->new()'.": called") or BAIL_OUT('Geo::OSM::Overpass->new()'.": failed, can not continue."); $num_tests++;
$eng->verbosity(2);
ok(defined $eng->bbox($bbox), "bbox() called"); $num_tests++;

my $plug = Geo::OSM::Overpass::Plugin::FetchRoundabouts->new({
	'engine' => $eng
});
ok(defined($plug) && 'Geo::OSM::Overpass::Plugin::FetchRoundabouts' eq ref $plug, 'Geo::OSM::Overpass::Plugin::FetchRoundabouts->new()'." : called"); $num_tests++;

ok(defined $plug->gorun(), "checking gorun()"); $num_tests++;

my $result = $eng->last_query_result();
ok(defined($result) && 1 == $$result =~ m|<way.+?id="28943061".*?>|s, "checking result contains one way."); $num_tests++;

# just the centres
ok(defined $plug->gorun({
	'convert-to-nodes' => 1
}), "checking gorun()"); $num_tests++;

$result = $eng->last_query_result();
ok(defined $result, "checking if got result"); $num_tests++;
# saturn operator, see https://perlmonks.org/?node_id=11100099
ok(defined($result) && 1 == ( ()= $$result =~ m|<node.+?id=".+?".*?>|gs), "checking result contains one <node>"); $num_tests++;
ok(defined($result) && $$result !~ m|<way.+?id="28943061".*?>|s, "checking result contains no <way>."); $num_tests++;
ok(defined($result) && $$result !~ m|<nd ref=".+?">|s, "checking result contains no <nd ref=..."); $num_tests++;

# END
done_testing($num_tests);
