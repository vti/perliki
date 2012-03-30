package DBPageTest;

use strict;
use warnings;

use base 'DBTestBase';

use Test::More;
use Test::Fatal;

use Perliki::DB::Page;

sub should_create_page_with_revision_1 : Test {
    my $self = shift;

    my $page = $self->_build_page(
        name    => 'root',
        content => 'story',
        user_id => 1
    );
    $page->create;

    is($page->get_column('revision'), 1);
}

sub should_increment_revision_on_update : Test {
    my $self = shift;

    my $page = $self->_build_page(
        name    => 'root',
        content => 'story',
        user_id => 1
    );
    $page->create;

    $page->set_column(content => 'next');
    $page->update;

    is($page->get_column('revision'), 2);
}

sub should_create_history_entry : Test(2) {
    my $self = shift;

    my $page = $self->_build_page(
        name    => 'root',
        content => 'story',
        user_id => 1
    );
    $page->create;

    $page->set_column(content => 'next');
    $page->update;

    my $history = Perliki::DB::History->new->table->find(
        first => 1,
        where => [root_id => $page->get_column('id')]
    );

    is($history->get_column('revision'), 1);
    is($history->get_column('content'), 'story');
}

sub should_create_history_entries : Test {
    my $self = shift;

    my $page = $self->_build_page(
        name    => 'root',
        content => 'story',
        user_id => 1
    );
    $page->create;

    for (1 .. 10) {
        $page->set_column(content => 'next' . $_);
        $page->update;
    }

    is($page->count_related('history'), 10);
}

sub _build_page {
    my $self = shift;

    return Perliki::DB::Page->new(@_);
}

1;
