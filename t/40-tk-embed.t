#
# Tpda3 Tk TM embeded windows test script
#

use 5.010;
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

use Tpda3::Tk::TM;

# Header for TM, slightly modified data, all cols are 'rw'

my $header = {
    colstretch    => '',
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
            displ_width => 40,
            valid_width => 20,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'alphanumplus',
        },
    },
};

my $choices = [
    { -name => 'one',   -value => 1 },
    { -name => 'two',   -value => 2 },
    { -name => 'three', -value => 3 },
];

# Data for tests

my $records = [
    {
        id_doc  => 1,
        tip_doc => 3,
        den_doc => '1930 Buick Marquette Phaeton',
    },
    {
        id_doc  => 2,
        tip_doc => 2,
        den_doc => 'American Airlines: B767-300',
    },
    {
        id_doc  => 3,
        tip_doc => 1,
        den_doc => 'F/A 18 Hornet 1/72',
    },
];

my $mw = tkinit;
#$mw->geometry('460x80+20+20');
$mw->geometry('+20+20');

my $tm;
my $xtvar = {};
eval {
    $tm = $mw->Scrolled(
        'TM',
        -rows          => 5,
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
ok !$@, 'create TM';

is $tm->is_col_name('tip_doc'), 1, 'is col name';
is $tm->is_col_name(3), '', 'is col name';

$header->{tip_doc} = $choices;           # add the choices to the args
    
ok !$tm->init( $mw, $header ), 'make header';

is $tm->cell_config_for( 'tip_doc', 'embed' ), 'jcombobox',
  'cell_config_for tip_doc';    # call after init!

is $tm->cell_config_for( 1, 'embed' ), 'jcombobox',
  'cell_config_for 1';    # call after init!

$tm->pack( -expand => 1, -fill => 'both' );

my ( $delay, $milisec ) = ( 1, 1000 );

$mw->after(
    $delay * $milisec,
    sub {
        ok $tm->fill($records), 'fill TM';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        my ( $data, $scol ) = $tm->data_read('selected');
        cmp_deeply $data, $records, 'read data from TM';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        my $cell_data = $tm->cell_read( 1, 2 );
        cmp_deeply(
            $cell_data,
            { den_doc => '1930 Buick Marquette Phaeton' },
            'read cell from TM'
        );
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        $tm->clear_all;
        my ( $data, $scol ) = $tm->data_read();
        cmp_deeply( $data, [], 'read data from TM after clear' );
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        $tm->add_row;
        my ( $r, $i ) = ( 1, 0 );
        $tm->write_row( $r, $records->[$i] );
        my ( $data, $scol ) = $tm->data_read();
        cmp_deeply( $data->[$i], $records->[$i], 'read data from TM after add' );
        cmp_deeply $tm->read_row($r), $records->[$i], "data for row $r";
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        $tm->add_row;
        my ( $r, $i ) = ( 2, 1 );
        $tm->write_row( $r, $records->[$i] );
        my ( $data, $scol ) = $tm->data_read();
        cmp_deeply( $data->[$i], $records->[$i], 'read data from TM after add' );
        cmp_deeply $tm->read_row($r), $records->[$i], "data for row $r";
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        $tm->add_row;
        my ( $r, $i ) = ( 3, 2 );
        $tm->write_row( $r, $records->[$i] );
        my ( $data, $scol ) = $tm->data_read('selected');
        say "scol = $scol";
        cmp_deeply( $data->[$i], $records->[$i],
            'read data from TM after add' );
        cmp_deeply $tm->read_row($r), $records->[$i], "data for row $r";

        my $r_data = $tm->read_row($r);
        
        is $tm->has_embeded_widget('tip_doc'), 1,
            'tip_doc has emebeded widget';
        is $tm->has_embeded_widget('den_doc'), '',
            'den_doc has no emebeded widget';
        is $tm->count_is_checked(3), 1, 'count is_checked';
    }
);

$delay++;

$mw->after( $delay * $milisec, sub { $mw->destroy } );

Tk::MainLoop;

done_testing();
