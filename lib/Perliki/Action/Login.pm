package Perliki::Action::Login;

use strict;
use warnings;

use base 'Perliki::Action::FormBase';

use Digest::MD5 ();
use Perliki::DB::User;
use Plack::Session;

sub BUILD {
    my $self = shift;

    $self->SUPER::BUILD();

    $self->{validator}->add_field('name');
    $self->{validator}->add_field('password');
}

sub run {
    my $self = shift;

    return unless $self->req->method eq 'POST';

    if ($self->validate) {
        if (my $user = $self->_load_user) {
            my $session = Plack::Session->new($self->env->to_hash);
            $session->set(user => {id => $user->get_column('id')});
            return $self->redirect('index');
        }
        else {
            $self->set_var(
                errors => {name => 'Unknown user or wrong password'});
        }
    }
    else {
        $self->set_var(errors => $self->{validator}->errors);
    }

    return $self;
}

sub _load_user {
    my $self = shift;

    my $password = Digest::MD5::md5_hex($self->req->param('password'));

    return Perliki::DB::User->new->table->find(
        first => 1,
        where => [name => $self->req->param('name'), password => $password]
    );
}

1;
