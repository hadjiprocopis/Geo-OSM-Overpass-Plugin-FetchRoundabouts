#!/usr/bin/env perl

use strict;
use warnings;

use utf8;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use Getopt::Long;
use File::Spec;
use Data::Dumper;
use Geo::OSM::Overpass;
use Geo::OSM::Overpass::Plugin::FetchRoundabouts;

my $bbox = undef;
my $outfile = undef;

my $VERBOSITY = 0;

my $engine = Geo::OSM::Overpass->new();
if( ! defined $engine ){ print STDERR "$0 : call to ".'Geo::OSM::Overpass->new()'." has failed.\n"; exit(1) }

my %plugin_params = ();
if( ! Getopt::Long::GetOptions(
	'outfile=s' => sub {
		$engine->output_filename($_[1]);
		$outfile = $_[1];
	},
	'bbox-centred-at=s' => sub {
		$bbox = Geo::BoundingBox->new();
		if( ! $bbox->centred_at($_[1]) ){ print STDERR "$0 : input centred-at spec could not be parsed: '".$_[1]."'. Expected (lat:lon,width[,height)\n"; exit(1) }
		if( ! $engine->bbox($bbox) || ! $bbox->was_set() ){ print STDERR "$0 : failed to set the bounding box of the engine to $bbox\n"; exit(1) }
	},
	'bbox-bounded-by=s' => sub {
		$bbox = Geo::BoundingBox->new();
		if( ! $bbox->bounded_by($_[1]) ){ print STDERR "$0 : input centred-at spec could not be parsed: '".$_[1]."'. Expected (lat:lon,lat:lon) for left-bottom and right-top corners of the bounding box.\n"; exit(1) }
		if( ! $engine->bbox($bbox) || ! $bbox->was_set() ){ print STDERR "$0 : failed to set the bounding box of the engine to $bbox\n"; exit(1) }
	},
	'convert-to-nodes!' => sub { $plugin_params{'convert-to-nodes'} = $_[1] },
	'timeout=i' => sub { $engine->query_timeout($_[1]) },
	'maxsize=i' => sub { $engine->max_memory_size($_[1]) },
	'output-type=s' => sub { $engine->query_output_type($_[1]) },
	'verbosity=i' => sub {
		$engine->verbosity($_[1]);
		$VERBOSITY = $_[1];
	},
) ){ print STDERR usage($0) . "\n$0 : something wrong with command line parameters.\n"; exit(1); }

if( ! defined $bbox ){ print STDERR usage($0) . "\n$0 : a bounding box must be specified either using --bbox-centred-at or --bbox-OSM.\n"; exit(1) }
#if( ! defined $outfile ){ print STDERR usage($0) . "\n$0 : an output file must be specified using --outfile.\n"; exit(1); }

$engine->verbosity($VERBOSITY);

my $plug = Geo::OSM::Overpass::Plugin::FetchRoundabouts->new({
	'engine' => $engine
});
if( ! defined $plug ){ print STDERR "$0 : call to ".'Geo::OSM::Overpass::Plugin::FetchRoundabouts->new()'." has failed.\n"; exit(1) }

if( ! defined $plug->gorun(\%plugin_params) ){ print STDERR "$0 : call to ".'gorun()'." has failed.\n"; exit(1) }

if( defined $outfile ){
	$engine->output_filename($outfile);
	if( ! $engine->save() ){ print STDERR "$0 : failed to save output to file '$outfile'.\n"; exit(1) }
	print "$0 : success, output written to '$outfile'.\n";
} else {
	print "$0 : success, output dumped below:\n";
	print ${$engine->last_query_result()}."\n";
}
exit(0);

sub	usage {
	print "Usage : $0 <options>\noptions:\n"
	. " --bbox-centred-at LAT:LON,W[xH] : specify bounding box as a square or rectangle of side W[xH] centred at LAT:LON (notice LAT:LON).\n"
	. " OR\n"
	. " --box-bounded-by minLAT:minLON,maxLAT:maxLON : specify bounding box by specifying its bottom-left and top-right corners as (LAT,LON), for example lat:lon,lat:lon.\n"
	. "[--outfile OUTFILE.xml : where output goes.]\n"
	. "[--verbosity N : be verbose if N > 0.]\n"
	. "[--timeout T : seconds before the query times out, default is ".$engine->query_timeout()." seconds.]\n"
	. "[--output-type T : output type, default is ".$engine->query_output_type().".]\n"
	. "[--max-num-items M : maximum number of items to get, default is ".(defined($engine->query_output_type())?$engine->query_output_type():'unlimited').".]\n"
	. "\nProgram by Andreas Hadjiprocopis (c) 2019\n\n"
}
