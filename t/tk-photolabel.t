#
# Tpda3 Tk Photograph test script
#
use Test::Most;
use Tk;
use Path::Tiny;

use lib qw( lib ../lib );

use Tpda3::Tk::PhotoLabel;

my ( $delay, $milisec ) = ( 1, 100 );
$milisec *= 10 if $^O eq 'MSWin32';

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }
    eval { use Tk; };
    if ($@) {
        plan( skip_all => 'Perl Tk is required for this test' );
    }
}

my $mw = tkinit;
$mw->geometry('+20+20');

my $ph;
eval {
    $ph = $mw->PhotoLabel(
        -width  => 300,
        -height => 100,
        -background => 'lightgreen',
    )->pack;
};
ok !$@, 'create PhotoLabel';

$ph->pack( -expand => 1, -fill => 'both');

$mw->after(
    $delay * $milisec,
    sub {
        my $file = path 't', 'photoframe1.data';
        my $data = $file->slurp;
        ok $ph->write_data($data), 'load image data 1';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        my $file = path 't', 'photoframe2.data';
        my $data = $file->slurp;
        ok $ph->write_data($data), 'load image data 2';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        my $file = path 't', 'photoframe1.jpg';
        ok $ph->write_image($file), 'load image file 1';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        my $file = path 't', 'photoframe2.jpg';
        ok $ph->write_image($file), 'load image file 2';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $ph->write_data(undef), 'load undef image data';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        note ref $ph;
        my $data = $ph->read_data;
        # note $data;
        $mw->destroy;
    }
);

Tk::MainLoop;

done_testing;
