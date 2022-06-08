#
# Tpda3 Tk TM test script
#

use strict;
use warnings;

use Test::Most;
use Tk;

use lib qw( lib ../lib );

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

use_ok('Tpda3::Tk::TM');

# Header for TM, slightly modified data, all cols are 'rw'

my $header = {
    colstretch    => 2,
    selectorcol   => '',
    selectorstyle => '',
    columns       => {
        orderlinenumber => {
            id          => 0,
            label       => 'Art',
            tag         => 'ro_center',
            displ_width => 5,
            valid_width => 5,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'integer',
        },
        productcode => {
            id          => 1,
            label       => 'Code',
            tag         => 'find_left',
            displ_width => 15,
            valid_width => 15,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'alphanum',
        },
        productname => {
            id          => 2,
            label       => 'Product',
            tag         => 'ro_left',
            displ_width => 36,
            valid_width => 36,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'alphanumplus',
        },
        quantityordered => {
            id          => 3,
            label       => 'Quantity',
            tag         => 'enter_right',
            displ_width => 12,
            valid_width => 12,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'numeric',
        },
        priceeach => {
            id          => 4,
            label       => 'Price',
            tag         => 'enter_right',
            displ_width => 12,
            valid_width => 12,
            numscale    => 2,
            readwrite   => 'rw',
            datatype    => 'numeric',
        },
        ordervalue => {
            id          => 5,
            label       => 'Value',
            tag         => 'ro_right',
            displ_width => 12,
            valid_width => 12,
            numscale    => 2,
            readwrite   => 'rw',
            datatype    => 'numeric',
        },
    },
};

# Data for tests

my $records = [
    {   priceeach       => '37.97',
        productcode     => 'S50_1341',
        ordervalue      => '1101.13',
        quantityordered => '29',
        productname     => '1930 Buick Marquette Phaeton',
        orderlinenumber => '1'
    },
    {   priceeach       => '81.29',
        productcode     => 'S700_1691',
        ordervalue      => '3901.92',
        quantityordered => '48',
        productname     => 'American Airlines: B767-300',
        orderlinenumber => '2'
    },
    {   priceeach       => '70.40',
        productcode     => 'S700_3167',
        ordervalue      => '2675.20',
        quantityordered => '38',
        productname     => 'F/A 18 Hornet 1/72',
        orderlinenumber => '3'
    }
];

my $mw = tkinit;
$mw->geometry('460x80+20+20');

my $tm;
my $xtvar = {};
eval {
    $tm = $mw->Scrolled(
        'TM',
        -rows          => 1,
        -cols          => 5,
        -width         => -1,
        -height        => -1,
        -ipadx         => 3,
        -titlerows     => 1,
        -validate      => 1,
        -variable      => $xtvar,
        -selectmode    => 'single',
        -resizeborders => 'none',
        -bg            => 'white',
        -scrollbars    => 'osw',
    );
};
ok !$@, 'create TM';

ok !$tm->init( $mw, $header ), 'make header';

$tm->pack( -expand => 1, -fill => 'both');

my ( $delay, $milisec ) = ( 1, 1000 );

$mw->after(
    $delay * $milisec,
    sub {
        ok $tm->fill($records), 'fill TM';
        is $tm->get_col_for('ordervalue'), 5, 'col for field';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        my ( $data, $scol ) = $tm->data_read();
        is_deeply $data, $records, 'read data from TM';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        my $cell_data = $tm->cell_read( 1, 1 );
        is_deeply
            $cell_data,
            { productcode => 'S50_1341' },
            'read cell from TM'
        ;
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        $tm->clear_all;
        my ( $data, $scol ) = $tm->data_read();
        is_deeply( $data, [], 'read data from TM after clear' );
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        $tm->add_row();
        $tm->write_row( 1, $records->[0] );
        my ( $data, $scol ) = $tm->data_read();
        is_deeply( $data->[0], $records->[0], 'read data from TM after add' );
    }
);

$delay++;
$delay++;
$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        my @names = $tm->tagNames();
        $tm->add_row_find;
    }
);

$delay++;
$delay++;
$delay++;

$mw->after( $delay * $milisec, sub { $mw->destroy } );

Tk::MainLoop;

done_testing;
