package Perliki::Action::Update;

use strict;
use warnings;

use base 'Perliki::Action::PageBase';

use Perliki::DB::Page;

sub run {
    my $self = shift;

    my $name = $self->captures->{name};

    my $page = Perliki::DB::Page->new(name => $name)->load;
    return $self->not_found unless $page;

    if ($self->req->method eq 'POST') {
        if ($self->validate) {
            $page->set_columns(%{$self->validated_params},
                user_id => $self->env->get('user')->get_column('id'));
            $page->update;

            return $self->redirect('page', name => $name);
        }
        else {
            $self->set_var(
                params => $self->req->parameters,
                errors => $self->{validator}->errors
            );
        }
    }
    else {
        $self->set_var(page => $page->to_hash);
    }
}

1;
