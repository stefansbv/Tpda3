# Exemplu de BLOB

use 5.010;
use strict;
use warnings;

use DBI;
use Carp;
use MIME::Base64;

my ($db, $tr, $st, $status, @result, $sql);

print "Connect... ";

# Connect to database
my $host = 'localhost';
my $port = 5432;
my $dbname = 'loto_dev';
my $user   = 'stefan';
my $pass   = 'tba790k';

print "\n";
print " Server    = $host\n";
print " Database  = $dbname\n";
print " User      = $user\n";

my $dsn = qq{dbi:Pg:dbname=$dbname;host=$host;port=$port};

my $dbh = DBI->connect(
    $dsn, $user, $pass,
    {   FetchHashKeyName => 'NAME_lc',
        AutoCommit       => 1,
        RaiseError       => 1,
        PrintError       => 0,
        LongReadLen      => 524288,
        pg_enable_utf8   => 1,
    }
);

$dbh->{RaiseError} => 1 ;
$dbh->{LongReadLen} = 512 * 1024;

# Prepare the image
my $img_file  = 'earth.jpg';
open my $img_fh, '<', $img_file
    or die "Can't open file ", $img_file, ": $!";
binmode $img_fh;

my ($infile, $buffer);
while ( my $bytes = read( $img_fh, $buffer, 1024 ) ) {
    $infile .= $buffer;
}
close $img_fh;

my $stream = encode_base64($infile);
# print $stream;

# Insert
my $sql = "UPDATE sl.angajati SET foto = ? WHERE marca = ?";
print "sql=", $sql, "\n";

my $sth = $dbh->prepare($sql)
    or die "Can't prepare statement: $DBI::errstr";
my $rc = $sth->execute($stream, 1330)
    or die "Can't execute statement: $DBI::errstr";

$dbh->disconnect;

print "Done!\n";

exit 0;
