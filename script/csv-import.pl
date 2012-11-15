#! perl
#
# Import CSV files into databases, using the Text::CSV_XS module.
#
# Copyleft 2011-2012 Ștefan Suciu
#

use strict;
use warnings;
use Carp;

use DBI;
use Text::CSV_XS;
use Try::Tiny;
use Term::ReadKey;

use Getopt::Long;
use Pod::Usage;

# Parse options and print usage if there is a syntax error, or if
# usage was explicitly requested.
my ($help, $man);
my ($dbname, $file, $batch);
my ($module, $user, $pass, $port);
my $server = 'localhost';

# Process options.
if ( @ARGV > 0 ) {
    require "Pod/Usage.pm";
    import Pod::Usage;
    GetOptions(
        'help|?'   => \$help,
        'man'      => \$man,
        'server=s' => \$server,
        'port=s'   => \$port,
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
        print "The database name is required\n";
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
    print "Module    = $module\n";
    print "Data file = $file\n";
}

my $dbh;
if ( $module =~ /fb|firebird/i ) {

    # Firebird
    $port ||= '3050';

    unless ( $user or $pass ) {
        if ($batch) {
            pod2usage("\n$0: User and pass are required\n");
        }
        else {
            $user = read_username() if !$user;
            $pass = read_password() if !$pass;
        }
    }

    try {
        $dbh = DBI->connect(
              "dbi:Firebird:"
            . "dbname=$dbname"
            . ";ib_dialect=3"
            . ";host=$server"
            . ";port=$port"
            , $user
            , $pass
            , { RaiseError => 1, FetchHashKeyName => 'NAME_lc' }
        );
    }
    catch {
        croak "caught error: $_";
    };
}
elsif ( $module =~ /pg|pgsql|postgresql/i ) {

    # PostgreSQL
    $port ||= '5432';

    unless ( $user or $pass ) {
        if ($batch) {
            pod2usage("\n$0: User and pass are required\n");
        }
        else {
            $user = read_username() if !$user;
            $pass = read_password() if !$pass;
        }
    }

    try {
        $dbh = DBI->connect(
              "dbi:Pg:"
            . "dbname=$dbname"
            . ";host=$server"
            . ";port=$port"
            , $user
            , $pass
            , { RaiseError => 1, FetchHashKeyName => 'NAME_lc' }
        );
        $dbh->{pg_enable_utf8} = 1;
    }
    catch {
        croak "caught error: $_";
    };

}
elsif ( $module =~ /my|mysql/i ) {

    # MySQL
    $port ||= '3306';

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

    try {
        $dbh = DBI->connect(
              "dbi:mysql:"
            . "database=$dbname"
            . ";host=$server"
            . ";port=$port"
            , $user
            , $pass
            , { RaiseError => 1, FetchHashKeyName => 'NAME_lc' }
        );
    }
    catch {
        croak "caught error: $_";
    };
}
elsif ( $module =~ /si|sqlite/i ) {

    # SQLite
    try {
        $dbh = DBI->connect( "dbi:SQLite:$dbname", q{}, q{} );
    }
    catch {
        croak "caught error: $_";
    };

}
else {
    print "db = $module?\n";
    exit;
}

$dbh->{RaiseError}         = 1;
$dbh->{PrintError}         = 1;
$dbh->{ShowErrorStatement} = 0;

print "Loading $file ";

my @rows;

my $csv = Text::CSV_XS->new(
    {
        sep_char       => ';',
        always_quote   => 0,
        binary         => 1,
        blank_is_undef => 1,
    }
) or die "Cannot use CSV: " . Text::CSV->error_diag();

open my $fh, "<:encoding(utf8)", $file
    or die "Error: $!";

my $table = $csv->getline($fh)->[0];
# print "Table is $table\n";

my $header = $csv->getline($fh);
# print "Header is [ ", join( ', ', @{$header} ), " ]\n";

my $sql =
    "INSERT INTO $table ("
  . join( ',', @{$header} )
  . ') VALUES ('
  . ( '?, ' x $#{$header} ) . '?)';

# print "SQL: $sql\n";

$dbh->{AutoCommit} = 0;    # enable transactions, if possible
$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;

my $ok_done = 1;
try {
    my $st = $dbh->prepare($sql);

    while (my $row = $csv->getline ($fh)) {
        $st->execute(@{$row});
    }

    $dbh->commit;              # commit the changes if we got this far
}
catch {
    warn "caught error: $_";
    $ok_done = 0;
    $dbh->rollback;                      # undo the incomplete changes
};

$dbh->disconnect();

print $ok_done ? "done.\n" : "failed!\n";

exit 0;

#--

sub read_username {
    my $self = shift;

    print ' Enter your username: ';

    my $user = ReadLine(0);
    chomp $user;

    return $user;
}

sub read_password {
    my $self = shift;

    print ' Enter your password: ';

    ReadMode('noecho');
    my $pass = ReadLine(0);
    print "\n";
    chomp $pass;
    ReadMode('normal');

    return $pass;
}

__END__

=head1 NAME

csv-import.pl - Import records from database tables from custom CSV files.

=head1 USAGE

csv-import.pl [-help | -man]

csv-import.pl -module <module> -dbname <dbname> -file <file>

=head1 OPTIONS

=over

=item B<module> Database driver name

The module options are:
    fb | firebird           for Firebird
    pg | pgsql | postgresql for Postgresql
    my | mysql              for MySQL
    si | sqlite             for SQLite

=item B<server>

Server name, default is I<localhost>.

=item B<dbname>

Database name or path for Firebird.

=item B<file>

Output file name, defaults to C<< <dbname>-<table>.dat >>.

=item B<user>

User name, if required by the module and not supplied, prompt for it.

=item B<pass>

Password,  if required by the module and not supplied, prompt for it.

=item B<batch>

Batch mode, suppresses prompting and help messages.

=back

=head1 DESCRIPTION

Import custom CSV files into databases, using the Text::CSV_XS module.

The first row of the file is the table name.  Fields are separated by
semicolon.  The Text::CSV_XS attribute blank_is_undef is set to true,
so two consecutive field separators are read as undef value, and
inserted as NULL into the database table.

The input file must be in the form:

    TABLENAME
    field1;field2;field3;...
    value1;value2;value3;...
    value1;value2;value3;...

The module options are:
    fb | firebird           for Firebird
    pg | pgsql | postgresql for Postgresql
    my | mysql              for MySQL
    si | sqlite             for SQLite

=head1 ACKNOWLEDGEMENTS

Inspired by 'Import.pl' Copyright 2000 Bill Karwin.

Converted from IBPerl to DBD::InterBase by Stefan Suciu, based on
article 'IBPerl Migration' by Bill Karwin
http://www.karwin.com/products/ibperl_migration.html, long time ago...

=cut
