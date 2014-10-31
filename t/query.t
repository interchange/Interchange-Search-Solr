#!perl

use strict;
use warnings;

use Interchange::Search::Solr;
use Data::Dumper;
use Test::More tests => 12;

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
my @skus = $solr->skus_found;
ok (scalar(@skus), "Found some results with /shirt/manufacturer/pikeur");
ok ($solr->has_more, "And has more");
ok ($solr->num_found, "Total: " . $solr->num_found);
