package Perliki::Action::History;

use strict;
use warnings;

use base 'Turnaround::Action';

use Perliki::DB::Page;
use Perliki::DB::History;

sub run {
    my $self = shift;

    my $name = $self->captures->{name};

    my $page = Perliki::DB::Page->new(name => $name)->load;
    return $self->not_found unless $page;

    my $history = [];

    my @pages = $page->find_related('history', order_by => 'revision DESC');

    my $prev_revision = $page->get_column('revision');
    foreach my $page (@pages) {
        push @$history, {%{$page->to_hash}, prev_revision => $prev_revision};
        $prev_revision = $page->get_column('revision');
    }

    $self->set_var(page => $page->to_hash, history => $history);

    return;
}

1;
