#!perl

use utf8;
use strict;
use warnings;

use Calevo::Search::Solr;
use Test::More tests => 7;
use Data::Dumper;

my $solr = Calevo::Search::Solr->new(solr_url => 'http://localhost:8985/solr/collection1');
ok($solr, "Object created");
ok($solr->solr_object, "Internal Solr instance ok");
$solr->start(3);
$solr->rows(6);
$solr->search("shirt");

diag $solr->_search_query;

my @results = $solr->full_search;
# print Dumper(\@results);
is (scalar(@results), 6, "Found 6 results");

$solr->rows(3);
my @skus = $solr->skus_found;

# print Dumper(\@skus);

is (scalar(@skus), 3, "Found 3 skus");

foreach my $sku (@skus) {
    is (ref($sku), '', "$sku is a scalar");
}


