#!perl

use strict;
use warnings;

use Interchange::Search::Solr;
use Data::Dumper;
use Test::More tests => 15;

my $solr = Interchange::Search::Solr->new(solr_url => 'http://localhost:8985/solr/collection1');

$solr->search_from_url('/the/boot/i/like/suchbegriffe/xxxxx/yyyy/manufacturer/pikeur/page/2');

is_deeply($solr->search_terms, [qw/the boot i like/], "Search terms picked up ok");
is($solr->start, 11, "Start computed correctly"), #
is($solr->page, 2, "Page picked up");
is_deeply($solr->filters, {
                           suchbegriffe => [qw/xxxxx yyyy/],
                           manufacturer => [qw/pikeur/],
                          });

is (scalar($solr->skus_found), 0, "No sku found with this query");

# reverse the order of facets
$solr->facets([qw/manufacturer suchbegriffe/]);

is $solr->current_search_to_url,
  'words/the/boot/i/like/manufacturer/pikeur/suchbegriffe/xxxxx/yyyy/page/2',
  "Url resolves correctly";


$solr->search_from_url('/boot');
my @skus = $solr->skus_found;
ok (scalar(@skus), "Found some results with /boot");

$solr->search('boot');
is_deeply([ $solr->skus_found] , \@skus, "same result");

is ($solr->url_builder([qw/pinco pallino/],
                       {
                        manufacturer => [qw/pikeur/]
                       }, 3),
    'words/pinco/pallino/manufacturer/pikeur/page/3',
    "Url builder works");

$solr->search_from_url('/shirt/manufacturer/pikeur');
@skus = $solr->skus_found;
ok (scalar(@skus), "Found some results with /shirt/manufacturer/pikeur");
ok ($solr->has_more, "And has more");
ok ($solr->num_found, "Total: " . $solr->num_found);

$solr->search_from_url('/shirt');

my @links = map { $_->[0]->{query_url} }  values %{ $solr->facets_found };

like $links[0], qr{words/shirt/.+/.+}, "Found the filter link $links[0]";


$solr->search_from_url('/');

@links = map { $_->[0]->{query_url} }  values %{ $solr->facets_found };

like $links[0], qr{.+/.+}, "Found the filter link $links[0]";

$solr->search_from_url('/manufacturer/pikeur');

is($solr->facets_found->{manufacturer}->[0]->{query_url}, '',
   "After querying a manufacturer, removing the bit would reset the search");

