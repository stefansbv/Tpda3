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
# http://www.karwin.com/products/ibperl_migration.html, long time ago...
#
# TODO: replace if .. then; update POD; TEST with ALL drivers!
#
# 2010-02-20 Started refactoring. 3 args open, user and pass reading,
# diferent messages when batch processing; using scope localized vars.
#

use strict;
use warnings;
use Carp;

use Getopt::Long;
use Pod::Usage;

use Term::ReadKey;
use DBI;

# Parse options and print usage if there is a syntax error, or if
# usage was explicitly requested.
my ($help, $man);
my ($dbname, $file, $batch);

# Some (legacy) defaults
my $module = 'fb';          # Database type fb=Firebird is default
my $server = 'localhost';
my $user;
my $pass   = 'secret';      # This works for Postgresql if password not set

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
        'pass=s'   => \$pass,
        'batch'    => \$batch,
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
    if ($batch) {
        print "Database name is required\n";
    }
    else {
        pod2usage("\n$0: Database name is required\n");
    }
}

if ($file) {
    if ( ! -f $file ) {
        if ($batch) {
            print "Data file not found: $file!\n";
        }
        else {
            require "Pod/Usage.pm";
            import Pod::Usage;
            pod2usage("$0: Data file not found: $file!");
        }
    }
}
else {
    if ($batch) {
        print "Data file option required!\n";
    }
    else {
        require "Pod/Usage.pm";
        import Pod::Usage;
        pod2usage("$0: Data file required");
    }
}

if ( !$batch ) {
    print "Server    = $server\n";
    print "Database  = $dbname\n";
    print "User      = $user\n";
    print "Data file = $file\n";
}

my $dbh;
if ( $module =~ /ib|fb|firebird/i ) {

    unless ( $user or $pass ) {
        if ($batch) {
            pod2usage("\n$0: User and pass are required\n");
        }
        else {
            $user = read_username() if !$user;
            $pass = read_password() if !$pass;
        }
    }

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

    unless ( $pass ) {
        if ($batch) {
            pod2usage("\n$0: User and optional pass are required\n");
        }
        else {
            $user = read_username() if !$user;
            # $pass = read_password() if !$pass;
        }
    }

    # Postgresql
    $dbh = DBI->connect( "dbi:Pg:" . "dbname=" . $dbname . ";host=" . $server,
        $user, $pass );
}
elsif ( $module =~ /my|mysql/i ) {

    unless ( $user or $pass ) {
        if ($batch) {
            pod2usage("\n$0: User and pass are required\n");
        }
        else {
            $user = read_username() if !$user;
            $pass = read_password() if !$pass;
        }
    }

    unless ( $user && $pass ) {
        pod2usage("\n$0: User and pass are required\n") if ! $batch;
    }

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

print " Loading $file\t";
open my $file_fh, '<', $file
    or croak "Can't open file ",$file, ": $!";

my $table = <$file_fh>;
$table =~ s/[\r\n]//g;
my $line = <$file_fh>;
$line =~ s/[\r\n]//g;
my @fields = ( split( ';', $line ) );

my $sql =
    "INSERT INTO $table ("
  . join( ',', @fields )
  . ') VALUES ('
  . ( '?, ' x $#fields ) . "?)";

$dbh->{AutoCommit} = 0;    # enable transactions, if possible
$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;

eval {
    my $st = $dbh->prepare($sql);

    while ( my $line = <$file_fh> ) {
        chomp $line;

        my @data;
        foreach my $field_value ( split ';', $line ) {
            # Null fields == 'undef' in CSV data
            $field_value = undef if $field_value eq q{undef};
            push( @data, $field_value );
        }

        $st->execute(@data);
    }

    $dbh->commit;    # commit the changes if we get this far
};
if ($@) {
    # print "$@ -> $line\n";
    $dbh->rollback;    # undo the incomplete changes
}

close $file_fh;
$dbh->disconnect();
print " done.\n";

exit 0;

=head2 read_username

Read and return user name from command line

=cut

sub read_username {
    my $self = shift;

    print 'Enter your user name: ';

    my $user = ReadLine(0);
    chomp $user;

    return $user;
}

=head2 read_password

Read and return password from command line

=cut

sub read_password {
    my $self = shift;

    print 'Enter your password: ';

    ReadMode('noecho');
    my $pass = ReadLine(0);
    print "\n";
    chomp $pass;
    ReadMode('normal');

    return $pass;
}

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
