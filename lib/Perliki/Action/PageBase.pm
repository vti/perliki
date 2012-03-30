package Perliki::Action::PageBase;

use strict;
use warnings;

use base 'Lamework::Action';

use Input::Validator;
use Perliki::DB::Page;

sub BUILD {
    my $self = shift;

    $self->SUPER::BUILD();

    $self->{validator} ||= Input::Validator->new;

    $self->{validator}->field('content')->required(1);
}

sub validate {
    my $self = shift;

    my $validator = $self->{validator};

    return $validator->validate($self->req->parameters);
}

sub validated_params {
    my $self = shift;

    return $self->{validator}->values;
}

1;
