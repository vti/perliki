package Perliki::DB::Page;

use strict;
use warnings;

use base 'Perliki::DB';

use Perliki::DB::History;
use Text::MultiMarkdown;

__PACKAGE__->meta(
    table   => 'wiki',
    columns => [qw/id root_id user_id revision created updated name content/],
    primary_key    => 'id',
    auto_increment => 'id',
    unique_keys    => ['name'],
    relationships  => {
        root => {
            type  => 'many to one',
            class => 'Perliki::DB::Page',
            map   => {root_id => 'id'}
        },
        history => {
            type  => 'one to many',
            class => 'Perliki::DB::History',
            map   => {id => 'root_id'}
        },
        user => {
            type  => 'many to one',
            class => 'Perliki::DB::User',
            map   => {user_id => 'id'}
        }
    }
);

sub has_history {
    my $self = shift;

    my $revision = $self->get_column('revision');
    return $revision && $revision > 1;
}

sub create {
    my $self = shift;

    my $time = time;

    $self->set_column(created => $time);
    $self->set_column(updated => $time);

    $self->set_column(revision => 1);

    return $self->SUPER::create();
}

sub update {
    my $self = shift;

    return $self unless $self->is_modified;

    my $initial = ref($self)->new(id => $self->get_column('id'))->load;

    my $history = $self->create_related('history', $initial->clone->to_hash);

    $self->set_column(revision => $self->get_column('revision') + 1);
    $self->set_column(updated  => time);

    if (!$self->get_column('root_id')) {
        $self->set_column(root_id => $history->get_column('id'));
    }

    $self->SUPER::update;

    return $self;
}

sub to_hash {
    my $self = shift;

    my $hash = $self->SUPER::to_hash;

    $hash->{has_history} = $self->has_history;
    $hash->{content_rendered} = $self->_render($self->get_column('content'));

    return $hash;
}

sub _render {
    my $self = shift;
    my ($text) = @_;

    my $md = Text::MultiMarkdown->new(base_url => '/wiki/', use_wikilinks => 1);

    return $md->markdown($text);
}


1;
