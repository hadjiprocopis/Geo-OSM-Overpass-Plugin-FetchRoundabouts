package Geo::OSM::Overpass::Plugin::FetchRoundabouts;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use Data::Dumper;

use Geo::OSM::Overpass::Plugin::ParseXML;
use parent 'Geo::OSM::Overpass::Plugin';

# returns undef on failure
sub gorun {
	my $self = $_[0];
	my $params = $_[1];

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $eng = $self->engine();
	my $bbox = $eng->bbox();
	if( ! defined $bbox ){ print STDERR "$whoami (via $parent) : a bounding box was not specified via the engine.\n"; return undef }
	my $bbox_query = $bbox->stringify_as_OSM_bbox_query_xml();
	my $previous_print_mode = $eng->query_print_mode();
	$eng->query_print_mode('center');
	my $qu = $eng->_overpass_XML_preamble();
#   <has-kv k='highway' v='roundabout'/>
#   <has-kv k='junction' v='circular'/>
	$qu .= <<EOQ;
 <union>
  <query type='way'>
   <has-kv k='junction' v='roundabout'/>
   ${bbox_query}
  </query>
 </union>
EOQ
	$qu .= $eng->_overpass_XML_postamble();

	$eng->query_print_mode($previous_print_mode); # restore previous print mode... (are you sure?)
	# make the query
	if( ! $eng->query($qu) ){ print STDERR "$whoami (via $parent) : call to query() has failed.\n"; return undef }

	my $res = $eng->last_query_result();
	# the result has 1 or more way with all the nodes enclosing the roundabout
	# and also a center

	if( exists($params->{'convert-to-nodes'}) && $params->{'convert-to-nodes'} == 1 ){
		# here we are replacing the "<way>" with one of its node, retaining the node id
		# but substituting the node's location with way's centre.
		# the tags of the way are transfered to the node. everything else is removed.
		#$$res =~ s|\s*<nd\s+ref=.+?/>\n*|\n|sg;
		$$res =~ s|\s*<node\s+.*?id=".+?/>\n*|\n|sg;
		my @nodes=();
		my ($wayid, $nodeid, $centr, $rest, $lat, $lon);
		while( $$res =~ s|<\s*way.+?id=["'](.+?)["'].*?>.*?<center\s+(.+?)\s*>(.*?)<\s*/\s*way\s*>|<XYZFUC>|s ){
			$wayid = $1;
			$centr = $2;
			$rest = $3;
			if( $centr =~ /lat=["'](.+?)["']/ ){ $lat = $1 } else { print STDERR "$whoami (via $parent) : error parsing XML (way id=$wayid), centre does not have 'lat='\n"; return undef }
			if( $centr =~ /lon=["'](.+?)["']/ ){ $lon = $1 } else { print STDERR "$whoami (via $parent) : error parsing XML (way id=$wayid), centre does not have 'lon='\n"; return undef }
			if( $rest =~ m|<nd.+?ref=["'](.+?)["'].*?/>|s ){
				$nodeid = $1
			} else {
				print STDERR "$whoami (via $parent) : warning, parsing XML (way id=$wayid) has failed because did not find any '<nd ref=...', way-id will be used as a node id, this will produce a node with fake id.\n";
				$nodeid = $wayid;
			}
			$rest =~ s|\s*<nd\s+ref=.+?/>\n*|\n|sg;
			push @nodes, [$wayid, $nodeid, [$lat,$lon], $rest];
		}
		foreach my $anode (@nodes){
			$wayid = $anode->[0];
			$nodeid = $anode->[1];
			($lat, $lon) = @{$anode->[2]};
			$rest = $anode->[3];
			$$res =~ s|<XYZFUC>|<node id="${nodeid}" lat="${lat}" lon="${lon}">\n${rest}</node>|;
		}
		$$res =~ s|\n+|\n|sg;
		# sanity test
		if( $$res =~ /<XYZFUC>/ ){ print STDERR "$whoami (via $parent) : error, excess marker tags after processing, this should not be happening.\n"; return undef }
		# alternative is to parse XML, filter and output to string but ...
		#my $xmlplug = Geo::OSM::Overpass::Plugin::ParseXML->new({
		#	'engine' => $eng
		#});
		#if( ! defined $xmlplug ){ print STDERR "$whoami (via $parent) : call to ".'Geo::OSM::Overpass::Plugin::ParseXML->new()'." has failed.\n"; return undef }
		#my $xml = $xmlplug->gorun();
		#if( ! defined $xml ){ print STDERR "$whoami (via $parent) : call to ".'Geo::OSM::Overpass::Plugin::ParseXML::gorun()'." has failed.\n"; return undef }
	}
	return 1 # success
}

# end of program, pod starts here
=encoding utf8
=head1 NAME

Geo::OSM::Overpass::Plugin::FetchRoundabouts - Plugin for L<Geo::OSM::Overpass> to fetch bus stop data in given area

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

This is a plugin for L<Geo::OSM::Overpass>, which is a module to fetch
data from the OpenStreetMap Project using Overpass API. It fetches
data about bus stops within a geographical area defined by a bounding
box. In order to use this plugin, first create a L<Geo::BoundingBox>
object for the bounding box enclosing the area. Secondly, create
a L<Geo::OSM::Overpass> object to do the communication with the
Overpass API server. Thirdly, create the plugin object and run
its C<gorun()> method.

    use Geo::BoundingBox;
    use Geo::OSM::Overpass;
    use Geo::OSM::Overpass::Plugin::FetchRoundabouts;

    my $bbox = Geo::BoundingBox->new();
    # a bounding box (bottom-left corner, top-right corner) in LAT,LON convention
    $bbox->bounded_by(35.177119, 33.333039, 35.178417, 33.334980);
    my $eng = Geo::OSM::Overpass->new();
    die unless defined $eng;
    $eng->verbosity(2);
    $eng->bbox($bbox) or die;
    my $plug = Geo::OSM::Overpass::Plugin::FetchRoundabouts->new({
        'engine' => $eng
    });
    die unless defined $plug;
    $plug->gorun() or die;
    # print results, but it's a reference!
    print "Results: ".${$eng->last_query_result()}."\n";
    # prints:
    # <?xml version="1.0"?>
    # <osm version="0.6" generator="Overpass API 0.7.55.7 8b86ff77">
    # <note>The data included in this document is from www.openstreetmap.org. The data is made available under ODbL.</note>
    # <meta osm_base="2019-05-15T21:50:02Z"/>
    # 
    #   <way id="28512252">
    #     <center lat="35.1777960" lon="33.3340230"/>
    #     <nd ref="313200571"/>
    #     ...
    #   </way>
    #   <node id="313200571" lat="35.1776945" lon="33.3340493"/>
    #   <node id="313200572" lat="35.1776958" lon="33.3339902"/>
    #   ..,
    # 
    # </osm>

    # Now let's keep only the center of the way and make a node with that location
    $plug->gorun({
	'convert-to-nodes' => 1
    }) or die;
    print "Results: ".${$eng->last_query_result()}."\n";
    # WARNING: the node printed below is real and lies on the periphery of the roundabout
    # However, its actual location is slightly different
    # to the one printed. We moved it a bit to reflect the centre of the way

    # <?xml version="1.0"?>
    # <osm version="0.6" generator="Overpass API 0.7.55.7 8b86ff77">
    # <note>The data included in this document is from www.openstreetmap.org. The data is made available under ODbL.</note>
    # <meta osm_base="2019-05-15T22:07:02Z"/>
    #   <node id="313200571" lat="35.1777960" lon="33.3340230">
    #     <tag k="highway" v="primary"/>
    #     <tag k="junction" v="roundabout"/>
    #     <tag k="lanes" v="2"/>
    #     <tag k="oneway" v="yes"/>
    #     <tag k="surface" v="asphalt"/>
    #   </node>
    # </osm>

=head1 SUBROUTINES/METHODS

=head2 C<< new({'engine' => $eng}) >>

Constructor. A hashref of parameters contains the
only required parameter which is an already created
L<Geo::OSM::Overpass> object. If in your plugin have
no use for this, then call it like C<new({'engine'=>undef})>


=head2 C<< gorun(...) >>

It will execute the query using the specified L<Geo::OSM::Overpass>
object (aka the engine) specified in the constructor.

It takes an optional hashref of parameters:

=over 4

=item * C<convert-to-nodes> : if set to 1 then the result of the query is modified in order
to eliminate all the nodes from the periphery of the roundabout (and the way) and
replace them with just one node with a real id but its coordinates slightly different
in order to coincide with the centre of the roundabout.

=back

It will return 1 on success or C<undef> on failure.

The result of the query can be accessed using ```print "Results: ".${eng->last_query_result()}."\n";```


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 CAVEATS

This is alpha release, the API is not yet settled and may change.

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-osm-overpass-plugin-FetchRoundabouts at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-OSM-Overpass-Plugin-FetchRoundabouts>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::OSM::Overpass::Plugin::FetchRoundabouts


You can also look for information at:

=over 4

=item * L<Geo::BoundingBox> a geographical bounding box class.

=item * L<Geo::OSM::Overpass> aka the engine.

=item * L<Geo::OSM::Plugin> the parent class of all the plugins for
L<Geo::OSM::Overpass>

=item * L<https://www.openstreetmap.org> main entry point for the OpenStreetMap Project.

=item * L<https://wiki.openstreetmap.org/wiki/Overpass_API/Language_Guide> Overpass API
query language guide.

=item * L<https://overpass-turbo.eu> Overpass Turbo query language online
sandbox. It can also convert to XML query language.

=item * L<http://overpass-api.de/query_form.html> yet another online sandbox and
converter.

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-OSM-Overpass-Plugin-FetchRoundabouts>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-OSM-Overpass-Plugin-FetchRoundabouts>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Geo-OSM-Overpass-Plugin-FetchRoundabouts>

=item * Search CPAN

L<https://metacpan.org/release/Geo-OSM-Overpass-Plugin-FetchRoundabouts>

=back


=head1 DEDICATIONS

Almaz

=head1 ACKNOWLEDGEMENTS

The OpenStreetMap project and all the good people who
thought it, implemented it, collected the data and
publicly host it.

```
 @misc{OpenStreetMap,
   author = {{OpenStreetMap contributors}},
   title = {{Planet dump retrieved from https://planet.osm.org }},
   howpublished = "\url{ https://www.openstreetmap.org }",
   year = {2017},
 }
```

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
1; # End of Geo::OSM::Overpass::Plugin::FetchRoundabouts
