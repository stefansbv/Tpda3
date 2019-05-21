#!/usr/bin/perl

use strict;
use warnings;

use Data::Dump;

use Storable qw(retrieve);

# http://perldoc.perl.org/perluniintro.html
# use encoding 'utf-8';

my $file_dat = $ARGV[0] || usage();

my $colref = retrieve($file_dat);

die "Unable to retrieve from record!\n" unless defined $colref;

dd $colref;

sub usage {
    print "$0 <filename.dat>\n";
    exit;
}
