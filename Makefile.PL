use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    INSTALL_BASE     => $ENV{'HOME'}.'/usr',
    NAME	     => 'Geo::OSM::Overpass::Plugin::FetchRoundabouts',
    AUTHOR	   => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Geo/OSM/Overpass/Plugin/FetchRoundabouts.pm',
    ABSTRACT_FROM    => 'lib/Geo/OSM/Overpass/Plugin/FetchRoundabouts.pm',
    LICENSE	  => 'artistic_2',
    PL_FILES	 => {},
    EXE_FILES	=> ['bin/osm-fetch-roundabouts.pl'],
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
	'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
	'Test::More' => '0',
	'Geo::BoundingBox' => '0.01',
	'Geo::OSM::Overpass' => '0.01',
	'Geo::OSM::Overpass::Plugin' => '0.01',
	#'Geo::OSM::Overpass::Plugin::ParseXML' => '0.01',
    },
    PREREQ_PM => {
	#'ABC'	      => '1.6',
	#'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Geo-OSM-Overpass-Plugin-FetchRoundabouts-*' },
);
