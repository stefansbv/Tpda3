#!/bin/env perl

use 5.010;
use strict;
use warnings;

use DBI;
use Try::Tiny;
use List::Util qw(any);

use Data::Printer;

my $dbh = db_connect();

# table_info_short($dbh, 'products');
table_info_short($dbh, 'customers');
# table_info_short($dbh, 'orders');

sub db_connect {

    my $dsn = qq{dbi:SQLite:dbname=classicmodels.db};

    my $dbh = DBI->connect(
        $dsn, undef, undef,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 1,
            PrintError       => 0,
            LongReadLen      => 524288,
            sqlite_unicode   => 1,
        }
    );

    return $dbh;
}

sub table_info_short {
    my ( $dbh, $table ) = @_;

    my $h_ref = $dbh->selectall_hashref("PRAGMA table_info($table)", 'cid');

    my $flds_ref = {};
    foreach my $cid ( sort keys %{$h_ref} ) {
        my $name       = $h_ref->{$cid}{name};
        my $dflt_value = $h_ref->{$cid}{dflt_value};
        my $notnull    = $h_ref->{$cid}{notnull};
        # my $pk         = $h_ref->{$cid}{pk};
        my $data_type  = $h_ref->{$cid}{type};

        # Parse type;
        my ($type, $precision, $scale);
        if ( $data_type =~ m{
               (\w+)                           # data type
               (?:\((\d+)(?:,(\d+))?\))?       # optional (precision[,scale])
             }x
         ) {
            $type      = $1;
            $precision = $2;
            $scale     = $3;
        }

        my $info = {
            pos         => $cid,
            name        => $name,
            type        => $type,
            is_nullable => $notnull ? 0 : 1,
            defa        => $dflt_value,
            length      => $precision,
            prec        => $precision,
            scale       => $scale,
        };
        $flds_ref->{$cid} = $info;
    }
p $flds_ref;
    return $flds_ref;
}
