# cal.pl

use 5.010;
use utf8;
use strict;
use warnings;
use Data::Dump;

use Tk; # Tk::place
my $mw = MainWindow->new;

my $ux = 1 / 7;
my $uy = 1 / 6;

my $first_on = 1;                            # first day on col

my $header = $mw->Frame(
    -width       => 482,
    -height      => 30,
    -borderwidth => '3',
    -relief      => 'raised',
    -background => 'grey60',
);
$header->pack(qw/-side top -padx 1c -pady 5/);

my $top = $mw->Frame(
    -width       => 480,
    -height      => 320,
    -borderwidth => '2',
    -relief      => 'sunken',
    -background => 'grey60',
);
$top->pack(qw/-side top -padx 1c -pady 5/);

my $bot = $mw->Frame(
    -width       => 120,
    -height      => 40,
    -borderwidth => '2',
    -relief      => 'sunken',
    -background  => 'green',
);
$bot->pack(qw/-side top -padx 1c -pady 1c/);

#-- header

my $day_arr = [qw(luni marți miercuri joi vineri sâmbătă duminică)];

foreach my $x ( 0 .. 6 ) {
    make_label( $header, $x, 0, $day_arr->[$x] );
}

my ($ctrl, $rx, $ry, $e_ctrl);
my (@ctrls, @coords, @ectrls);

my $days  = 1;
my $count = 1;
foreach my $y ( 0 .. 5 ) {
    foreach my $x ( 0 .. 6 ) {
        if ( $days > 31 ) {
            ($ctrl, $rx, $ry) = make_space( $x, $y );
        }
        else {
            ($ctrl, $rx, $ry, $e_ctrl) = make_frame( $x, $y, $days );
            push @ectrls, $e_ctrl;
            $days++;
        }
        push @ctrls, $ctrl;
        push @coords, [$rx, $ry];
    }
}

sub make_frame {
    my ( $x, $y, $d ) = @_;
    my $rx  = $ux * $x;
    my $ry  = $uy * $y;
    my $frm = $top->Frame(
        -borderwidth => 2,
        -relief      => 'ridge',
    )->place(
        -relx      => $rx,
        -rely      => $ry,
        -relwidth  => $ux,
        -relheight => $uy,
    );
    my $e_ctrl = make_label_entry($frm, $d);
    return ( $frm, $rx, $ry, $e_ctrl );
}

sub make_label_entry {
    my ($mf, $day)= @_;
    my $ft = $mf->Frame()->pack;
    $ft->Label(
        -text       => $day,
        -width      => 4,
        # -background => $w->{bg},
    )->pack;
    my $efb = $mf->Frame()->pack;
    return $efb->Entry(
        -width   => 3,
        -relief  => 'flat',
        -justify => 'center',
    )->pack(
        -padx => 5,
        -pady => 3,
    );
}

sub make_button {
    my ( $x, $y, $d ) = @_;
    my $rx  = $ux * $x;
    my $ry  = $uy * $y;
    my $btn = $top->Button(
        -text               => $d,
        -relief             => 'raised',
        -highlightthickness => 0,
    )->place(
        -relx      => $rx,
        -rely      => $ry,
        -relwidth  => $ux,
        -relheight => $uy,
    );
    return ( $btn, $rx, $ry );
}

sub make_label {
    my ( $frm, $x, $y, $g ) = @_;
    my $rx  = $ux * $x;
    my $ry  = $uy * $y;
    my $lbl = $frm->Label(
        -text               => $g,
        -relief             => 'ridge',
        -highlightthickness => 0,
    )->place(
        -relx      => $rx,
        -rely      => $ry,
        -relwidth  => $ux,
        -relheight => 1,
    );
    return ( $lbl, $rx, $ry );
}

sub make_space {
    my ( $x, $y, $g ) = @_;
    my $rx  = $ux * $x;
    my $ry  = $uy * $y;
    return ( 'space', $rx, $ry );
}

#---

$bot->Button(
    -text    => "<<",
    -command => sub { move_first_day(-1) }
)->place(
    -relx      => 0.0,
    -rely      => 0.5,
    -relwidth  => 0.30,
    -relheight => 0.70,
    -anchor    => 'w',
);

$bot->Button(
    -text    => "Quit",
    -command => sub {exit}
)->place(
    -relx      => 0.5,
    -rely      => 0.5,
    -relwidth  => 0.30,
    -relheight => 0.70,
    -anchor    => 'center',
);

$bot->Button(
    -text    => ">>",
    -command => sub { move_first_day(+1) }
)->place(
    -relx      => 1.0,
    -rely      => 0.5,
    -relwidth  => 0.30,
    -relheight => 0.70,
    -anchor    => 'e',
);

MainLoop;

sub move_first_day {
    my ($step) = @_;

    print "move $step\n";
    if ( $step < 0 ) {
        my $first_elt = shift @ctrls;
        push @ctrls, $first_elt;
    }
    elsif ( $step > 0 ) {
        my $last_elt = pop @ctrls;
        unshift @ctrls, $last_elt;
    }
    else {
        print "step 0?\n";
        return;
    }

    redraw();
    return;
}

sub redraw {
    for ( my $i = 0; $i < 42; $i++ ) {
        my $ctrl = $ctrls[$i];
        next if $ctrl eq 'space';
        my $c    = $coords[$i];
        my $x    = $c->[0];
        my $y    = $c->[1];
        print "o $i: $x,$y\n";
        $ctrl->place( -relx => $x, -rely => $y );
    }
    return;
}
