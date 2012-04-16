package Perliki;

use strict;
use warnings;

use base 'Lamework';

use Lamework::ACL::Loader;
use Lamework::ActionFactory;
use Lamework::Dispatcher::Routes;
use Lamework::Displayer;
use Lamework::HelperFactory;
use Lamework::I18N;
use Lamework::Renderer::Caml;
use Lamework::Routes::Loader;

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

    my $i18n = Lamework::I18N->new(app_class => __PACKAGE__);

    my $displayer = Lamework::Displayer->new(
        renderer => Lamework::Renderer::Caml->new(home => $self->{home}),
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

    $self->add_middleware('I18N', i18n => $i18n);

    $self->add_middleware(
        'RequestDispatcher',
        dispatcher => Lamework::Dispatcher::Routes->new(
            routes => Lamework::Routes::Loader->new->load(
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

            $env->{'lamework.displayer.vars'}->{'user'} = $user->to_hash;
            return $user;
        }
    );

    $self->add_middleware(
        'ACL',
        acl => Lamework::ACL::Loader->load(
            $self->{home}->catfile('configs/acl.yml')
        ),
        redirect_to => '/login'
    );

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

                $env->{'lamework.displayer.vars'}->{'helpers'} =
                  Lamework::HelperFactory->new(
                    namespace => 'Perliki::Helper::');

                $env->{'lamework.displayer.vars'}->{'title'} = $config->{wiki}->{title};

                my $languages_names = $i18n->get_languages_names;
                if (keys %$languages_names > 1) {
                    $env->{'lamework.displayer.vars'}->{'languages'} =
                      [map { {code => $_, name => $languages_names->{$_}} }
                          keys %$languages_names];
                }

                $env->{'lamework.displayer.vars'}->{'loc'} =
                  sub { shift; $env->{'lamework.i18n.maketext'}->loc(@_) };

                return $app->($env);
              }
        }
    );

    $self->add_middleware('ViewDisplayer', displayer => $displayer);

    return $self;
}

1;
