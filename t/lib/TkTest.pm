#
# Create a test database and load the SQL schema.  Much of the code
# is borrowed from Test module of the DBD::SQLite distribution.
#

package t::lib::TkTest;

use strict;
use warnings;

use Exporter ();
use Exporter qw(import);
use File::Slurp qw(read_file);
use DBI;

our @EXPORT_OK = qw(make_database);

my $parent;
my $dbfile;

BEGIN {
    $dbfile = 'classicmodels';
    $parent = $$;
}

# Delete temporary files
sub clean {
    return if $$ != $parent;
    unlink $dbfile if -f $dbfile;
}

# Clean up temporary test files at the beginning of the test script.
BEGIN { clean() }

# A simplified connect function for the most common case
sub connect_ok {
    my $attr = { @_ };

    my @params = ( "dbi:SQLite:dbname=$dbfile", '', '' );
    if ( %{$attr} ) {
        push @params, $attr;
    }

    my $dbh = DBI->connect( @params );
    Test::More::isa_ok( $dbh, 'DBI::db' );

    return $dbh;
}

# Make database and load the schema from an SQL file.
sub make_database {
    my $dbh = connect_ok();

    $dbh->{sqlite_allow_multiple_statements} = 1; # cool!

    my $sql_text = read_file( 'sql/classicmodels-si.sql' );

    my $rv = $dbh->do($sql_text) or die $dbh->errstr;

    return $rv;
}

1;
