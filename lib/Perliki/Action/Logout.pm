package Perliki::Action::Logout;

use strict;
use warnings;

use base 'Turnaround::Action';

use Plack::Session;

sub run {
    my $self = shift;

    my $session = Plack::Session->new($self->env);
    $session->expire;

    return $self->redirect('/');
}

1;
