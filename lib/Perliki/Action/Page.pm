package Perliki::Action::Page;

use strict;
use warnings;

use base 'Lamework::Action';

use Text::MultiMarkdown ();
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

    my $content = $page->get_column('content');
    $content = $self->_render($content);

    $self->set_var(page => $page->to_hash, content => $content);
}

sub _render {
    my $self = shift;
    my ($text) = @_;

    my $md = Text::MultiMarkdown->new(base_url => '/wiki/', use_wikilinks => 1);

    return $md->markdown($text);
}

1;
