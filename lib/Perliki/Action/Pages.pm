package Perliki::Action::Pages;

use strict;
use warnings;

use base 'Turnaround::Action';

use Perliki::DB::Page;

sub run {
    my $self = shift;

    my @pages = Perliki::DB::Page->new->table->find(order_by => 'created DESC');

    @pages = map { $_->to_hash } @pages;

    $self->set_var(pages => [@pages]);
}

1;
