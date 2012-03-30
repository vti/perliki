package Perliki::Action::Page;

use strict;
use warnings;

use base 'Lamework::Action';

use Perliki::DB::Page;

sub run {
    my $self = shift;

    my $name = $self->captures->{name};

    my $page = Perliki::DB::Page->new(name => $name)->load(with => 'user');
    return $self->redirect('create', name => $name) unless $page;

    my $revision = $self->req->param('revision');
    if ($revision && $revision != $page->get_column('revision')) {
        $page = $page->find_related(
            'history',
            where => [revision => $revision],
            with  => 'user',
            first => 1
        );
        return $self->not_found unless $page;
    }

    $self->set_var(page => $page->to_hash);
}

1;
