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
                      created_date
                      updated_date
                     /);

if ($ENV{SOLR_TEST_URL}) {
    $solr = Interchange::Search::Solr->new(
                                           solr_url => $ENV{SOLR_TEST_URL},
                                           search_fields => \@localfields,
                                          );
}
else {
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}

ok($solr, "Object created");

$solr->permit_empty_search(1);
$solr->sorting('updated_date');
$solr->search();
my $latest = $solr->results->[0];
my %params = $solr->construct_params;
is $params{sort}, 'updated_date desc', 'sorting desc param ok';
$solr->permit_empty_search(1);
$solr->sorting_direction('asc');
$solr->search();
%params = $solr->construct_params;
is $params{sort}, 'updated_date asc', 'sorting asc param ok';
my $older = $solr->results->[0];
diag Dumper($latest, $older);
# these are known values from data.yaml and 00-populate.pl
is $latest->{sku}, '1211202', "Sorting desc ok";
is $older->{sku}, '1111200', "Sorting asc ok";
done_testing;
