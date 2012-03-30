package DBTestBase;

use strict;
use warnings;

use base 'TestBase';

use Perliki::DB;

sub setup : Test(setup) {
    my $self = shift;

    my $dbh =
      DBI->connect('dbi:SQLite::memory:', '', '',
        {sqlite_unicode => 1, RaiseError => 1});
    die $DBI::errorstr unless $dbh;

    $dbh->do("PRAGMA default_synchronous = OFF");
    $dbh->do("PRAGMA temp_store = MEMORY");

    my $file =
      do { local $/; open my $fh, 'schema/SQLite.sql' or die $!; <$fh> };
    my @sql = split /;/, $file;
    $dbh->do($_) for @sql;

    Perliki::DB->init_db($dbh);
}

1;
