#!perl

use utf8;
use strict;
use warnings;

use Calevo::Search::Solr;
use Test::More tests => 12;
use Data::Dumper;

my $solr = Calevo::Search::Solr->new(solr_url => 'http://localhost:8985/solr/collection1');

ok($solr, "instance ok");
$solr->search('boot');
my $facets = $solr->facets_found;
is (ref($facets), 'HASH', "Facets is an hahsref");
# diag Dumper($facets);
$solr->facets('manufacturer');
$solr->search('shirt');
is ($solr->facets, 'manufacturer', "facets can be changed");
$facets = $solr->facets_found;
is (ref($facets), 'HASH', "and is an hashref again");
# diag Dumper($facets);

# pick the first
my $filter = $facets->{manufacturer}->[0]->{name};
ok($filter, "Filter is $filter");




