#!/usr/bin/perl
#
# Import.pl - read a symbol-separated ASCII file of data
#   and insert it into an InterBase database very very quickly
#   using DBD::InterBase.
#
#   The input file must be in the form:
#     TABLENAME
#     FIELD1;FIELD2;FIELD3;...
#     VALUE1;VALUE2;VALUE3;...
#     VALUE1;VALUE2;VALUE3;...
#     ...
# The table must exist
# Null atributes must contain 'undef'
#
# Copyright 2000 Bill Karwin
#
# Converted from IBPerl to DBD::InterBase by Stefan Suciu,
# based on article 'IBPerl Migration' by Bill Karwin
# http://www.karwin.com/products/ibperl_migration.html

use strict;
use warnings;
use DBI;
use Carp;

use Getopt::Long;
use Pod::Usage;

# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
my $help   = '';
my $man    = '';
my $module = 'fb';          # Database type fb=Firebird is default
my $server = 'localhost';
my $dbname;
my $file;
my $user = 'SYSDBA';        # Default user ;)
my $pass = 'secret';        # This works for Postgresql if password not set

# Process options.
if ( @ARGV > 0 ) {
    require "Pod/Usage.pm";
    import Pod::Usage;
    GetOptions(
        'help|?'   => \$help,
        'man'      => \$man,
        'server=s' => \$server,
        'module=s' => \$module,
        'dbname=s' => \$dbname,
        'file=s'   => \$file,
        'user=s'   => \$user,
        'pass=s'   => \$pass
      ),
      or pod2usage(2);
}
if ( $man or $help or $#ARGV >= 0 ) {

    # Load Pod::Usage only if needed.
    require "Pod/Usage.pm";
    import Pod::Usage;
    pod2usage(1) if $help;
    pod2usage( VERBOSE => 2 ) if $man;
    if ( $#ARGV >= 0 ) {
        Pod::Usage::pod2usage("$0: Too many arguments");
    }
}

unless ($dbname) {
    pod2usage("\n$0: Database name is required\n");
}

if ($file) {
    unless ( -f $file ) {
        require "Pod/Usage.pm";
        import Pod::Usage;
        pod2usage("$0: Data file not found: $file!");
    }
}
else {
    require "Pod/Usage.pm";
    import Pod::Usage;
    pod2usage("$0: Data file required");
}

if ( $module eq 'pg' ) {
    unless ($user) {
        pod2usage("\n$0: User is required\n");
    }
}
else {
    unless ( $user && $pass ) {
        pod2usage("\n$0: User and pass are required\n");
    }
}

print "Server    = $server\n";
print "Database  = $dbname\n";
print "User      = $user\n";
print "Data file = $file\n";

my ( $dbh, $tr, $st );
my ( $line, $table, @fields, $sql );

print "Connect";

if ( $module =~ /ib|fb|firebird/i ) {

    # Interbase / Firebird
    $dbh = DBI->connect(
        "dbi:InterBase:"
          . "dbname="
          . $dbname
          . ";host="
          . $server
          . ";ib_dialect=3",
        $user, $pass
    );
}
elsif ( $module =~ /pg|pgsql|postgresql/i ) {

    # Postgresql
    $dbh = DBI->connect( "dbi:Pg:" . "dbname=" . $dbname . ";host=" . $server,
        $user, $pass );
}
elsif ( $module =~ /my|mysql/i ) {

    # MySQL
    $dbh =
      DBI->connect( "dbi:mysql:" . "database=" . $dbname . ";host=" . $server,
        $user, $pass );
}
elsif ( $module =~ /si|sqlite/i ) {

    # SQLite
    $dbh = DBI->connect( "dbi:SQLite:$dbname", q{}, q{} );
}
else {
    print "db = $module?\n";
    exit;
}

$dbh->{RaiseError}         = 1;
$dbh->{PrintError}         = 1;
$dbh->{ShowErrorStatement} = 0;

print "ed\n";

open( INFIS, "$file" )
  or die "Could not open file: $file:$!\n";

$table = <INFIS>;
$table =~ s/[\r\n]//g;
$line = <INFIS>;
$line =~ s/[\r\n]//g;
@fields = ( split( ';', $line ) );

$sql =
    "INSERT INTO $table ("
  . join( ',', @fields )
  . ') VALUES ('
  . ( '?, ' x $#fields ) . "?)";

my ( $linie, @linie, $camp, @data_lin );

$dbh->{AutoCommit} = 0;    # enable transactions, if possible
$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;

eval {

    # do lots of work here including inserts and updates
    $st = $dbh->prepare($sql);

    while ( $linie = <INFIS> ) {
        chomp $linie;
        @linie = split( ';', $linie );

        foreach $camp (@linie) {
            if ( $camp eq "undef" ) {
                $camp = undef;
            }
            push( @data_lin, $camp );
        }    # end foreach

        my $aref = \@data_lin;

        $st->execute( @{$aref} );

        # Initializare
        @data_lin = ();
    }

    $dbh->commit;    # commit the changes if we get this far
};
if ($@) {
    print "$@ -> $linie\n";
    $dbh->rollback;    # undo the incomplete changes
}

close(INFIS);
$dbh->disconnect();
print "Done!\n";

exit 0;

__END__


=head1 NAME

Perl script for quick import of data into tables

=head1 SYNOPSIS

import-dbi.pl [help|-man]
            | [-dbname <name> -file <file> -pass <pwd>]

 Options:
   -help            Brief help message
   -man             Full documentation

   -server          Server name; default: localhost
   -module          Server type; default: ib
   -dbname          Database name (or path for Firebird or Interbase)
   -file            Data file
   -user            User name;   default: SYSDBA
   -pass            Password

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

Import csv file with semicolon delimiter into a database table.

The input file must be in the form:

    TABLENAME
    FIELD1;FIELD2;FIELD3;...
    VALUE1;VALUE2;VALUE3;...
    VALUE1;VALUE2;VALUE3;...

The module options are:
    ib | fb | firebird      for Interbase or Firebird
    pg | pgsql | postgresql for Postgresql
    my | mysql              for MySQL
    si | sqlite             for SQLite

=cut
