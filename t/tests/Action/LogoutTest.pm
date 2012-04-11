package LogoutTest;

use strict;
use warnings;

use base 'ActionTestBase';

use Test::More;
use Test::Fatal;
use Test::MockObject::Extends;

use Perliki::Action::Logout;
use Lamework::DispatchedRequest;

sub remove_session : Test {
    my $self = shift;

    my $action = $self->_build_action(
        env => $self->_build_env(
            'psgix.session'         => {user => {id => 1}},
            'psgix.session.options' => {},
            method                  => 'GET'
        )
    );

    $action->run;

    is_deeply($action->env->{'psgix.session'}, {});
}

sub redirect_after_logout : Test {
    my $self = shift;

    Perliki::DB::User->new(
        name     => 'foo',
        password => Digest::MD5::md5_hex('bar')
    )->create;

    my $action = $self->_build_action(
        env => $self->_build_env(
            'psgix.session'         => {user => {id => 1}},
            'psgix.session.options' => {},
            method                  => 'GET',
        )
    );

    $action->run;

    is($action->res->code, 302);
}

sub _build_action {
    my $self = shift;
    my (%params) = @_;

    my $action = Perliki::Action::Logout->new(%params);

    my $dr = Lamework::DispatchedRequest->new(captures => {});
    $dr = Test::MockObject::Extends->new($dr);
    $dr->mock(build_path => sub {'/'});

    $action->env->{'lamework.dispatched_request'} = $dr;

    return $action;
}

1;
