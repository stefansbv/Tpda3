package Tpda3::Tk::EntryCalendar;

# ABSTRACT: Calendar Entry widget

use utf8;
use 5.010;
use strict;
use warnings;

use Data::Dump;

use Carp;
use Date::Calc qw(
  check_date
  Days_in_Month
  Day_of_Week
  Add_Delta_Days
  Today
);

use Tk;
use base qw(Tk::Frame);

Construct Tk::Widget 'EntryCalendar';

# valid options for EntryCalendar:
my @validArgs =
  qw( -day -month -year -day_names -month_names -bg_color -fg_color );

sub Populate {    # {{{
    my ( $w, $args ) = @_;

    # eval, in case fonts already exist
    eval {
        $w->fontCreate(qw/f_small  -family courier   -size 10/);
        $w->fontCreate(qw/f_vbig   -family helvetica -size 14 -weight bold/);
        $w->fontCreate(qw/f_bold   -family courier   -size 10 -weight bold/);
    };

    $w->{UX} = 1 / 7;
    $w->{UY} = 1 / 6;
    $w->{DX} = 0;

    $w->{LE_ARR}     = [];   # [0..30] holds the [labels, entries]
    $w->{CELLS_ARR}  = [];   # [0..41] holds the frames with [labels, entries]
    $w->{COORDS_ARR} = [];   # [0..41] holds the coords

    # get parameters which are only for me ...
    my ( $y, $m, $d ) = Today;
    {
        my %received;
        @received{@validArgs} = @$args{@validArgs};

        # ... and remove them before we give $args to SUPER::Populate ...
        #   delete @$args{ @validArgs };
        #   print Dumper $args;

        # defaults:
        $w->{DAYNAME}
            = [qw(luni marți miercuri joi vineri sâmbătă duminică)];
        $w->{MONNAME}
            = [
            qw(ianuarie februarie martie aprilie mai iunie iulie august septembrie octombrie noiembrie decembrie)
            ];
        $w->{DAY}   = $d;    # default is Today
        $w->{MONTH} = $m;
        $w->{YEAR}  = $y;

        # color options
        $w->{BG_COLOR} = 'white';
        $w->{FG_COLOR} = 'black';

        # handle options:
        $w->{DAY}   = $received{'-day'}   if defined $received{'-day'};
        $w->{MONTH} = $received{'-month'} if defined $received{'-month'};
        $w->{YEAR}  = $received{'-year'}  if defined $received{'-year'};

        $w->{DAYNAME} = $received{'-day_names'}
            if defined $received{'-day_names'};
        $w->{MONNAME} = $received{'-month_names'}
            if defined $received{'-month_names'};

        # check: 7 names for DAYNAME, 12 names for MONNAME
        if ( defined $received{'-day_names'}
            and @{ $received{'-day_names'} } != 7 )
        {
            croak
                "error in names array for -day_names option: must provide 7 names";
        }
        if ( defined $received{'-month_names'}
            and @{ $received{'-month_names'} } != 12 )
        {
            croak
                "error in names array for -month_names option: must provide 12 names";
        }
    }    # %received goes out of scope and will be deleted ...
    croak "error in initial date: ", $w->{YEAR}, ", ", $w->{MONTH}, ", ",
        $w->{DAY}
        unless check_date( $w->{YEAR}, $w->{MONTH}, $w->{DAY} );

    # selected day: (need not be visible in current month)
    $w->{SEL_DAY}   = $w->{DAY};
    $w->{SEL_MONTH} = $w->{MONTH};
    $w->{SEL_YEAR}  = $w->{YEAR};

    $w->SUPER::Populate($args)
        ;    # handle other widget options like -relief, -background, ...

    $w->ConfigSpecs(
        -day   => [ METHOD => 'day',   'Day',   $d ],
        -month => [ METHOD => 'month', 'Month', $m ],
        -year  => [ METHOD => 'year',  'Year',  $y ],
        -day_names =>
            [ PASSIVE => 'day_names', 'Day_names', \@{ $w->{DAYNAME} } ],
        -month_names =>
            [ PASSIVE => 'month_names', 'Month_names', \@{ $w->{MONNAME} } ],
        -bg_color => [ METHOD => 'bg_color', 'Bg_color', 'white' ],
        -fg_color => [ METHOD => 'fg_color', 'Fg_color', 'black' ],
    );

    #
    # Contents of widget:
    # ===================

    my $monthname_frm = $w->Frame(
        -width       => 200,
        -height      => 30,
        -borderwidth => '2',

        # -relief      => 'raised',
    );
    $monthname_frm->pack(qw/-side top -padx 1c -pady 5/);

    my $weekdays_frm = $w->Frame(
        -width       => 482,
        -height      => 30,
        -borderwidth => '2',

        # -relief      => 'raised',
    );
    $weekdays_frm->pack(qw/-side top -padx 1c -pady 2/);

    my $top_frm = $w->Frame(
        -width       => 480,
        -height      => 320,

        -borderwidth => 2,
        -relief      => 'sunken',
        -background => 'blue',          # does not work (!?)
    );
    $top_frm->pack(qw/-side top -padx 1c -pady 5/);

    #-- header

    my $day_arr = [qw(luni marți miercuri joi vineri sâmbătă duminică)];

    $w->{l_mm} = $monthname_frm->Label(
        -text               => '',
        -relief             => 'ridge',
        -highlightthickness => 0,
        -width              => 30,
    )->place(
        -relx   => 0.50,
        -rely   => 0.50,
        -anchor => 'center',
    );

    foreach my $x ( 0 .. 6 ) {
        make_label( $w, $weekdays_frm, $x, 0, $day_arr->[$x] );
    }

    my ( $ctrl, $rx, $ry );
    my $le_ctrl = [];
    my $days    = 1;
    my $count   = 1;
    foreach my $y ( 0 .. 5 ) {
        foreach my $x ( 0 .. 6 ) {
            if ( $days > 31 ) {
                ( $ctrl, $rx, $ry ) = register_space( $w, $x, $y );
            }
            else {
                ( $ctrl, $rx, $ry, $le_ctrl )
                    = make_label_entry_frame( $w, $top_frm, $x, $y, $days );
                push @{ $w->{LE_ARR} }, $le_ctrl;
                $days++;
            }
            push @{ $w->{CELLS_ARR} }, $ctrl;
            push @{ $w->{COORDS_ARR} }, [ $rx, $ry ];
        }
    }

}    # Populate }}}

