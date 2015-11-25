#!perl

use strict;
use warnings;
use Interchange::Search::Solr;
use Test::More;

my @localfields = (qw/sku
                      title
                      comment_en comment_fr
                      comment_nl comment_de
                      comment_se comment_es
                      description_en description_fr
                      description_nl description_de
                      description_se description_es/);

my $solr;
if ($ENV{SOLR_URL}) {
    $solr = Interchange::Search::Solr->new(
                                           solr_url => $ENV{SOLR_URL},
                                           search_fields => \@localfields,
                                          );
}
else {
    my $doc = <<'DOC';
Test can run only if there is a test solr instance running. Tests are
going to clear up the existing node, store some data, and test some searches.

Download the tarball from http://lucene.apache.org/solr/ and unpack it
in /opt/, symlinking it to /opt/solr.

Then symlink /opt/solr/bin/solr to /usr/local/bin/solr.

This is going to give you a solr executable in your $PATH.

So create a dedicated directory under $HOME and do:

 mkdir -p $HOME/solr/{solr,pids,logs}
 cp /opt/solr/server/solr/solr.xml $HOME/solr/solr
 export SOLR_LOGS_DIR=$HOME/solr/logs
 export SOLR_PID_DIR=$HOME/solr/pids
 export SOLR_HOME=$HOME/solr/solr
 export SOLR_PORT=9999
 solr start
 solr status

Then create a core:

 solr create_core -c icsearch -d sample_techproducts_configs -p 9999

Copy the example/schema.xml found in this distribution to
$HOME/solr/solr/icsearch/conf/schema.xml

 cp examples/schema.xml $HOME/solr/solr/icsearch/conf/schema.xml
 solr restart

And export SOLR_URL with the path:

 export SOLR_URL=http://localhost:9999/solr/icsearch

Beware that 9999 is now exposed to the internet, so firewall that.

DOC
    diag $doc;
    plan skip_all => "Please set environment variable SOLR_URL.";
}

