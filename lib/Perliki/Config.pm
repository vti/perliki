package Perliki::Config;

use strict;
use warnings;

use base 'Turnaround::Config';

use File::Spec;

sub BUILD {
    my $self = shift;

    $self->{preprocess} ||= {__HOME__ => $self->{home}};
}

sub load {
    my $self = shift;

    my $path = File::Spec->catfile($self->{home}, @_);

    return $self->SUPER::load($path);
}

1;
