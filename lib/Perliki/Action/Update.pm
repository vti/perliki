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

            if ($self->req->param('preview')) {
                $self->set_var(preview => 1);
            }
            else {
                $page->update;

                return $self->redirect('page', name => $name);
            }
        }
        else {
            $self->set_var(errors => $self->{validator}->errors);
        }
    }

    $self->set_var(
        page => $page->to_hash,
        form => $self->merge_with_params($page->to_hash),
    );
}

1;
