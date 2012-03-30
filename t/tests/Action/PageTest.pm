package PageTest;

use strict;
use warnings;

use base 'TestBase';

use Test::More;
use Test::Fatal;

use Perliki::Action::Page;

sub should_redirect_to_page_creation_when_not_found : Test {
    my $self = shift;

    #my $action = $self->_build_action;

    #$action->run;
}

sub _build_action {
    my $self = shift;

    return Perliki::Action::Page->new(@_);
}

1;
