#!perl

use utf8;
use strict;
use warnings;

use Calevo::Search::Solr;
use Test::More tests => 12;
use Data::Dumper;

my $solr = Calevo::Search::Solr->new(solr_url => 'http://localhost:8985/solr/collection1');

ok($solr);

my $params = {
              facet => 'true',
              'facet.field' => [qw/suchbegriffe manufacturer/],
              'facet.mincount'=> 1,
              q => '*',
             };

my $res = $solr->solr_object->generic_solr_request(select => $params);

print Dumper($res->facets_found);




