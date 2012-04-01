package Perliki::Action::PageBase;

use strict;
use warnings;

use base 'Perliki::Action::FormBase';

sub BUILD {
    my $self = shift;

    $self->SUPER::BUILD();

    $self->{validator}->field('content')->required(1);
}

1;
