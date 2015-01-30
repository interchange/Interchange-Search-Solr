#!perl

use strict;
use warnings;
use utf8;
use Interchange::Search::Solr;
use Data::Dumper;
use Test::More;
use Encode;

my $solr_url;
my $solr_enc = 'iso-8859-1';

if ($ENV{SOLR_URL}) {
    $solr_url = $ENV{SOLR_URL};
}
else {
    plan skip_all => "Please set environment variable SOLR_URL.";
}

my $solr = Interchange::Search::Solr->new(solr_url => $solr_url,
                                          input_encoding => $solr_enc);

my $url = encode($solr_enc, 'words/Ärmelbündchen');
$solr->search_from_url($url);

ok(scalar($solr->skus_found), "Found products");

done_testing;


