package Interchange::Search::Solr;

use 5.010001;
use strict;
use warnings;

use Moo;
use WebService::Solr;
use WebService::Solr::Query;

=head1 NAME

Interchange::Search::Solr -- Solr query encapsulation

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Interchange::Search::Solr;
    my $solr = Interchange::Search::Solr->new(solr_url => $url);
    $solr->rows(10);
    $solr->start(0);
    $solr->search('shirts');
    my @skus = $solr->skus_found;

=head1 ACCESSORS

=head2 solr_url

Url of the solr instance. Read-only.

=head2 rows

Number of results to return. Read-write (so you can reuse the object).

=head2 search_fields

An arrayref with the indexed fields to search. Defaults to:

  [qw/sku
      title
      comment_en comment_fr
      comment_nl comment_de
      comment_se comment_es
      description_en description_fr
      description_nl description_de
      description_se description_es/] 


=head2 facets

A string or an arrayref with the fields which will generate a facet.
Defaults to

 [qw/suchbegriffe manufacturer/]

=head2 start

Start of pagination. Read-write.

=head2 page

Current page. Read-write.

=head2 filters

An hashref with the filters. E.g.

 {
  suchbegriffe => [qw/xxxxx yyyy/],
  manufacturer => [qw/pikeur/],
 }

The keys of the hashref, to have any effect, must be one of the facets.

=head2 response

Read-only accessor to the response object of the current search.

=head2 facets_found

After a search, the structure with the facets can be retrieved with
this accessor, with this structure:

 {
   field => [ { name => "name", count => 11 }, { name => "name", count => 9 }, ...  ],
   field2 => [ { name => "name", count => 7 }, { name => "name", count => 6 }, ...  ],
   ...
 }

=head2 search_string

Debug only. The search string produced by the query.

=head2 search_terms

The terms used for the current search.

=cut

has solr_url => (is => 'ro',
                 required => 1);

has search_fields => (is => 'ro',
                      default => sub { return [qw/sku
                                                  title
                                                  comment_en comment_fr
                                                  comment_nl comment_de
                                                  comment_se comment_es
                                                  description_en description_fr
                                                  description_nl description_de
                                                  description_se description_es/] },
                      isa => sub { die unless ref($_[0]) eq 'ARRAY' });

has facets => (is => 'rw',
               default => sub {
                   return [qw/suchbegriffe manufacturer/];
               });

has rows => (is => 'rw',
             default => sub { 10 });

has start => (is => 'rw',
              default => sub { 0 });

has page => (is => 'rw',
             default => sub { 1 });

has filters => (is => 'rw');

has response => (is => 'rwp');

has search_string => (is => 'rwp');

has search_terms  => (is => 'rwp');

=head1 INTERNAL ACCESSORS

=head2 solr_object

The L<WebService::Solr> instance.

=cut

has solr_object => (is => 'lazy');

sub _build_solr_object {
    my $self = shift;
    return WebService::Solr->new($self->solr_url);
}

=head1 METHODS

=head2 search($string)

Run a search and return a L<WebService::Solr::Response> object. After
calling this method you can inspect the response using the following
methods:

=head2 skus_found

Returns just a plain list of skus.

=head2 num_found

Return the number of items found

=head2 has_more

Return true if there are more pages

=cut

sub search {
    my ($self, $string) = @_;
    # here we just split the terms, set C<search_terms>, and call
    # _do_search.
    my @terms;
    if ($string) {
        @terms = grep { $_ } split(/\s+/, $string);
    }
    $self->_set_search_terms(\@terms);
    return $self->_do_search;
}

sub _do_search {
    my $self = shift;

    my @terms = @{ $self->search_terms };
    my $query;
    if (@terms) {
        my @queries;
        foreach my $field (@{ $self->search_fields }) {
            push @queries, { $field => [ -and =>  @terms ] };
        }
        $query = WebService::Solr::Query->new(\@queries);
    }
    else {
        # catch all
        $query = WebService::Solr::Query->new( { '*' => \'*' } );
    }
    # save the debug info
    $self->_set_search_string($query->stringify);

    # set start and rows
    my %params = (
                  start => $self->_start_row,
                  rows => $self->_rows
                 );


    if (my $facet_field = $self->facets) {
        $params{facet} = 'true';
        $params{'facet.field'} = $facet_field;
        $params{'facet.mincount'} = 1;

        # see if we have filters set
        if (my $filters = $self->filters) {
            my @fq;
            foreach my $facet (@{ $self->facets }) {
                if (my $condition = $filters->{$facet}) {
                    push @fq,
                      WebService::Solr::Query->new({ $facet => $condition });
                }
            }
            if (@fq) {
                $params{fq} = \@fq;
            }
        }
    }

    my $res = $self->solr_object->search($query, \%params);
    $self->_set_response($res);
    return $res;
}

sub _start_row {
    my $self = shift;
    return $self->_convert_to_int($self->start) || 0;
}

sub _rows {
    my $self = shift;
    return $self->_convert_to_int($self->rows) || 10;
}

