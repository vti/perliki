package Perliki::Action::Changes;

use strict;
use warnings;

use base 'Turnaround::Action';

use Perliki::DB::Page;

sub run {
    my $self = shift;

    my @pages = Perliki::DB::Page->new->table->find(
        order_by => 'updated DESC',
        limit    => 10
    );

    @pages = map {
        {
            %{$_->to_hash},
              is_created => $_->get_column('revision') == 1,
              is_updated => !($_->get_column('revision') == 1)
        }
    } @pages;

    $self->set_var(pages => [@pages]);
}

1;
