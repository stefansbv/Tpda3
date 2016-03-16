# Extrage imagine din BLOB

use strict;
use DBI;
use Carp;
use MIME::Base64;
use Tk;
use Tk::Pane;
# use Tk::Photo;
use Tk::JPEG;
use Cwd;

my ($db, $tr, $st, $status, @result, $sql);

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

my $sql = qq{
SELECT foto
    FROM sl.angajati
    WHERE marca = 1330; 
};
my $sth = $dbh->prepare($sql) or die "Can't prepare statement: $DBI::errstr";
my $rc = $sth->execute or die "Can't execute statement: $DBI::errstr";

my $stream = {};
my $indice = 1;

while (@result = $sth->fetchrow_array()) {
  $stream->{$indice} = $result[0];
  $indice++;
}

$sth->finish();
$dbh->disconnect();

# Afiseaza

my $photo; # Photo label

my $mw = MainWindow->new( -bg => 'pink' );
$mw->geometry('700x560');

# Default empty image
my $image = $mw->Photo(
    -format => 'jpeg',
    -width  => 640,
    -height => 480,
    -data   => ''
);

my $topframe = $mw->Frame(
    -height     => 10,
    -background => 'white'
)->pack(
    -side   => "top",
    -anchor => "n",
    -fill   => 'x',
    -expand => 0
);

my $info = 'File Information';
$mw->fontCreate(
    'big',
    -family => 'arial',
    -weight => 'bold',
    -size   => int( -18 * 18 / 14 )
);

$topframe->Label(
    -textvariable => \$info,
    -background   => 'black',
    -foreground   => 'yellow',
    -font         => 'big',
    -padx         => 40,
    -relief       => 'raised',
)->pack( -fill => 'x', -expand => 1 );

my $mainframe = $mw->Frame( -background => 'black' )->pack(
    -side   => "top",
    -anchor => "n",
    -fill   => 'both',
    -expand => 1
);

my $pane = $mainframe->Scrolled(
    'Pane',
    Name        => 'Main Display',
    -background => 'black',
    -scrollbars => 'osoe',
    -sticky     => 'n',
)->pack(
    -side   => "top",
    -anchor => "n",
    -fill   => 'both',
    -expand => 1
);

$photo = $pane->Label( -image => $image )->pack(
    -side   => 'top',
    -anchor => 'n',
    -fill   => 'both',
    -expand => 1,
);

my $bottomframe = $mw->Frame(
    -height     => 10,
    -background => 'white'
)->pack(
    -side   => "bottom",
    -anchor => "s",
    -fill   => 'x',
    -expand => 0
);

# Create Button bar
my $buttonBar = $bottomframe->Frame( -borderwidth => 4 )->pack( -fill => 'y' );

my $primaB = $buttonBar->Button(
    -text    => "Prima",
    -width   => 10,
    -command => sub { load_image(1); }
);

my $ultimaB = $buttonBar->Button(
    -text    => "Ultima",
    -width   => 10,
    -command => sub { load_image(2); }
);

my $exportB = $buttonBar->Button(
    -text    => "Export",
    -width   => 10,
    -command => \&export_foto
);

my $exitB = $buttonBar->Button(
    -text    => "Exit",
    -width   => 10,
    -command => sub { destroy $mw}
);

foreach ( $primaB, $ultimaB, $exportB, $exitB ) {
    $_->pack(
        -side => 'left',
        -padx => 2
    );
}

$mw->waitVisibility;

MainLoop;

sub export_foto {

    my $jpegfile = $pane->getSaveFile(
        -defaultextension => ".jpg",
        -filetypes        => [ [ 'JPEG File', '.jpg' ] ],
        -initialdir       => Cwd::cwd(),
        -initialfile      => "temp.jpg",
        -title            => "Salveaza Foto",
    );

    # Write image file to disk
    if ($jpegfile) {
        $image->write($jpegfile);
    }
    else {
        print "Export abandonat.\n";
    }
}

sub load_image {
  my $indice = shift;
  $image->blank;
  $image->configure(-format => 'jpeg', -data => $stream->{$indice} );
}
