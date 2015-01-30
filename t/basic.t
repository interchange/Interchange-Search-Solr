#!perl

use utf8;
use strict;
use warnings;

use Interchange::Search::Solr;
use Test::More;
use Data::Dumper;

my $solr;

if ($ENV{SOLR_URL}) {
    $solr = Interchange::Search::Solr->new(solr_url => $ENV{SOLR_URL});
}
else {
    plan skip_all => "Please set environment variable SOLR_URL.";
}

ok($solr, "Object created");
ok($solr->solr_object, "Internal Solr instance ok");
$solr->start(3);
$solr->rows(6);
$solr->search();
is ($solr->search_string, '(*:*)', "Empty search returns everything");
ok ($solr->num_found, "Found results") and diag "Results: " . $solr->num_found;
$solr->search("the boot");

like $solr->search_string, qr/\(\(sku:"the"\) AND \(sku:"boot"\)\)/,
  "Search string interpolated" . $solr->search_string;

is_deeply ($solr->search_terms, [qw/the boot/], "Search terms saved");


my @results = $solr->response->docs;
# print Dumper(\@results);
is (scalar(@results), 6, "Found 6 results");

$solr->rows(3);
$solr->search("boot");
my @skus = $solr->skus_found;

diag $solr->num_found;
ok ($solr->num_found > 10, "Found more than 10 results");
ok ($solr->has_more, "Has more products");
# print Dumper(\@skus);

is (scalar(@skus), 3, "Found 3 skus");

foreach my $sku (@skus) {
    is (ref($sku), '', "$sku is a scalar");
}

$solr->start($solr->num_found);
$solr->search("boot");
ok (!$solr->has_more, "No more products starting at " .  $solr->start);

$solr->start('pippo');
$solr->rows('ciccia');
$solr->search("boot");
ok $solr->num_found, "Found results with messed up start/rows";
ok $solr->has_more, "And has more";

done_testing;
