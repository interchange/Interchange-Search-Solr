#!perl

use utf8;
use strict;
use warnings;

use Interchange::Search::Solr;
use Test::More;
use Data::Dumper;

my $solr;

# given that we test against a specific database/instance, we have to
# set the fields

my @localfields = (qw/sku
                      title
                      comment
                      description
                     /);

if ($ENV{SOLR_URL}) {
    $solr = Interchange::Search::Solr->new(
                                           solr_url => $ENV{SOLR_URL},
                                           search_fields => \@localfields,
                                          );
}
else {
    plan skip_all => "Please set environment variable SOLR_URL.";
}

ok($solr, "Object created");
ok($solr->solr_object, "Internal Solr instance ok");
$solr->start(3);
$solr->rows(2);
$solr->search();
is ($solr->search_string, '*', "Empty search returns everything");
ok ($solr->num_found, "Found results") and diag "Results: " . $solr->num_found;
# {
#     my @results = @{$solr->results};
#     print Dumper(\@results);
# }
# 
$solr->search("desc hat");
ok ($solr->response->ok);

like $solr->search_string, qr/\(desc\* AND hat\*\)/,
  "Search string interpolated" . $solr->search_string;

is_deeply ($solr->search_terms, [qw/desc hat/], "Search terms saved");

diag "Calling response->docs\n";
ok ($solr->response->ok, "Rersponse is ok");
my @results = @{$solr->results};
# print Dumper(\@results);
is (scalar(@results), 2, "Found 2 results");

$solr->rows(3);
$solr->search("hat");
my @skus = $solr->skus_found;

diag $solr->num_found;
ok ($solr->num_found > 6, "Found more than 10 results");
ok ($solr->has_more, "Has more products");
# print Dumper(\@skus);

is (scalar(@skus), 3, "Found 3 skus");

foreach my $sku (@skus) {
    is (ref($sku), '', "$sku is a scalar");
}

$solr->start($solr->num_found);
$solr->search("hat");
ok (!$solr->has_more, "No more products starting at " .  $solr->start);

$solr->start('pippo');
$solr->rows('ciccia');
$solr->search("hat");
ok $solr->num_found, "Found results with messed up start/rows";
ok $solr->has_more, "And has more";

done_testing;
