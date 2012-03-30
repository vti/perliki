package Perliki::Helper::Date;

use strict;
use warnings;

use Time::Piece;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub format {
    sub {
        my (undef, $date) = @_;

        Time::Piece->strptime($date, '%s')->strftime('%Y-%m-%d %T');
    }
}

1;
