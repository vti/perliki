package LoginTest;

use strict;
use warnings;

use base 'ActionTestBase';

use Test::More;
use Test::Fatal;
use Test::MockObject::Extends;

use Digest::MD5 ();
use Perliki::Action::Login;
use Lamework::DispatchedRequest;

sub do_nothing_on_GET_method : Test {
    my $self = shift;

    my $action = $self->_build_action(env => {REQUEST_METHOD => 'GET'});

    $action->run;

    ok(!$action->env->get('displayer.vars'));
}

sub set_validation_errors : Test {
    my $self = shift;

    my $action = $self->_build_action(env => {REQUEST_METHOD => 'POST'});

    $action->run;

    my $errors = $action->env->get('displayer.vars')->{errors};

    is_deeply($errors, {name => 'REQUIRED', password => 'REQUIRED'});
}

sub set_validation_errors_on_unknown_user : Test {
    my $self = shift;

    my $action = $self->_build_action(
        env => $self->_build_env(
            method  => 'POST',
            content => 'name=foo&password=bar'
        )
    );

    $action->run;

    my $errors = $action->env->get('displayer.vars')->{errors};

    is_deeply($errors, {name => 'Unknown user or wrong password'});
}

sub set_validation_errors_on_unknown_password : Test {
    my $self = shift;

    Perliki::DB::User->new(name => 'foo', password => 'foo')->create;

    my $action = $self->_build_action(
        env => $self->_build_env(
            method  => 'POST',
            content => 'name=foo&password=bar'
        )
    );

    $action->run;

    my $errors = $action->env->get('displayer.vars')->{errors};

    is_deeply($errors, {name => 'Unknown user or wrong password'});
}

sub set_session_after_login : Test {
    my $self = shift;

    my $user = Perliki::DB::User->new(
        name     => 'foo',
        password => Digest::MD5::md5_hex('bar')
    )->create;

    my $action = $self->_build_action(
        env => $self->_build_env(
            'psgix.session'         => {},
            'psgix.session.options' => {},
            method                  => 'POST',
            content                 => 'name=foo&password=bar'
        )
    );

    $action->run;

    is($action->env->{'psgix.session'}->{user}->{id}, $user->get_column('id'));
}

sub redirect_after_login : Test {
    my $self = shift;

    Perliki::DB::User->new(
        name     => 'foo',
        password => Digest::MD5::md5_hex('bar')
    )->create;

    my $action = $self->_build_action(
        env => $self->_build_env(
            'psgix.session'         => {},
            'psgix.session.options' => {},
            method                  => 'POST',
            content                 => 'name=foo&password=bar'
        )
    );

    $action->run;

    is($action->res->code, 302);
}

sub _build_action {
    my $self = shift;
    my (%params) = @_;

    my $action = Perliki::Action::Login->new(%params);

    my $dr = Lamework::DispatchedRequest->new(captures => {});
    $dr = Test::MockObject::Extends->new($dr);
    $dr->mock(build_path => sub {'/'});

    $action->env->set('dispatched_request' => $dr);

    return $action;
}

1;
