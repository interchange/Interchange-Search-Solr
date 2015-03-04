#!perl

use strict;
use warnings;

use Interchange::Search::Solr;
use Data::Dumper;
use Test::More;

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

$solr->search_from_url('/the/boot/i/like/suchbegriffe/xxxxx/yyyy/manufacturer/Pikeur/page/2');

is_deeply($solr->search_terms, [qw/the boot i like/], "Search terms picked up ok");
is($solr->start, 10, "Start computed correctly"), # we have to start at 0
is($solr->page, 2, "Page picked up");
is_deeply($solr->filters, {
                           suchbegriffe => [qw/xxxxx yyyy/],
                           manufacturer => [qw/Pikeur/],
                          });

is (scalar($solr->skus_found), 0, "No sku found with this query");

# reverse the order of facets
$solr->facets([qw/manufacturer suchbegriffe/]);

is $solr->current_search_to_url,
  'words/the/boot/i/like/manufacturer/Pikeur/suchbegriffe/xxxxx/yyyy/page/2',
  "Url resolves correctly";


$solr->search_from_url('/boot');
my @skus = $solr->skus_found;
ok (scalar(@skus), "Found some results with /boot");

$solr->search('boot');
is_deeply([ $solr->skus_found] , \@skus, "same result");

is ($solr->url_builder([qw/pinco pallino/],
                       {
                        manufacturer => [qw/Pikeur/]
                       }, 3),
    'words/pinco/pallino/manufacturer/Pikeur/page/3',
    "Url builder works");

$solr->search_from_url('/shirt/manufacturer/Pikeur');
@skus = $solr->skus_found;
ok (scalar(@skus), "Found some results with /shirt/manufacturer/Pikeur")
  or die "Search is broken";
ok ($solr->has_more, "And has more");
ok ($solr->num_found, "Total: " . $solr->num_found);

$solr->search_from_url('/shirt');

my @links = map { $_->[0]->{query_url} }  values %{ $solr->facets_found };

like $links[0], qr{words/shirt/.+/.+}, "Found the filter link $links[0]"
  or diag Dumper($solr->response);


$solr->search_from_url('/');

@links = map { $_->[0]->{query_url} }  values %{ $solr->facets_found };

like $links[0], qr{.+/.+}, "Found the filter link $links[0]";

$solr->search_from_url('/manufacturer/Pikeur');

# this test is fragile because it depends on the db

my %paginator = %{$solr->paginator};

my $lastpage = delete $paginator{last};

like $lastpage, qr{manufacturer/Pikeur/page/\d+}, "Found last page";



is_deeply(\%paginator,
          {
           next => 'manufacturer/Pikeur/page/2',
           'items' => [
                       {
                        'current' => 1,
                        name => 1,
                        'url' => 'manufacturer/Pikeur'
                       },
                       {
                        'url' => 'manufacturer/Pikeur/page/2',
                        name => 2,
                       },
                       {
                        'url' => 'manufacturer/Pikeur/page/3',
                        name => 3,
                       },
                       {
                        'url' => 'manufacturer/Pikeur/page/4',
                        name => 4,
                       },
                       {
                        'url' => 'manufacturer/Pikeur/page/5',
                        name => 5,
                       },
                       {
                        'url' => 'manufacturer/Pikeur/page/6',
                        name => 6,
                       }
                      ]
          });


is($solr->facets_found->{manufacturer}->[0]->{query_url}, '',
   "After querying a manufacturer, removing the bit would reset the search");
is($solr->facets_found->{manufacturer}->[0]->{active}, 1,
   "The filter is active") or diag Dumper($solr->facets_found);

like ($solr->facets_found->{suchbegriffe}->[0]->{query_url},
      qr/suchbegriffe/, "Found the suchbegriffe keyword in the url")
  or diag $solr->facets_found->{suchbegriffe}->[0]->{query_url};

$solr->rows(1000);
$solr->search_from_url('/shirt/manufacturer/Pikeur');
@skus = $solr->skus_found;
is (scalar(@skus), $solr->num_found, "Skus reported and returned match");
# print Dumper($solr);

$solr->search_from_url('/words/shirt/fashion/manufacturer/Pikeur');

ok (scalar($solr->skus_found), "Found some results");

is_deeply($solr->terms_found, {
                               reset => 'manufacturer/Pikeur',
                               terms => [
                                         {
                                          term => 'shirt',
                                          url => 'words/fashion/manufacturer/Pikeur',
                                         },
                                         {
                                          term => 'fashion',
                                          url => 'words/shirt/manufacturer/Pikeur',
                                         },
                                        ],
                              }, "struct ok");


$solr->search_from_url('/words/shirt/fashion');

ok (scalar($solr->skus_found), "Found some results");

is_deeply($solr->terms_found, {
                               reset => '',
                               terms => [
                                         {
                                          term => 'shirt',
                                          url => 'words/fashion',
                                         },
                                         {
                                          term => 'fashion',
                                          url => 'words/shirt',
                                         },
                                        ],
                              }, "struct ok");


is ($solr->add_terms_to_url('words/pippo', qw/pluto paperino  ciccia/),
    "words/pippo/pluto/paperino/ciccia");

done_testing;

