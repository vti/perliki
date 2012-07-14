package Perliki;

use strict;
use warnings;

use base 'Turnaround';

use Turnaround::ACL::FromConfig;
use Turnaround::ActionFactory;
use Turnaround::Dispatcher::Routes;
use Turnaround::Displayer;
use Turnaround::HelperFactory;
use Turnaround::Renderer::Caml;
use Turnaround::Routes::FromConfig;

use Perliki::DB;
use Perliki::DB::User;
use Perliki::Config;

our $VERSION = '0.01';

sub startup {
    my $self = shift;

    my $config =
      Perliki::Config->new(home => $self->{home}->catfile('configs'))
      ->load('config.yml');
    $self->{config} = $config;

    Perliki::DB->init_db(%{$config->{database}});

    my $displayer = Turnaround::Displayer->new(
        renderer => Turnaround::Renderer::Caml->new(home => $self->{home}),
        layout   => 'layout.caml'
    );

    $self->add_middleware(
        'ErrorDocument',
        403        => '/forbidden',
        404        => '/not_found',
        subrequest => 1
    );

    $self->add_middleware('HTTPExceptions');

    $self->add_middleware(
        'Static',
        path => qr{^/(images|js|css)/},
        root => $self->{home}->catfile('public')
    );

    $self->add_middleware(
        'Session::Cookie',
        secret  => $config->{session}->{secret},
        expires => $config->{session}->{expires}
    );

    $self->add_middleware(
        'RequestDispatcher',
        dispatcher => Turnaround::Dispatcher::Routes->new(
            routes => Turnaround::Routes::FromConfig->new->load(
                $self->{home}->catfile('configs/routes.yml')
            )
        )
    );

    $self->add_middleware(
        'User',
        user_loader => sub {
            my ($session, $env) = @_;

            return unless $session->{user};

            my $user = Perliki::DB::User->new(id => $session->{user}->{id})->load;
            return unless $user;

            $env->{'turnaround.displayer.vars'}->{'user'} = $user->to_hash;
            return $user;
        }
    );

    $self->add_middleware(
        'ACL',
        acl => Turnaround::ACL::FromConfig->new->load(
            $self->{home}->catfile('configs/acl.yml')
        ),
        redirect_to => '/login'
    );

    $self->add_middleware(
        'ActionDispatcher',
        action_factory => Turnaround::ActionFactory->new(
            namespace => ref($self) . '::Action::'
        )
    );

    $self->add_middleware(
        sub {
            my $app = shift;
            sub {
                my $env = shift;

                $env->{'turnaround.displayer.vars'}->{'title'} = $config->{wiki}->{title};

                return $app->($env);
              }
        }
    );

    $self->add_middleware('ViewDisplayer', displayer => $displayer);

    $self->register_plugin('I18N');

    return $self;
}

1;