# Methods

sub make_label_entry_frame {
    my ( $w, $wf, $x, $y, $d ) = @_;
    my $rx  = $w->{UX} * $x;
    my $ry  = $w->{UY} * $y;
    my $frm = $wf->Frame(
        -borderwidth => 2,
        -relief      => 'ridge',
    )->place(
        -relx      => $rx,
        -rely      => $ry,
        -relwidth  => $w->{UX},
        -relheight => $w->{UY},
    );
    my ($lbl, $ent) = make_label_entry($w, $frm, $d);
    return ( $frm, $rx, $ry, [$lbl, $ent] );
}

sub make_label_entry {
    my ($w, $wf, $day)= @_;
    my $ft  = $wf->Frame()->pack;
    my $lbl = $ft->Label(
        -text       => $day,
        -width      => 4,
        -font       => 'f_bold',
        # -background => $w->{bg},
    )->pack;
    my $efb = $wf->Frame()->pack;
    my $ent = $efb->Entry(
        -width   => 3,
        # -relief  => 'flat',
        -justify => 'center',
    )->pack(
        -padx => 5,
        -pady => 3,
    );
    return ($lbl, $ent);
}

sub make_label {
    my ( $w, $wf, $x, $y, $g ) = @_;
    my $rx  = $w->{UX} * $x;
    my $ry  = $w->{UY} * $y;
    my $lbl = $wf->Label(
        -text               => $g,
        -relief             => 'ridge',
        -highlightthickness => 0,
    )->place(
        -relx      => $rx,
        -rely      => $ry,
        -relwidth  => $w->{UX},
        -relheight => 1,
    );
    return ( $lbl, $rx, $ry );
}

