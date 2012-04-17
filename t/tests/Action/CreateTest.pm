package CreateTest;

use strict;
use warnings;

use base 'ActionTestBase';

use Test::More;
use Test::Fatal;
use Test::MockObject::Extends;

use Perliki::DB::User;
use Perliki::Action::Create;
use Turnaround::DispatchedRequest;

sub throw_404_when_page_exists : Test {
    my $self = shift;

    Perliki::DB::Page->new(name => 'foo', user_id => 1)->create;

    my $action = $self->_build_action(captures => {name => 'foo'}, env => {});

    ok(exception { $action->run });
}

sub do_nothing_on_GET_method : Test {
    my $self = shift;

    my $action = $self->_build_action(
        captures => {name           => 'foo'},
        env      => {REQUEST_METHOD => 'GET'}
    );

    $action->run;

    ok(!$action->env->{'turnaround.displayer.vars'});
}

sub set_validation_errors : Test {
    my $self = shift;

    my $action = $self->_build_action(
        captures => {name           => 'foo'},
        env      => {REQUEST_METHOD => 'POST'}
    );

    $action->run;

    my $errors = $action->env->{'turnaround.displayer.vars'}->{errors};

    is_deeply($errors, {content => 'REQUIRED'});
}

sub on_preview_set_vars : Test(3) {
    my $self = shift;

    my $action = $self->_build_action(
        captures => {name => 'foo'},
        env      => $self->_build_env(
            method  => 'POST',
            query   => 'preview=1',
            content => 'content=foobar'
        )
    );

    $action->run;

    my $vars = $action->env->{'turnaround.displayer.vars'};

    ok(exists $vars->{form}->{content});
    ok(exists $vars->{preview});
    ok(exists $vars->{page});
}

sub create_page : Test {
    my $self = shift;

    my $action = $self->_build_action(
        captures => {name => 'foo'},
        env =>
          $self->_build_env(method => 'POST', content => 'content=foobar')
    );

    $action->run;

    my $vars = $action->env->{'turnaround.displayer.vars'};

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

    my $vars = $action->env->{'turnaround.displayer.vars'};

    my $page = Perliki::DB::Page->new->table->find(first => 1);

    is($page->get_column('content'), 'foobar');
    is($page->get_column('user_id'), 1);
}

sub redirect_after_creation : Test {
    my $self = shift;

    my $action = $self->_build_action(
        captures => {name => 'foo'},
        env =>
          $self->_build_env(method => 'POST', content => 'content=foobar')
    );

    is($action->run->code, 302);
}

sub _build_action {
    my $self = shift;
    my (%params) = @_;

    my $captures = delete $params{captures};

    my $action = Perliki::Action::Create->new(%params);

    my $dr = Turnaround::DispatchedRequest->new(captures => $captures);
    $dr = Test::MockObject::Extends->new($dr);
    $dr->mock(build_path => sub {'/'});

    $action->env->{'turnaround.dispatched_request'} = $dr;

    return $action;
}

1;