sub _convert_to_int {
    my ($self, $maybe_num) = @_;
    return 0 unless $maybe_num;
    if ($maybe_num =~ m/([1-9][0-9]*)/) {
        return $1;
    }
    else {
        return 0;
    }
}

sub num_found {
    my $self = shift;
    return $self->response->content->{response}->{numFound} || 0;
}

sub skus_found {
    my $self = shift;
    my @skus;
    foreach my $item ($self->response->docs) {
        push @skus, $item->value_for('sku');
    }
    return @skus;
}

sub facets_found {
    my $self = shift;
    my $res = $self->response;
    my $facets = $res->content->{facet_counts}->{facet_fields};
    my %out;
    foreach my $field (keys %$facets) {
        my @list = @{$facets->{$field}};
        my @items;
        while (@list > 1) {
            my $name = shift @list;
            my $count = shift @list;
            push @items, { name => $name, count => $count };
        }
        $out{$field} = \@items;
    }
    return \%out;
}


sub has_more {
    my $self = shift;
    if ($self->num_found > ($self->_start_row + $self->_rows)) {
        return 1;
    }
    else {
        return 0;
    }
}


=head2 maintainer_update($mode)

Perform a maintainer update and return a L<WebService::Solr::Response>
object.

=cut

sub maintainer_update {
    my ($self, $mode) = @_;
    die "Missing argument" unless $mode;
    my @query;
    if ($mode eq 'clear') {
        my %params = (
                      'stream.body' => '<delete><query>*:*</query></delete>',
                      commit        => 'true',
                     );
        @query = ('update', \%params);
    }
    elsif ($mode eq 'full') {
        @query = ('dataimport', { command => 'full-import' });
    }
    elsif ($mode eq 'delta') {
        @query = ('dataimport', { command => 'delta-import' });
    }
    else {
        die "Unrecognized mode $mode!";
    }
    return $self->solr_object->generic_solr_request(@query);
}


=head2 reset_object

Reset the leftovers of a possible previous search.

=head2 search_from_url($url)

Parse the url provided and do the search.

=cut

sub reset_object {
    my $self = shift;
    $self->start(0);
    $self->page(1);
    $self->_set_response(undef);
    $self->_set_search_string(undef);
    $self->filters(undef);
}

sub search_from_url {
    my ($self, $url) = @_;
    $self->reset_object;
    $self->_parse_url($url);
    $self->_set_start_from_page;
    # at this point, all the parameters are set after the url parsing
    return $self->_do_search;
}

sub _parse_url {
    my ($self, $url) = @_;
    my @fragments = grep { $_ } split('/', $url);

    # nothing to do if there are no fragments
    return unless @fragments;

    # the first keyword we need is the optional "words"
    if ($fragments[0] eq 'words') {
        # just discards and check if we have something
        shift @fragments;
        return unless @fragments;
    }

    # the page is the last fragment, so check that
    if (@fragments > 1) {
        my $page = $#fragments;
        if ($fragments[$page - 1] eq 'page') {
            $page = pop @fragments;
            # and remove the page
            pop @fragments;
            # but assert it is a number, 1 otherwise
            if ($page =~ s/^([1-9][0-9]*)$/)/) {
                $self->page($1);
            }
            else {
                $self->page(1);
            }
        }
    }
    return unless @fragments;
    # then we lookup until the first keyword
    my @keywords = @{ $self->facets };
    my ($current_filter, @terms, %filters);
    while (@fragments) {

        my $chunk = shift (@fragments);

        if (grep { $_ eq $chunk } @keywords) {
            # chunk is actually a keyword. Set the flag, prepare the
            # array and move on.
            $current_filter = $chunk;
            $filters{$current_filter} = [];
            next;
        }

        # are we inside a filter?
        if ($current_filter) {
            push @{ $filters{$current_filter} }, $chunk;
        }
        # if not, it's a term
        else {
            push @terms, $chunk;
        }
    }
    $self->_set_search_terms(\@terms);
    $self->filters(\%filters);
    return unless @fragments;
}

sub _set_start_from_page {
    my $self = shift;
    # unclear if the trailing +1 is needed
    $self->start($self->rows * ($self->page - 1)  + 1);
}


=head2 current_search_to_url

Return the url for the current search.

=cut

sub current_search_to_url {
    my ($self) = @_;
    my @fragments;
    if (my @terms = @{$self->search_terms}) {
        push @fragments, 'words', @terms;
    }
    if (my $filters = $self->filters) {
        foreach my $facet (@{ $self->facets }) {
            if (my $terms = $filters->{$facet}) {
                push @fragments, $facet, @$terms;
            }
        }
    }
    if ($self->page > 1) {
        push @fragments, page => $self->page;
    }
    return join ('/', @fragments);
}


=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-calevo-search-solr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Interchange-Search-Solr>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Interchange::Search::Solr


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Interchange-Search-Solr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Interchange-Search-Solr>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Interchange-Search-Solr>

=item * Search CPAN

L<http://search.cpan.org/dist/Interchange-Search-Solr/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Marco Pessotto.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Interchange::Search::Solr
