package Perliki::DB::History;

use strict;
use warnings;

use base 'Perliki::DB';

__PACKAGE__->meta(
    table   => 'history',
    columns => [
        qw/id root_id user_id revision created updated content/,
    ],
    primary_key    => 'id',
    auto_increment => 'id',
    relationships => {
        user => {
            type  => 'many to one',
            class => 'Perliki::DB::User',
            map   => {user_id => 'id'}
        }
    }
);

sub create {
    my $self = shift;

    if (!$self->get_column('created')) {
        $self->set_column(created => time);
    }

    return $self->SUPER::create();
}

1;
