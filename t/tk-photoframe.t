#
# Tpda3 Tk Photograph test script
#
use Test::Most;
use Tk;
use Path::Tiny;

use lib qw( lib ../lib );

use Tpda3::Tk::PhotoFrame;

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

my $bunny =
'iVBORw0KGgoAAAANSUhEUgAAAB4AAAAjEAIAAABcJvHFAAAACXBIWXMAAAsSAAALEgHS3X78AAAD
F0lEQVR42u1YL+yqUBj1vfcLbhY3C44is8BIREYSG9FoNBqNkok2aFhp2BhJDWyadCZN/ilOGxan
jRdOuRsPxl/f+23vJKfX7x6+73znu5dK5RviV9QPDMMwDIPP7/f7/X6XTWU0Go1Go06n0+l0PM/z
PC91CNu2bduWZVmW5bLpjsfj8XgcBEEQBJPJZDKZZAw0n8/n8zkCGYZhGIYgCIIgFEt3OBwOh8OA
gKZpmqZlDDedTqfTKRnO933f95GVer1er9fz0BVFURRFxCR3QfyMQfv9fr/fDyLgOI7jONmo419k
JUkMBoPBYJCRNBrxdrvdbrco6qvVarVaIWdFpQO/5tIcFBbE4nQ6nU6nJIpHjlGlEklTFEVRFDIa
T32/3+/3+3jqHMdxHBcfB2sK6HFFURRFeb1er9crfksoNUrr0GvUfxGfnA+FmX+QALDItGLDA6O2
pQyCJFkPqxMDK2p9LodOAhQaLRjfoKRGo2wObl3G8PoDsA0Gb5Q5oonjfSNKTh96AOh+u91ut1uS
FuZrONPJ7bJ06tA9TDDsD6QkCnDltEDRkV1Q9AnENyuk8hcyChkkcZKo5uv1er1er3S6cAPkFXSx
MQodPrXFg2zTEsVANhO2JNdEmVo80ub7K/lSDHPyLkNaXrVarVar2W46LMuyLFsKaZ7neZ4nvwFR
NGKeGjYajUajkXz9z+RLn8/n8/ms/ANIQXq5XC6Xy/v9fr/fvw3p9Xq9Xq9VVVVV9fF4PB6Pokhc
r9fr9Vr6s6Lf4dNpbS6/exQA3BHDt/fkPl3wwT85wlcEcrCHZyHO1tmOSl95iGLcQN80TdM0jTa1
LMuyLF3XdV03TdM0zWaz2Ww2Xdd1XRenDlDHgTbtvj/ykMZpDm/6LpfL5XLBmGi32+12G6Th5RAA
Pne73W63iwfGYFosFovF4kOZrtVqtVoN16TD4XA4HPAAKDp5yZUkSZIk1GGz2Ww2m91ut9vt0Mof
lcfxeDwej7PZbDaboRFbrVar1SJfIsLdYZfn8/l8Pue3y1zyiH9VAMFElb5Yp/+PcvAbH/25ox5S
PYYAAAAASUVORK5CYII=';

my $mw = tkinit;
$mw->geometry('320x320+20+20');

my $ph;
eval {
    $ph = $mw->PhotoFrame;
};
ok !$@, 'create PhotoFrame';

$ph->pack( -expand => 1, -fill => 'both');

my ( $delay, $milisec ) = ( 1, 1000 );

$mw->after(
    $delay * $milisec,
    sub {
        my $file = path 't', 'photoframe1.data';
        my $data = $file->slurp;
        ok $ph->load_data($data), 'load image data 1';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        my $file = path 't', 'photoframe2.data';
        my $data = $file->slurp;
        ok $ph->load_data($data), 'load image data 2';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        my $file = path 't', 'photoframe1.jpg';
        ok $ph->load_image($file), 'load image file 1';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        my $file = path 't', 'photoframe2.jpg';
        ok $ph->load_image($file), 'load image file 2';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        note "close";
        $mw->destroy;
    }
);

Tk::MainLoop;

done_testing;
