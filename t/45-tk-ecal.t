#
# Tpda3 Tk ECalendar test script
#

use 5.010;
use strict;
use warnings;

use Test::Most;
use Tk;

use lib qw( lib );

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

use Tpda3::Tk::EntryCalendar;

# Data for tests

my $mw = tkinit;

#$mw->geometry('460x80+20+20');
$mw->geometry('+20+20');

my $ecal;
my $xtvar = {};
eval {
    $ecal = $mw->EntryCalendar(
        # -year  => 2019,
        # -month => 2,
        # -bg_label_color => 'thistle4',
        # -fg_label_color => 'thistle1',
        # -bg_sel_color   => 'grey95',
        # -fg_sel_color   => 'black',
        # -bg_color       => 'gray95',
        # -fg_color       => 'green',
        # -bg_wkday_color => 'blue',
        # -fg_wkday_color => 'blue',
        # -bg_wkend_color => 'blue',
        # -fg_wkend_color => 'blue',
    )->pack;
};
ok !$@, 'create ECal';

my ( $delay, $milisec ) = ( 1, 1000 );

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $ecal->select_date( 2019, 2, 1 );
    }
);

$mw->after(
    $delay * $milisec,
    sub {
        ok my $ec = $ecal->get_entry_array, 'dump';
        my $cnt = 0;
        foreach my $ctrl ( @{$ec} ) {
            ok $ctrl->isa('Tk::Entry'), "entry $cnt";
            ok write_e($ctrl, $cnt+1), "write $cnt";
            $cnt++;
        }
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok my $ec = $ecal->get_entry_array, 'dump';
        my $cnt = 0;
        foreach my $ctrl ( @{$ec} ) {
            ok $ctrl->isa('Tk::Entry'), "entry $cnt";
            is read_e($ctrl), $cnt+1, "read $cnt";
            $cnt++;
        }
    }
);

#-- Change month

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $ecal->select_date( 2019, 9, 1 );
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok my $ec = $ecal->get_entry_array, 'dump';
        my $cnt = 0;
        foreach my $ctrl ( @{$ec} ) {
            ok $ctrl->isa('Tk::Entry'), "entry $cnt";
            ok write_e($ctrl, $cnt+1), "write $cnt";
            $cnt++;
        }
    }
);

$delay++;

$mw->after( $delay * $milisec, sub { $mw->destroy } );

sub write_e {
    my ( $control, $value ) = @_;
    $value = q{} unless defined $value;    # empty
    $control->delete( 0, 'end' );
    $control->insert( 0, $value ) if defined $value;
    return 1;
}

sub read_e {
    my ( $control ) = @_;
    return $control->get;
}

Tk::MainLoop;

done_testing();
