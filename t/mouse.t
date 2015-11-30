#!perl

use strict;
use warnings;

use HTTP::Response;
use Interchange::Search::Solr::Response;
use Test::More;
use Data::Dumper;
use Scalar::Util qw/blessed/;

my $http_res = HTTP::Response->new(404);
ok (blessed($http_res), "empty response is blessed");
diag Dumper($http_res);

my $res = Interchange::Search::Solr::Response->new();

ok ($res);

done_testing;
