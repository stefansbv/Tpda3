#! perl
#
# Create a test database and load the SQL schema.  The connect_to_db
# code is borrowed from the Test module of the DBD::SQLite
# distribution.
#
# In this particular case the load order for tables is not important.
#
# This script is part of the Tpda3 application.
# Copyleft 2011-2012 Ștefan Suciu
#

use strict;
use warnings;

use Cava::Packager; 
use File::HomeDir;
use File::ShareDir qw(dist_dir);
use File::Spec::Functions;
use File::Slurp qw(read_file);
use DBI;
use Text::CSV_XS;
use Try::Tiny;

Cava::Packager::SetResourcePath('C:/dev/tpda3-src/share/cm');
	
create_classicmodels();

load_classicmodels_data();

#--- Main subs

sub connect_to_db {
    my $dbfile = shift;
    my $attr = { @_ };

    my @params = ( "dbi:SQLite:dbname=$dbfile", '', '' );
    if ( %{$attr} ) {
        push @params, $attr;
    }

    my $dbh = DBI->connect( @params );

    return $dbh;
}

=head2 create_classicmodels

Create the test database.

=cut

sub create_classicmodels {

    my $dbfile = get_testdb_filename();

    if (-f $dbfile) {
		exit 0; # Do nothing if DB exists
    }

    my $dbh = connect_to_db($dbfile);

    my $sql_file = get_sql_filename();
    my $sql_text;
    if (-f $sql_file) {
        $sql_text = read_file($sql_file);
    }
    else {
        print " SQL test database schema $sql_file not found!\n";
		exit 0;
    }

    $dbh->{sqlite_allow_multiple_statements} = 1;    # cool!

    $dbh->do($sql_text) or exit 0;

    $dbh->disconnect;

    return;
}

sub load_classicmodels_data {

    my $dbfile = get_testdb_filename();
    my $dbh    = connect_to_db($dbfile);

    $dbh->{AutoCommit} = 0;    # enable transactions, if possible
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
    $dbh->{ShowErrorStatement} = 0;

    my $data_files = data_file_list();

    foreach my $data_file ( @{$data_files} ) {
        load_table_data( $dbh, $data_file );
    }

    $dbh->disconnect;

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
    print "Loading data for '$table'...";

    my $header = $csv->getline($fh);
    # print "Header is [ ", join( ', ', @{$header} ), " ]\n";

    my $sql
        = "INSERT INTO $table ("
        . join( ',', @{$header} )
        . ') VALUES ('
        . ( '?, ' x $#{$header} ) . '?)';

    #print "SQL: $sql\n";

    my $ok_done = 1;
    try {
        my $st = $dbh->prepare($sql);

        while ( my $row = $csv->getline($fh) ) {
            $st->execute( @{$row} );
        }

        $dbh->commit;    # commit the changes if we got this far
    }
    catch {
        warn "caught error: $_";
        $ok_done = 0;
        $dbh->rollback;    # undo the incomplete changes
    };

    print $ok_done ? "done.\n" : "failed!\n";

    return;
}

#--- Helper subs

sub get_testdb_filename {
    return catfile(File::HomeDir->my_data, 'classicmodels.db');
}

sub get_sql_filename {
	return RF('sql/classicmodels-si.sql'); 
}

sub get_data_dir {
	return RF('data'); 
}

sub data_file_list {
    my $dir = get_data_dir();

    my @files = glob("$dir/*.dat");

    return \@files;
}

sub RF {
	Cava::Packager::Resource( shift ); 
} 
