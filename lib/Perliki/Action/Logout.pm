package Perliki::Action::Logout;

use strict;
use warnings;

use base 'Lamework::Action';

use Plack::Session;

sub run {
    my $self = shift;

    my $session = Plack::Session->new($self->env->to_hash);
    $session->expire;

    $self->redirect('/');
}

1;
