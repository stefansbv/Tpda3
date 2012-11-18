#
# Create a test database and load the SQL schema.  The connect_ok code
# is borrowed from Test module of the DBD::SQLite distribution.
#

package t::lib::TkTest;

use strict;
use warnings;

use Exporter ();
use Exporter qw(import);
use File::Slurp qw(read_file);
use File::HomeDir;
use File::Spec::Functions;
use DBI;

our @EXPORT_OK = qw(make_database);

my $dbfile = get_testdb_filename('classicmodels');

# A simplified connect function for the most common case
sub connect_ok {
    my $attr = { @_ };

    # Recreate database
    unlink $dbfile if $dbfile and -f $dbfile;

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

    my $sql_text = read_file( 'share/cm/sql/classicmodels-si.sql' );

    my $rv = $dbh->do($sql_text) or die $dbh->errstr;

    return $rv;
}

sub get_testdb_filename {
    my $dbname = shift;

    return catfile(File::HomeDir->my_data, "$dbname.db");
}

1;
