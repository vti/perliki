package Perliki::Action::FormBase;

use strict;
use warnings;

use base 'Turnaround::Action';

use Turnaround::Validator;

sub BUILD {
    my $self = shift;

    $self->SUPER::BUILD();

    $self->{validator} ||= Turnaround::Validator->new;
}

sub validate {
    my $self = shift;

    my $validator = $self->{validator};

    return $validator->validate({$self->req->parameters->flatten});
}

sub validated_params {
    my $self = shift;

    return $self->{validator}->validated_params;
}

sub merge_with_params {
    my $self = shift;
    my ($model) = @_;

    my @names = $self->{validator}->field_names;

    my $merge = {};
    foreach my $name (@names) {
        my $param = $self->req->param($name);
        $merge->{$name} = defined $param ? $param : $model->{$name};
    }

    return $merge;
}

1;
