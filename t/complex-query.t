#!perl

use strict;
use warnings;

use Interchange::Search::Solr;
use Data::Dumper;
use Test::More;
use WebService::Solr::Query;

my $solr;

my @localfields = (qw/sku name short_description description active/);
my @facets = (qw/collection manufacturer/);

if ($ENV{SOLR_TEST_URL}) {
    $solr = Interchange::Search::Solr->new(solr_url => $ENV{SOLR_TEST_URL},
                                           search_fields => \@localfields,
                                          );
}
else {
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}

my $res = $solr->search({ active => 1 });

ok($res->ok, $solr->search_string);
ok $solr->num_found, "found " . $solr->num_found;
$res = $solr->search({ active => 0 });
ok($res->ok, $solr->search_string);
ok $solr->num_found, "found inactive products " . $solr->num_found;
scan_field($solr->results, active => 0);

$res = $solr->search({ comment => 'knitted hat', active => 1 });
ok($res->ok, $solr->search_string);
ok $solr->num_found, "found " . $solr->num_found;
scan_field($solr->results, active => 1);

$res = $solr->search({ comment => 'knitted hat', active => 0 });
ok($res->ok, $solr->search_string);
ok $solr->num_found, "found " . $solr->num_found;
scan_field($solr->results, active => 0);


# wildcard

$solr = Interchange::Search::Solr->new(solr_url => $ENV{SOLR_TEST_URL},
                                       search_fields => \@localfields,
                                       global_conditions => { active => 1 },
                                      );

$solr->permit_empty_search(1);
$res = $solr->search('');
ok($res->ok, $solr->search_string);
ok $solr->num_found, "found " . $solr->num_found;
scan_field($solr->results, active => 1);

$solr = Interchange::Search::Solr->new(solr_url => $ENV{SOLR_TEST_URL},
                                       search_fields => \@localfields,
                                       global_conditions => { active => 0 },
                                      );
$res = $solr->search('hat und');
ok($res->ok, $solr->search_string);
ok $solr->num_found, "found " . $solr->num_found;
scan_field($solr->results, active => 0);

$solr = Interchange::Search::Solr->new(solr_url => $ENV{SOLR_TEST_URL},
                                       search_fields => \@localfields,
                                       global_conditions => { active => 1 },
                                      );
$res = $solr->search('hat und');
ok($res->ok, $solr->search_string);
ok $solr->num_found, "found " . $solr->num_found;
scan_field($solr->results, active => 1);




done_testing;



sub get_query {
    my $thing = shift;
    my $query = WebService::Solr::Query->new($thing);
    return $query->stringify . "\n";
}


sub scan_field {
    my ($results, $field, $value) = @_;
    ok(@$results, "Results found");
    my @not_matching = grep { $_->{$field} ne $value } @$results;
    ok(!@not_matching, "All $field are <$value>");
    
}