sub register_space {
    my ( $w, $x, $y ) = @_;
    my $rx  = $w->{UX} * $x;
    my $ry  = $w->{UY} * $y;
    return ( 'space', $rx, $ry );
}

sub label_yyyymm {
    my $w = shift;
    return 'initial' if !$w->{SEL_MONTH} and !$w->{SEL_YEAR};
    return $w->{MONNAME}[ $w->{SEL_MONTH} - 1 ] . '  ' . $w->{SEL_YEAR};
}

sub move_first_day {
    my ( $w, $dx ) = @_;
    my $i = $w->index_of_day(1);
    # print "dx=$dx  index of day #1 = $i\n";
    if ( $dx < 0 and $i > 0 ) {
        foreach my $i ( 1 .. abs($dx) ) {
            my $first_elt = shift @{ $w->{CELLS_ARR} };
            push @{ $w->{CELLS_ARR} }, $first_elt;
        }
        redraw($w);
        return 1;
    }
    elsif ( $dx > 0 and $i + $dx < 7 ) {
        foreach my $i ( 1 .. abs($dx) ) {
            my $last_elt = pop @{ $w->{CELLS_ARR} };
            unshift @{ $w->{CELLS_ARR} }, $last_elt;
        }
        redraw($w);
        return 1;
    }
    return;
}

sub hide_day {
    my ($w, $d) = @_;
    say "hide_day: $d";
    my $i = index_of_day($w, $d);
    my $ctrl = $w->{CELLS_ARR}[$i];
    $ctrl->placeForget if $ctrl ne 'space';
    return 1;
}

sub show_day {
    my ( $w, $d ) = @_;
    say "show_day: $d";
    my $i = index_of_day($w, $d);
    my $ctrl = $w->{CELLS_ARR}[$i];
    if ( $ctrl ne 'space' ) {
        my $c = $w->{COORDS_ARR}[$i];
        $ctrl->place(
            -relx      => $c->[0],
            -rely      => $c->[1],
            -relwidth  => $w->{UX},
            -relheight => $w->{UY},
        );
    }
    return 1;
}

sub redraw {
    my $w = shift;
    for ( my $i = 0; $i < 42; $i++ ) {
        my $ctrl = $w->{CELLS_ARR}[$i];
        next if $ctrl eq 'space';
        my $c = $w->{COORDS_ARR}[$i];
        $ctrl->place(
            -relx      => $c->[0],
            -rely      => $c->[1],
            -relwidth  => $w->{UX},
            -relheight => $w->{UY},
        );
    }
    return 1;
}

sub index_of_day {
    my ( $w, $d ) = @_;
    my $dx;
    for ( my $n = 0 ; $n < 42 ; $n++ ) {
        my $ctrl = $w->{CELLS_ARR}[$n];
        next if $ctrl eq 'space';
        $dx = $n;
        last;
    }
    my $i    = $d - 1 + $dx;
    my $ctrl = $w->{CELLS_ARR}[$i];
    die "Wrong index $i!\n" if $ctrl eq 'space';
    return $i;
}

sub reset_places {
    my $w = shift;
    my $i = $w->index_of_day(1);
    move_first_day( $w, 0 - $i );
    redraw($w);
    return 1;
}

sub day {    # {{{
    my ( $w, $d ) = @_;
    if ( $#_ > 0 ) {
        $w->{SEL_DAY} = $d;
        # display_month( $w, $w->{SEL_YEAR}, $w->{SEL_MONTH} );
        return;
    }
    else {
        return $w->{SEL_DAY};
    }
}    # }}}

sub month {    # {{{
    my ( $w, $m ) = @_;
    if ( $#_ > 0 ) {
        $w->{SEL_MONTH} = $m;
        # print $w->{SEL_YEAR}, $w->{SEL_MONTH}, "\n";
        # display_month( $w, $w->{SEL_YEAR}, $w->{SEL_MONTH} );
    }
    else {
        return $w->{SEL_MONTH};
    }
    return;
}    # }}}

