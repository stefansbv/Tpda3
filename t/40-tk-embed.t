#
# Tpda3 Tk TM embeded windows test script
#

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

    plan tests => 8;
}

use_ok('Tpda3::Tk::TM');

# Header for TM, slightly modified data, all cols are 'rw'

my $header = {
    colstretch    => 2,
    selectorcol   => 3,
    selectorstyle => '',
    columns       => {
        id_doc => {
            id          => 0,
            label       => 'Id',
            tag         => 'ro_center',
            displ_width => 5,
            valid_width => 5,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'alphanum',
        },
        tip_doc => {
            id          => 1,
            label       => 'Tip',
            tag         => 'enter_left',
            displ_width => 20,
            valid_width => 20,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'alphanumplus',
            embed       => 'jcombobox',
        },
        den_doc => {
            id          => 2,
            label       => 'Denum',
            tag         => 'enter_left',
            displ_width => 60,
            valid_width => 60,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'alphanumplus',
        },
    },
};

# Data for tests

my $record = [
    {
        id_doc  => 1,
        tip_doc => '',
        den_doc => '1930 Buick Marquette Phaeton',
    },
    {
        id_doc  => 2,
        tip_doc => '',
        den_doc => 'American Airlines: B767-300',
    },
    {
        id_doc  => 3,
        tip_doc => '',
        den_doc => 'F/A 18 Hornet 1/72',
    },
];

my $mw = tkinit;
$mw->geometry('300x100+20+20');

my $tm;
my $xtvar = {};
eval {
    $tm = $mw->Scrolled(
        'TM',
        -rows          => 1,
        -cols          => 3,
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
ok(!$@, 'create TM');

is( $tm->init( $mw, $header ), undef, 'make header' );

$tm->pack( -expand => 1, -fill => 'both');

my $delay = 1;

$mw->after( $delay * 1000,
            sub {
                is( $tm->fill($record), undef, 'fill TM' );
                $tm->tmatrix_make_embeded;
            } );

$delay++;

$mw->after(
    $delay * 1000,
    sub {
        my ( $data, $scol ) = $tm->data_read();
        is_deeply( $data, $record, 'read data from TM' );
    }
);

$delay++;

$mw->after(
    $delay * 1000,
    sub {
        my $cell_data = $tm->cell_read( 1, 1 );
        is_deeply(
            $cell_data,
            { productcode => 'S50_1341' },
            'read cell from TM'
        );
    }
);

$delay++;

$mw->after(
    $delay * 1000,
    sub {
        $tm->clear_all;
        my ( $data, $scol ) = $tm->data_read();
        is_deeply( $data, [], 'read data from TM after clear' );
    }
);

$delay++;

$mw->after(
    $delay * 1000,
    sub {
        $tm->add_row();
        $tm->write_row( 1, 0, $record->[0] );
        my ( $data, $scol ) = $tm->data_read();
        is_deeply( $data, [ $record->[0] ], 'read data from TM after add' );
    }
);

$delay++;

$mw->after(
    $delay * 1000,
    sub {
        $tm->add_row();
        $tm->write_row( 2, 0, $record->[1] );
        my ( $data, $scol ) = $tm->data_read();
        is_deeply( $data, [ $record->[1] ], 'read data from TM after add' );
    }
);

$delay++;

$mw->after(
    $delay * 1000,
    sub {
        $tm->add_row();
        $tm->write_row( 3, 0, $record->[2] );
        my ( $data, $scol ) = $tm->data_read();
        is_deeply( $data, [ $record->[2] ], 'read data from TM after add' );
    }
);

$delay++;

$mw->after( $delay * 1000, sub { $mw->destroy } );

Tk::MainLoop;

#-- End test
