#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Calevo::Search::Solr' ) || print "Bail out!\n";
}

diag( "Testing Calevo::Search::Solr $Calevo::Search::Solr::VERSION, Perl $], $^X" );
