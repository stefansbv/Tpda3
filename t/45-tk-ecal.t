#
# Tpda3 Tk ECalendar test script
#

use 5.010;
use strict;
use warnings;

use Test::Most;
use Tk;

use Data::Dump;

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

plan( skip_all => 'Until fixed!' );

use Tpda3::Tk::EntryCalendar;

my $mw = tkinit;

my $ecal;
my $xtvar = {};
eval {
    $ecal = $mw->EntryCalendar(
        -year  => 2019,
        -month => 4,
    )->pack;
};
ok !$@, 'create EntryCalendar';

my ( $delay, $milisec ) = ( 1, 1000 );

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $ecal->move_first_day(+3);
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $ecal->move_first_day(-1);
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $ecal->reset_places, 'reset to initial pozition';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $ecal->hide_day(31);
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $ecal->show_day(31);
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        $ecal->clear_entry_all;
        ok my $ec = $ecal->get_label_entry_array, 'dump';
        my $cnt = 0;
        foreach my $ctrl ( @{$ec} ) {
            ok $ctrl->[1]->isa('Tk::Entry'), "entry $cnt";
            is read_e($ctrl->[1]), '', "read $cnt";
            $cnt++;
        }
    }
);

#-- Change month

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $ecal->select_month( 2019, 9 );
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok my $ec = $ecal->get_label_entry_array, 'dump';
        my $cnt = 0;
        foreach my $ctrl ( @{$ec} ) {
            ok $ctrl->[1]->isa('Tk::Entry'), "entry $cnt";
            ok write_e($ctrl->[1], $cnt+1), "write $cnt";
            $cnt++;
        }
    }
);

$mw->after(
    $delay * $milisec,
    sub {
        ok my $ec = $ecal->get_label_entry_array, 'dump';
        my $cnt = 0;
        foreach my $ctrl ( @{$ec} ) {
            ok $ctrl->[1]->isa('Tk::Entry'), "entry $cnt";
            is read_e($ctrl->[1]), $cnt+1, "read $cnt";
            $cnt++;
        }
    }
);

$delay++;

$mw->after( $delay * $milisec, sub { $mw->destroy } );

#-- helper subs

sub write_e {
    my ( $control, $value ) = @_;
    $value = q{} unless defined $value;    # empty
    $control->delete( 0, 'end' );
    $control->insert( 0, $value ) if defined $value;
    return 1;
}

sub read_e {
    my ($ctrl) = @_;
    die "Can't read $ctrl, expecting an Entry" if !$ctrl->isa('Tk::Entry');
    return $ctrl->get;
}

Tk::MainLoop();

done_testing();
