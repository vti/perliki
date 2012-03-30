package Perliki::DB::User;

use strict;
use warnings;

use base 'Perliki::DB';

use Digest::MD5 ();

__PACKAGE__->meta(
    table          => 'user',
    columns        => [qw/id name password created/],
    primary_key    => 'id',
    auto_increment => 'id',
    unique_keys    => ['name']
);

sub role {'user'}

sub create {
    my $self = shift;

    my $time = time;

    $self->set_column(created => $time);

    return $self->SUPER::create();
}

sub reset_password {
    my $self = shift;

    my @a = (0 .. 9, 'a' .. 'z', 'A' .. 'Z', '+', '/');

    my $password = '';

    for (1 .. 16) {
        $password .= $a[rand(scalar @a)];
    }

    $self->set(password => Digest::MD5::md5_hex($password));

    return $password;
}

sub check_password {
    my $self = shift;
    my ($password) = @_;

    return Digest::MD5::md5_hex($self->get_column('password')) eq $password;
}

1;
