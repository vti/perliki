package ActionTestBase;

use strict;
use warnings;

use base 'DBTestBase';

use Test::More;
use Test::Fatal;
use Test::MockObject::Extends;

use Perliki::DB::User;
use Turnaround::DispatchedRequest;

sub setup : Test(setup) {
    my $self = shift;

    $self->SUPER::setup;

    $self->{user} = $self->_create_user;
}

sub _build_env {
    my $self = shift;
    my (%params) = @_;

    my $env = {REQUEST_METHOD => delete $params{method}};

    if (my $query = delete $params{query}) {
        $env->{QUERY_STRING} = $query;
    }

    if (my $content = delete $params{content}) {
        open my $input, '<', \$content;
        $env = {
            %$env,
            CONTENT_LENGTH => length($content),
            CONTENT_TYPE   => 'application/x-www-form-urlencoded',
            'psgi.input'   => $input
        };
    }

    if (my $user = $self->{user}) {
        $env->{'turnaround.user'} = $user;
    }

    $env = {%$env, %params};

    return $env;
}

sub _create_user {
    my $self = shift;

    return Perliki::DB::User->new(name => 'user', password => '123', @_)->create;
}

1;
