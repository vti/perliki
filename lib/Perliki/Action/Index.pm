package Perliki::Action::Index;

use strict;
use warnings;

use base 'Turnaround::Action';

use Perliki::DB::Page;

sub run {
    my $self = shift;

    my $name = 'Index';

    my $page = Perliki::DB::Page->new(name => $name)->load;
    return $self->redirect('page', name => $name) if $page;
}

1;
