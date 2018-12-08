#
# Create a test database and load the SQL schema.  The connect_ok code
# is borrowed from Test module of the DBD::SQLite distribution.
#
package TkTest;

use strict;
use warnings;

use Test::More;
use Exporter ();
use Exporter qw(import);
use File::Slurp qw(read_file);
use File::HomeDir;
use File::Spec::Functions;
use DBI;
use Text::CSV_XS;
use Try::Tiny;

our @EXPORT_OK = qw(make_database);

# A simplified connect function for the most common case
sub connect_ok {
    my $dbfile = shift;
    my $attr = { @_ };

    my @params = ( "dbi:SQLite:dbname=$dbfile", '', '' );
    if ( %{$attr} ) {
        push @params, $attr;
    }

    my $dbh = DBI->connect( @params );
    isa_ok( $dbh, 'DBI::db' );

    return $dbh;
}

# Make database and load the schema from an SQL file.

sub make_database {
    my $dbfile = get_testdb_filename();

    if (-f $dbfile) {
        unlink $dbfile;
        diag "Old classicmodels test database dropped";
    }

    my $dbh = connect_ok($dbfile);

    $dbh->{sqlite_allow_multiple_statements} = 1; # cool!

    my $sql_text = read_file( 'share/cm/sql/classicmodels-si.sql' );

    my $rv = $dbh->do($sql_text) or die $dbh->errstr;

    load_classicmodels_data();

    return $rv;
}

#--

sub load_classicmodels_data {

    my $dbfile = get_testdb_filename();
    my $dbh    = connect_ok($dbfile);

    $dbh->{AutoCommit} = 0;    # enable transactions, if possible
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
    $dbh->{ShowErrorStatement} = 0;

    my $data_files = data_file_list();

    diag "Created new database, loading data...";
    foreach my $data_file ( @{$data_files} ) {
        load_table_data( $dbh, $data_file );
    }

    return;
}

sub load_table_data {
    my ($dbh, $data_file) = @_;

    my @rows;

    my $csv = Text::CSV_XS->new(
        {
            sep_char       => ';',
            always_quote   => 0,
            binary         => 1,
            blank_is_undef => 1,
        }
    ) or die "Cannot use CSV: " . Text::CSV->error_diag();

    open my $fh, "<:encoding(utf8)", $data_file
        or die "Error: $!";

    my $table = $csv->getline($fh)->[0];
    # diag "Loading data for '$table'";

    my $header = $csv->getline($fh);

    my $sql
        = "INSERT INTO $table ("
        . join( ',', @{$header} )
        . ') VALUES ('
        . ( '?, ' x $#{$header} ) . '?)';

    try {
        my $st = $dbh->prepare($sql);

        while ( my $row = $csv->getline($fh) ) {
            $st->execute( @{$row} );
        }

        $dbh->commit;    # commit the changes if we got this far
    }
    catch {
        warn "caught error: $_";
        $dbh->rollback;    # undo the incomplete changes
    };

    return;
}

#--- Helper subs

sub get_testdb_filename {
    return catfile(File::HomeDir->my_data, 'classicmodels.db');
}

sub get_data_dir {
    return catdir( 'share', 'cm', 'data' );
}

sub data_file_list {
    my $dir = get_data_dir();

    my @files = glob("$dir/*.dat");

    return \@files;
}

1;
