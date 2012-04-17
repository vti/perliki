package Perliki::Action::Diff;

use strict;
use warnings;

use base 'Turnaround::Action';

use Perliki::DB::Page;
use Perliki::DB::History;
use Text::Diff ();

sub run {
    my $self = shift;

    my $page = Perliki::DB::Page->new(name => $self->captures->{name})->load;
    return $self->not_found unless $page;

    my $revision_a = $self->req->param('a') || $page->get_column('revision');
    my $revision_b = $self->req->param('b') || $page->get_column('revision') - 1;

    my $page_a =
        $revision_a == $page->get_column('revision')
      ? $page
      : $self->_load_history($page->get_column('id'), $revision_a);

    my $page_b =
        $revision_b == $page->get_column('revision')
      ? $page
      : $self->_load_history($page->get_column('id'), $revision_b);

    return $self->not_found unless $page_a && $page_b;

    my $content_a = $page_a->get_column('content');
    my $content_b = $page_b->get_column('content');

    my $diff = Text::Diff::diff(\$content_b, \$content_a, {STYLE => 'Unified'});

    $self->set_var(
        params => {a => $revision_a, b => $revision_b},
        page   => $page->to_hash,
        diff   => $diff
    );

    return;
}

sub _load_history {
    my $self = shift;
    my ($root_id, $revision) = @_;

    return Perliki::DB::History->table->find(
        first => 1,
        where => [root_id => $root_id, revision => $revision]
    );
}

1;
