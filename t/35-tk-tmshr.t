#
# Tpda3 Tk TMSHR test script
#
# Bug?:
# t/35-tk-tmshr.t ...... 1/6 Use of uninitialized value in numeric ne (!=)
# at blib/lib/Tk/Frame.pm (autosplit into
# blib/lib/auto/Tk/Frame/sbset.al) line 212,
# from 'make test' but not from 'prove' :(

use strict;
use warnings;

use Test::More;
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

    plan tests => 7;
}

use_ok('Tpda3::Tk::TMSHR');

# Header for TMSHR, slightly modified data, all cols are 'ro'

my $header = {
    colstretch => undef,
    rowcount   => 'nr_crt',
    columns    => {
        nr_crt => {
            id          => 1,
            numscale    => 0,
            displ_width => 3,
            valid_width => 3,
            datatype    => 'integer',
            order       => 'N',
            label       => '#',
            tag         => 'ro_center',
            readwrite   => 'ro',
            datasource  => '=count',
        },
        productline => {
            id          => 2,
            numscale    => 0,
            displ_width => 15,
            valid_width => 15,
            datatype    => 'alphanumplus',
            order       => 'A',
            label       => 'Line',
            tag         => 'ro_left',
            readwrite   => 'ro',
            datasource  => {
                level0 => 'tablename',
                level1 => undef,
            },
        },
        productname => {
            id          => 3,
            numscale    => 0,
            displ_width => 30,
            valid_width => 30,
            datatype    => 'alphanumplus',
            order       => 'A',
            label       => 'Product',
            tag         => 'ro_left',
            readwrite   => 'ro',
            datasource  => 'firme',
            datasource  => {
                level0 => undef,
                level1 => 'tablename'
            },
        },
        quantityordered => {
            id          => 4,
            numscale    => 0,
            displ_width => 8,
            valid_width => 8,
            datatype    => 'numeric',
            order       => 'N',
            label       => 'Quantity',
            tag         => 'enter_right',
            readwrite   => 'ro',
            datasource  => {
                level0 => undef,
                level1 => 'tablename'
            },
        },
        priceeach => {
            id          => 5,
            numscale    => 2,
            displ_width => 8,
            valid_width => 8,
            datatype    => 'numeric',
            order       => 'N',
            label       => 'Price',
            tag         => 'enter_right',
            readwrite   => 'ro',
            datasource  => {
                level0 => undef,
                level1 => 'tablename'
            },
        },
        ordervalue => {
            id         => 6,
            numscale   => 2,
            width      => 8,
            datatype   => 'numeric',
            order      => 'A',
            label      => 'Value',
            tag        => 'ro_right',
            readwrite  => 'ro',
            datasource => '=quantityordered*priceeach',
        },
    },
};

# Data for tests - main data

my $record = [
    {   nr_crt          => 1,
        productline     => 'Vintage Cars',
        productname     => '',
        quantityordered => '0',
        priceeach       => '0.00',
        ordervalue      => '0.00',
    },
    {   nr_crt          => 2,
        productline     => 'Planes',
        productname     => '',
        quantityordered => '0',
        priceeach       => '0.00',
        ordervalue      => '0.00',
    },
];

my $expdata = {
    '1' => {
        'data' => [
            [   '', '', '', '1930 Buick Marquette Phaeton',
                '29', '37.97',
            ],
            [   '', '', '', 'American Airlines: B767-300',
                '48', '81.29',
            ],
            [ '', '', '', 'F/A 18 Hornet 1/72', '38', '70.40', ]
        ],
        'tag' => 'detail',
    }
};

my $mw = tkinit;
$mw->geometry('+20+20');

my $tm;
my ( $xtvar, $expand_data ) = ( {}, {} );
eval {
    $tm = $mw->Scrolled(
        'TMSHR',
        -rows           => 5,
        -cols           => 1,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -variable       => $xtvar,
        -selectmode     => 'single',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -bg             => 'white',
        -scrollbars     => 'osw',
        -expandData     => $expand_data,
    );
};
ok(!$@, 'create TMSHR');

is( $tm->make_header($header), undef, 'make header' );

$tm->pack( -expand => 1, -fill => 'both');

my $delay = 1;

$mw->after( $delay * 100,
    sub { is( $tm->fill_main($record, 'nr_crt'), undef, 'fill TMSHR' ); } );

$delay++;

$mw->after(
    $delay * 100,
    sub {
        is( $tm->fill_details($expdata), undef, 'fill TMSHR det 1' );
    }
);

$delay++;

$mw->after(
    $delay * 100,
    sub {
        is_deeply($tm->get_main_data(), $record, 'compare main data');
        is_deeply($tm->get_expdata(), $expdata, 'compare expand data');
    }
);

$delay++;

$mw->after( $delay * 100, sub { $mw->destroy } );

Tk::MainLoop;

#-- End test
