#!perl

use strict;
use warnings;
use utf8;
use Interchange::Search::Solr;
use Data::Dumper;
use Test::More tests => 1;
use Encode;

my $solr_url = 'http://localhost:8985/solr/collection1';
my $solr_enc = 'iso-8859-1';

my $solr = Interchange::Search::Solr->new(solr_url => $solr_url,
                                          input_encoding => $solr_enc);

my $url = encode($solr_enc, 'words/Ärmelbündchen');
$solr->search_from_url($url);

ok(scalar($solr->skus_found), "Found products");



