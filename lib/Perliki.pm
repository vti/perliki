package Perliki;

use strict;
use warnings;

use base 'Lamework';

use Lamework::ACL;
use Lamework::ActionFactory;
use Lamework::Dispatcher::Routes;
use Lamework::Displayer;
use Lamework::HelperFactory;
use Lamework::HTTPExceptionResolver;
use Lamework::Renderer::Caml;
use Lamework::Routes;

use Perliki::DB;
use Perliki::DB::User;
use Perliki::Config;

sub startup {
    my $self = shift;

    my $config =
      Perliki::Config->new(home => $self->{home}->to_string)->load('config.yml');
    $self->{config} = $config;

    Perliki::DB->init_db(%{$config->{database}});

    my $displayer = Lamework::Displayer->new(
        renderer => Lamework::Renderer::Caml->new(home => $self->{home}),
        layout   => 'layout.caml'
    );

    $self->add_middleware('HTTPExceptions',
        resolver =>
          Lamework::HTTPExceptionResolver->new->build('template', displayer => $displayer));

    $self->add_middleware(
        'Static',
        path => qr{^/(images|js|css)/},
        root => $self->{home}->catfile('public')
    );

    $self->add_middleware(
        'Session::Cookie',
        secret  => $self->{config}->{session}->{secret},
        expires => $self->{config}->{session}->{expires}
    );

    $self->add_middleware('RequestDispatcher',
        dispatcher =>
          Lamework::Dispatcher::Routes->new(routes => $self->_build_routes));

    $self->add_middleware(
        'User',
        user_loader => sub {
            my ($params, $env) = @_;

            my $user = Perliki::DB::User->new(id => $params->{id})->load;
            return unless $user;

            Lamework::Env->new($env)
              ->set('displayer.vars.user', $user->to_hash);
            return $user;
        }
    );

    $self->add_middleware('ACL', acl => $self->_build_acl, redirect_to => '/login');

    $self->add_middleware(
        'ActionDispatcher',
        action_factory => Lamework::ActionFactory->new(
            namespace => ref($self) . '::Action::'
        )
    );

    $self->add_middleware(
        sub {
            my $app = shift;
            sub {
                my $env = shift;

                Lamework::Env->new($env)->set(
                    'displayer.vars.helpers',
                    Lamework::HelperFactory->new(
                        namespace => 'Perliki::Helper::'
                    )
                );

                return $app->($env);
              }
        }
    );

    $self->add_middleware('ViewDisplayer', displayer => $displayer);

    return $self;
}

sub _build_routes {
    my $self = shift;

    my $routes = Lamework::Routes->new;

    $routes->add_route('/',              name => 'index');
    $routes->add_route('/wiki/',         name => 'pages');
    $routes->add_route('/wiki/:name',    name => 'page');
    $routes->add_route('/create/:name',  name => 'create');
    $routes->add_route('/update/:name',  name => 'update');
    $routes->add_route('/history/:name', name => 'history');
    $routes->add_route('/diff/:name',    name => 'diff');
    $routes->add_route('/changes',       name => 'changes');
    $routes->add_route('/login',         name => 'login');
    $routes->add_route('/logout',        name => 'logout');

    return $routes;
}

sub _build_acl {
    my $self = shift;

    my $acl = Lamework::ACL->new;

    $acl->add_role('anonymous');
    $acl->allow('anonymous', 'login');

    if (!$self->{config}->{wiki}->{private}) {
        $acl->allow('anonymous', 'index');
        $acl->allow('anonymous', 'page');
        $acl->allow('anonymous', 'pages');
        $acl->allow('anonymous', 'changes');
        $acl->allow('anonymous', 'diff');
        $acl->allow('anonymous', 'history');
    }

    $acl->add_role('user');
    $acl->allow('user', '*');
    $acl->deny('user', 'login');

    return $acl;
}

1;
