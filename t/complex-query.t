#!perl

use strict;
use warnings;

use Interchange::Search::Solr;
use Data::Dumper;
use Test::More;
use WebService::Solr::Query;

my $solr;

my @localfields = (qw/sku
                      title
                      comment_en comment_fr
                      comment_nl comment_de
                      comment_se comment_es
                      description_en description_fr
                      description_nl description_de
                      description_se description_es/);

if ($ENV{SOLR_URL}) {
    $solr = Interchange::Search::Solr->new(solr_url => $ENV{SOLR_URL},
                                           search_fields => \@localfields,
                                          );
}
else {
    plan skip_all => "Please set environment variable SOLR_URL.";
}

diag get_query({
                 inactive => 0,
                 foo => 'bar',
                });

diag get_query([
                 { inactive => 0, },
                 { foo => 'bar', },
                ]);

my $res = $solr->search({ inactive => 0 });

ok($res->ok, $solr->search_string);
ok $solr->num_found, "found " . $solr->num_found;
$res = $solr->search({ inactive => 1 });
ok($res->ok, $solr->search_string);
ok $solr->num_found, "found inactive products " . $solr->num_found;

$res = $solr->search({ comment_en => 'knitted hat', inactive => 0 });
ok($res->ok, $solr->search_string);
ok $solr->num_found, "found " . $solr->num_found;

$res = $solr->search({ comment_en => 'knitted hat', inactive => 1 });
ok($res->ok, $solr->search_string);
ok $solr->num_found, "found " . $solr->num_found;

$res = $solr->search('knitted hat');
ok($res->ok, $solr->search_string);
ok $solr->num_found, "found " . $solr->num_found;
my $hats = $solr->num_found;


done_testing;



sub get_query {
    my $thing = shift;
    my $query = WebService::Solr::Query->new($thing);
    return $query->stringify . "\n";
}


