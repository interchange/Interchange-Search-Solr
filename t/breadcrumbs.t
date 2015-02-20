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
    plan tests => 2;
}
else {
    plan skip_all => "Please set environment variable SOLR_URL.";
}

my $testurl = 'words/the/shiny/boot/suchbegriffe/xxxxx/yyyy/manufacturer/pikeur/page/2';

$solr->search_from_url($testurl);

is ($solr->current_search_to_url, $testurl);

is_deeply([$solr->breadcrumbs],
          [
           {
            uri => 'words/the',
            label => 'the',
           },
           {
            uri => 'words/the/shiny',
            label => 'shiny',
           },
           {
            uri => 'words/the/shiny/boot',
            label => 'boot',
           },
           {
            uri => 'words/the/shiny/boot/suchbegriffe/xxxxx',
            label => 'xxxxx',
           },
           {
            uri => 'words/the/shiny/boot/suchbegriffe/xxxxx/yyyy',
            label => 'yyyy',
           },
           {
            uri => 'words/the/shiny/boot/suchbegriffe/xxxxx/yyyy/manufacturer/pikeur',
            label => 'pikeur',
           }
          ], "Breadcrumbs ok");
