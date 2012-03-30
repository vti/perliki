#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use FindBin '$RealBin';
use Plack::Runner;

my $psgi = File::Spec->catfile($RealBin, '..', 'app.psgi');
die "Can't open PSGI file: $psgi" unless -r $psgi;

Plack::Runner->run($psgi);
