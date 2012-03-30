package UpdateTest;

use strict;
use warnings;

use base 'ActionTestBase';

use Test::More;
use Test::Fatal;
use Test::MockObject::Extends;

use Perliki::Action::Update;
use Lamework::DispatchedRequest;

sub setup : Test(setup) {
    my $self = shift;

    $self->SUPER::setup;

    Perliki::DB::Page->new(
        name    => 'foo',
        user_id => 999,
        content => 'not_modified'
    )->create;
}

sub throw_404_when_page_not_exists : Test {
    my $self = shift;

    Perliki::DB::Page->table->delete;

    my $action = $self->_build_action(captures => {name => 'foo'}, env => {});

    ok(exception { $action->run });
}

sub set_page_on_GET_method : Test {
    my $self = shift;

    my $action = $self->_build_action(
        captures => {name           => 'foo'},
        env      => {REQUEST_METHOD => 'GET'}
    );

    $action->run;

    my $vars = $action->env->get('displayer.vars');

    ok($vars->{page});
}

sub set_validation_errors : Test {
    my $self = shift;

    my $action = $self->_build_action(
        captures => {name           => 'foo'},
        env      => {REQUEST_METHOD => 'POST'}
    );

    $action->run;

    my $errors = $action->env->get('displayer.vars')->{errors};

    is_deeply($errors, {content => 'REQUIRED'});
}

#sub on_preview_set_vars : Test {
#    my $self = shift;
#
#    my $action = $self->_build_action(
#        captures => {name => 'foo'},
#        env      => $self->_build_env(
#            method  => 'POST',
#            query   => 'preview=1',
#            content => 'content=foobar'
#        )
#    );
#
#    $action->run;
#
#    my $vars = $action->env->get('displayer.vars');
#
#    is_deeply($vars, {params => {content => 'foobar'}, preview => 'foobar'});
#}

sub update_page : Test {
    my $self = shift;

    my $action = $self->_build_action(
        captures => {name => 'foo'},
        env =>
          $self->_build_env(method => 'POST', content => 'content=foobar')
    );

    $action->run;

    my $vars = $action->env->get('displayer.vars');

    my $page = Perliki::DB::Page->new->table->find(first => 1);
    ok($page);
}

sub set_correct_page_columns : Test(2) {
    my $self = shift;

    my $action = $self->_build_action(
        captures => {name => 'foo'},
        env =>
          $self->_build_env(method => 'POST', content => 'content=foobar')
    );

    $action->run;

    my $vars = $action->env->get('displayer.vars');

    my $page = Perliki::DB::Page->new->table->find(first => 1);

    is($page->get_column('content'), 'foobar');
    is($page->get_column('user_id'), 1);
}

sub redirect_after_update : Test {
    my $self = shift;

    my $action = $self->_build_action(
        captures => {name => 'foo'},
        env =>
          $self->_build_env(method => 'POST', content => 'content=foobar')
    );

    $action->run;

    my $vars = $action->env->get('displayer.vars');

    is($action->res->code, 302);
}

sub _build_action {
    my $self = shift;
    my (%params) = @_;

    my $captures = delete $params{captures};

    my $action = Perliki::Action::Update->new(%params);

    my $dr = Lamework::DispatchedRequest->new(captures => $captures);
    $dr = Test::MockObject::Extends->new($dr);
    $dr->mock(build_path => sub {'/'});

    $action->env->set('dispatched_request' => $dr);

    return $action;
}

1;
