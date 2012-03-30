package Perliki::Action::Create;

use strict;
use warnings;

use base 'Perliki::Action::PageBase';

sub run {
    my $self = shift;

    my $name = $self->captures->{name};

    return $self->not_found if Perliki::DB::Page->new(name => $name)->load;

    return unless $self->req->method eq 'POST';

    if ($self->validate) {
        my $page = Perliki::DB::Page->new(
            name => $name,
            %{$self->validated_params},
            user_id => $self->env->get('user')->get_column('id')
        );

        if ($self->req->param('preview')) {
            $self->set_var(params => $self->validated_params);
            $self->set_var(preview => $self->req->param('content'));
        }
        else {
            $page->create;

            return $self->redirect('page', name => $name);
        }
    }
    else {
        $self->set_var(params => $self->validated_params);
        $self->set_var(errors => $self->{validator}->errors);
    }
}

1;