sub year {    # {{{
    my ( $w, $y ) = @_;
    if ( $#_ > 0 ) {
        $w->{SEL_YEAR} = $y;
        # print $w->{SEL_YEAR}, $w->{SEL_MONTH}, "\n";
        # display_month( $w, $w->{SEL_YEAR}, $w->{SEL_MONTH} );
    }
    else {
        return $w->{SEL_YEAR};
    }
    return;
}    # }}}

sub fg_color {
    my ( $w, $c ) = @_;
    if ( $#_ > 0 ) {
        $w->{FG_COLOR} = $c;
        # display_month( $w, $w->{SEL_YEAR}, $w->{SEL_MONTH} );
    }
    else {
        return $w->{FG_COLOR};
    }
    return;
}

sub bg_color {
    my ( $w, $c ) = @_;
    if ( $#_ > 0 ) {
        $w->{BG_COLOR} = $c;
        # display_month( $w, $w->{SEL_YEAR}, $w->{SEL_MONTH} );
    }
    else {
        return $w->{BG_COLOR};
    }
    return;
}

sub clear_entry_all {
    my $w = shift;
    my $eary = $w->get_label_entry_array;
    foreach my $ez ( @{$eary} ) {
        $ez->[1]->delete( 0, 'end' );
    }
    return;
}

sub get_label_entry_array {
    my $w = shift;
    return $w->{LE_ARR};
}

=head2 $minical->select_month($year, $month)

Positions the EntryCalendar to the corresponding year and month and
reconfigures the positions of the days.

=cut

sub select_month {
    my ( $w, $yyyy, $mm ) = @_;
    if ( check_date( $yyyy, $mm, 1 ) ) {
        $w->{SEL_YEAR}  = $yyyy;
        $w->{SEL_MONTH} = $mm;
        $w->{SEL_DAY}   = 1;
        $w->configure( -day => 1, -month => $mm, -year => $yyyy );
        display_month( $w, $yyyy, $mm );
        $w->{l_mm}->configure( -text => label_yyyymm($w) );
    }
    else {
        croak "Error in date: $yyyy, $mm, 1";
    }
    return 1;
}

=head2 $minical->display_month($year, $month)

Displays the specified month.  When a callback for the
E<lt>Display-MonthE<gt> event has been registered it will be called
with ($year, $month, 1) as parameters.

=cut

sub display_month {
    my ( $w, $yyyy, $mm ) = @_;

    croak "error in date:  $mm, $yyyy" unless check_date( $yyyy, $mm, 1 );

    reset_places($w);

    $w->{YEAR}  = $yyyy;
    $w->{MONTH} = $mm;

    my $dim = Days_in_Month( $yyyy, $mm );
    my $dow = Day_of_Week( $yyyy, $mm, 1 );

    # print "Day of week   = $dow\n";
    # print "Days in month = $dim\n";
    if ( $dow > 1 ) {
        my $dx = $dow - 1;
        move_first_day( $w, $dx );
    }
    my @to_hide = $dim + 1 .. 31;
    hide_day( $w, $_ ) for @to_hide;

    return;
}

# Internal methods

# sub _configure_labels {    # {{{
#     my ($w) = @_;
#     for ( my $i = 0 ; $i < 7 ; $i++ ) {
#         $w->{LABELS}->[$i]->configure(
#             -background => $w->{BG_LABEL_COLOR},
#             -foreground => $w->{FG_LABEL_COLOR},
#         );
#     }
#     return;
# }    # _configure_labels }}}

1;

__END__

# POD {{{

=head1 AUTHOR

Stefan Suciu, E<lt>stefan.suciu@s2i2.roE<gt>

Lorenz Domke, E<lt>lorenz.domke@gmx.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Stefan Suciu

Copyright (C) 2008 by Lorenz Domke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

# end POD Section }}}
