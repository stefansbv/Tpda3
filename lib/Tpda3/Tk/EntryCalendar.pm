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
  qw( -day -month -year -day_names -month_names -bg_color -fg_color
  -bg_label_color -fg_label_color
  -bg_sel_color -fg_sel_color
);

sub Populate {    # {{{
    my ( $w, $args ) = @_;

    $w->{UX} = 1 / 7;
    $w->{UY} = 1 / 6;

    $w->{ENT_ARR}    = []; # [0..30] holds the [labels, entries]
    $w->{FRM_ARR}    = []; # [0..30] holds the frames with [labels, entries]
    $w->{COORDS_ARR} = []; # [0..41] holds the coords

    # print ">", join("|", @_), "\n";
    # print Dumper(@_);

    # get parameters which are only for me ...
    my ( $y, $m, $d ) = Today;
    {
        my %received;
        @received{@validArgs} = @$args{@validArgs};

        # ... and remove them before we give $args to SUPER::Populate ...
        #   delete @$args{ @validArgs };
        #   print Dumper $args;

        # defaults:
        $w->{DAYNAME} = [qw(luni marți miercuri joi vineri sâmbătă duminică)];
        $w->{MONNAME} = [
            qw(ianuarie februarie martie aprilie mai iunie iulie august septembrie octombrie noiembrie decembrie)
        ];
        $w->{DAY}      = $d;    # default is Today
        $w->{MONTH}    = $m;
        $w->{YEAR}     = $y;

        # $w->{MON_ARR}  = [];
        # $w->{DAY_ARR}  = [];    # hold entries <---> days in month

        # Global array of 6 x 7 day labels
        # $MON_ARR[$i][$j] is on position $j in line $i
        #                  0 <= $i <= 5,  0 <= $j <= 6

        # color options
        # $w->{BG_COLOR}       = 'white';
        # $w->{FG_COLOR}       = 'black';
        # $w->{BG_SEL_COLOR}   = 'blue';
        # $w->{FG_SEL_COLOR}   = 'white';
        # $w->{BG_LABEL_COLOR} = '#bFbFbF';
        # $w->{FG_LABEL_COLOR} = 'black';
        # $w->{BG_WKDAY_COLOR} = 'yellow';
        # $w->{FG_WKDAY_COLOR} = 'blue';
        # $w->{BG_WKEND_COLOR} = 'red';
        # $w->{FG_WKEND_COLOR} = 'green';

        # handle options:
        $w->{DAY}   = $received{'-day'}   if defined $received{'-day'};
        $w->{MONTH} = $received{'-month'} if defined $received{'-month'};
        $w->{YEAR}  = $received{'-year'}  if defined $received{'-year'};
        # $w->{DAYNAME} = $received{'-day_names'}
        #   if defined $received{'-day_names'};
        # $w->{MONNAME} = $received{'-month_names'}
        #   if defined $received{'-month_names'};

#         # check: 7 names for DAYNAME, 12 names for MONNAME
#         if ( defined $received{'-day_names'}
#             and @{ $received{'-day_names'} } != 7 )
#         {
#             croak
# "error in names array for -day_names option: must provide 7 names";
#         }
#         if ( defined $received{'-month_names'}
#             and @{ $received{'-month_names'} } != 12 )
#         {
#             croak
# "error in names array for -month_names option: must provide 12 names";
#         }
    }    # %received goes out of scope and will be deleted ...
    croak "error in initial date: ", $w->{YEAR}, ", ", $w->{MONTH}, ", ",
        $w->{DAY}
        unless check_date( $w->{YEAR}, $w->{MONTH}, $w->{DAY} );

    # selected day: (need not be visible in current month)
    # $w->{SEL_DAY}   = $w->{DAY};
    # $w->{SEL_MONTH} = $w->{MONTH};
    # $w->{SEL_YEAR}  = $w->{YEAR};

    # $w->SUPER::Populate($args)
    #   ;    # handle other widget options like -relief, -background, ...

    $w->ConfigSpecs(
        -day   => [ METHOD => 'day',   'Day',   $d ],
        -month => [ METHOD => 'month', 'Month', $m ],
        -year  => [ METHOD => 'year',  'Year',  $y ],
        # -day_names =>
        #   [ PASSIVE => 'day_names', 'Day_names', \@{ $w->{DAYNAME} } ],
        # -month_names =>
        #   [ PASSIVE => 'month_names', 'Month_names', \@{ $w->{MONNAME} } ],
        # -bg_color     => [ METHOD => 'bg_color',     'Bg_color',     'white' ],
        # -fg_color     => [ METHOD => 'fg_color',     'Fg_color',     'black' ],
        # -bg_sel_color => [ METHOD => 'bg_sel_color', 'Bg_sel_color', 'blue' ],
        # -fg_sel_color => [ METHOD => 'fg_sel_color', 'Fg_sel_color', 'white' ],
        # -bg_label_color =>
        #   [ METHOD => 'bg_label_color', 'Bg_label_color', '#bFbFbF' ],
        # -fg_label_color =>
        #   [ METHOD => 'fg_label_color', 'Fg_label_color', 'black' ],
        # -bg_wkday_color =>
        #   [ METHOD => 'bg_wkday_color', 'Bg_wkday_color', 'white' ],
        # -fg_wkday_color =>
        #   [ METHOD => 'fg_wkday_color', 'Fg_wkday_color', 'black' ],
        # -bg_wkend_color =>
        #   [ METHOD => 'bg_wkend_color', 'Bg_wkend_color', 'white' ],
        # -fg_wkend_color =>
        #   [ METHOD => 'fg_wkend_color', 'Fg_wkend_color', 'black' ],
        # -bg_hlday_color =>
        #   [ METHOD => 'bg_hlday_color', 'Bg_hlday_color', 'white' ],
        # -fg_hlday_color =>
        #   [ METHOD => 'fg_hlday_color', 'Fg_hlday_color', 'black' ],
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
        -background  => 'grey60',
    );
    $top_frm->pack(qw/-side top -padx 1c -pady 5/);

    #-- header

    my $day_arr = [qw(luni marți miercuri joi vineri sâmbătă duminică)];

    my $week_lbl = $monthname_frm->Label(
        -text               => 'ianuarie 2019',
        -relief             => 'ridge',
        -highlightthickness => 0,
        -width              => 30,
    )->place(
        -relx      => 0.50,
        -rely      => 0.50,
        -anchor    => 'center',
    );

    foreach my $x ( 0 .. 6 ) {
        make_label( $w, $weekdays_frm, $x, 0, $day_arr->[$x] );
    }

    my ($ctrl, $rx, $ry);
    my $le_ctrl = [];
    my $days  = 1;
    my $count = 1;
    foreach my $y ( 0 .. 5 ) {
        foreach my $x ( 0 .. 6 ) {
            if ( $days > 31 ) {
                ( $ctrl, $rx, $ry ) = register_space( $w, $x, $y );
            }
            else {
                ( $ctrl, $rx, $ry, $le_ctrl ) =
                    make_label_entry_frame( $w, $top_frm, $x, $y, $days );
                push @{ $w->{ENT_ARR} }, $le_ctrl;
                $days++;
            }
            push @{ $w->{FRM_ARR} }, $ctrl;
            push @{ $w->{COORDS_ARR} }, [ $rx, $ry ];
        }
    }

    adjusts_calendar($w);
}    # Populate }}}

# Methods

sub adjusts_calendar {
    my $w = shift;
    my $yyyy = $w->{YEAR};
    my $mm   = $w->{MONTH};
    my $dow  = Day_of_Week( $yyyy, $mm, 1 );
    my $dim  = Days_in_Month( $yyyy, $mm );
    print "Day of week   = $dow\n";
    print "Days in month = $dim\n";
    my @to_hide = $dim + 1 .. 31;
    dd @to_hide;
    move_first_day( $dow - 1 ) if $dow > 1;
    hide_day($w, $_) for @to_hide;
    return;
}

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
        # -background => $w->{bg},
    )->pack;
    my $efb = $wf->Frame()->pack;
    my $ent = $efb->Entry(
        -width   => 3,
        -relief  => 'flat',
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
    return 'none' if !$w->{SEL_MONTH} and !$w->{SEL_YEAR};
    return $w->{MONNAME}[ $w->{SEL_MONTH} - 1 ] . '  ' . $w->{SEL_YEAR};
}

sub move_first_day {
    my ( $w, $step ) = @_;
    if ( $step < 0 ) {
        foreach my $i ( 1 .. abs($step) ) {
            my $first_elt = shift @{ $w->{FRM_ARR} };
            push @{ $w->{FRM_ARR} }, $first_elt;
        }
    }
    elsif ( $step > 0 ) {
        foreach my $i ( 1 .. abs($step) ) {
            my $last_elt = pop @{ $w->{FRM_ARR} };
            unshift @{ $w->{FRM_ARR} }, $last_elt;
        }
    }
    redraw($w);
    return 1;
}

sub hide_day {
    my ($w, $i) = @_;
    say "hide_day: $i";
    $i--;                       # day to index
    my $ctrl = $w->{FRM_ARR}[$i];
    $ctrl->placeForget if $ctrl ne 'space';
    return 1;
}

sub show_day {
    my ( $w, $i ) = @_;
    say "show_day: $i";
    $i--;                       # day to index
    my $ctrl = $w->{FRM_ARR}[$i];
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
        my $ctrl = $w->{FRM_ARR}[$i];
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

# sub index_of {    # {{{
#     my $w      = shift;
#     my $m_name = shift;
#     my $i      = 0;
#     foreach my $mnm ( @{ $w->{MONNAME} } ) {
#         $i++;
#         return $i if $mnm eq $m_name;
#     }
#     return $i;
# }    # index_of }}}

sub day {    # {{{
    my ( $w, $d ) = @_;
    if ( $#_ > 0 ) {
        $w->{SEL_DAY} = $d;
#        display_month( $w, $w->{SEL_YEAR}, $w->{SEL_MONTH} );
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
#        display_month( $w, $w->{SEL_YEAR}, $w->{SEL_MONTH} );
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
#        display_month( $w, $w->{SEL_YEAR}, $w->{SEL_MONTH} );
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

# sub fg_label_color {    # {{{
#     my ( $w, $c ) = @_;
#     if ( $#_ > 0 ) {
#         $w->{FG_LABEL_COLOR} = $c;
# #        _configure_labels($w);
#     }
#     else {
#         return $w->{FG_LABEL_COLOR};
#     }
#     return;
# }    # }}}

# sub bg_label_color {    # {{{
#     my ( $w, $c ) = @_;
#     if ( $#_ > 0 ) {
#         $w->{BG_LABEL_COLOR} = $c;
# #        _configure_labels($w);
#     }
#     else {
#         return $w->{BG_LABEL_COLOR};
#     }
#     return;
# }    # }}}

# sub fg_sel_color {    # {{{
#     my ( $w, $c ) = @_;
#     if ( $#_ > 0 ) {
#         $w->{FG_SEL_COLOR} = $c;
#     }
#     else {
#         return $w->{FG_SEL_COLOR};
#     }
#     return;
# }    # }}}

# sub bg_sel_color {    # {{{
#     my ( $w, $c ) = @_;
#     if ( $#_ > 0 ) {
#         $w->{BG_SEL_COLOR} = $c;
#     }
#     else {
#         return $w->{BG_SEL_COLOR};
#     }
#     return;
# }    # }}}

# sub bg_wkday_color {
#     my ( $w, $c ) = @_;
#     if ( $#_ > 0 ) {
#         $w->{BG_WKDAY_COLOR} = $c;
# #        _configure_labels_wkday($w);
#     }
#     else {
#         return $w->{BG_WKDAY_COLOR};
#     }
#     return;
# }

# sub fg_wkday_color {
#     my ( $w, $c ) = @_;
#     if ( $#_ > 0 ) {
#         $w->{FG_WKDAY_COLOR} = $c;
# #        _configure_labels_wkday($w);
#     }
#     else {
#         return $w->{FG_WKDAY_COLOR};
#     }
#     return;
# }

# sub bg_wkend_color {
#     my ( $w, $c ) = @_;
#     if ( $#_ > 0 ) {
#         $w->{BG_WKEND_COLOR} = $c;
# #        _configure_labels_wkend($w);
#     }
#     else {
#         return $w->{BG_WKEND_COLOR};
#     }
#     return;
# }

# sub fg_wkend_color {
#     my ( $w, $c ) = @_;
#     if ( $#_ > 0 ) {
#         $w->{FG_WKEND_COLOR} = $c;
# #        _configure_labels_wkend($w);
#     }
#     else {
#         return $w->{FG_WKEND_COLOR};
#     }
#     return;
# }

sub date {    #{{{ -----------------------------------------------------

=head2 my ($year, $month, $day) = $minical->date()

Returns the selected date from Tk::EntryCalendar.
Day and month numbers are always two digits (with leading zeroes).

=cut

    my ($w) = @_;
    my $yyyy = sprintf( "%4d",  $w->{SEL_YEAR} );
    my $mm   = sprintf( "%02d", $w->{SEL_MONTH} );
    my $dd   = sprintf( "%02d", $w->{SEL_DAY} );
    return ( $yyyy, $mm, $dd );
}    # date }}}

# sub clear_entry_all {
#     my $w = shift;
#     foreach my $i ( 0 .. 5 ) {
#         foreach my $j ( 0 .. 6 ) {
#             $w->{ENT_ARR}->[$i][$j]->delete( 0, 'end' );
#         }
#     }
# }

sub get_label_entry_array {
    my $w = shift;
    return $w->{ENT_ARR};
}

sub select_date {    #{{{ ----------------------------------------------

=head2 $minical->select_date($year, $month, $day)

Selects a date and positions the EntryCalendar to the corresponding
year and month. The selected date is hilighted.

=cut

    my ( $w, $yyyy, $mm, $dd ) = @_;
    if ( check_date( $yyyy, $mm, $dd ) ) {
        $w->{SEL_YEAR}  = $yyyy;
        $w->{SEL_MONTH} = $mm;
        $w->{SEL_DAY}   = $dd;
        $w->configure( -day => $dd, -month => $mm, -year => $yyyy );
        display_month( $w, $yyyy, $mm );
        $w->{l_mm}->configure( -text => label_yyyymm($w) );
        update_entry_array($w);
    }
    else {
        croak "Error in date: $yyyy, $mm, $dd";
    }
    return 1;
}    # select_date }}}

=head2 $minical->display_month($year, $month)

Displays the specified month.  When a callback for the
E<lt>Display-MonthE<gt> event has been registered it will be called
with ($year, $month, 1) as parameters.

=cut

# sub display_month { #{{{
#     my ( $w, $yyyy, $mm ) = @_;

#     croak "error in date:  $mm, $yyyy" unless check_date( $yyyy, $mm, 1 );

#     $w->{YEAR}     = $yyyy;
#     $w->{MONTH}    = $mm;

#     $w->{mtxt} = $w->{MONNAME}[ $mm - 1 ];

#     my $day = " ";
#     my $dim = Days_in_Month( $yyyy, $mm );
#     my $dow = Day_of_Week( $yyyy, $mm, 1 );
#     foreach my $i ( 0 .. 5 ) {
#         foreach my $j ( 0 .. 6 ) {

#             # Set $day to 1 if the first day reaches the correct day
#             # of the week for the first day of the month
#             $day = 1 if $day eq " " and $i == 0 and $j + 1 == $dow;
#             $w->{MON_ARR}->[$i][$j]->configure(
#                 -text       => $day,
#                 -background => $w->{bg},
#                 -foreground => $w->{FG_COLOR},
#             );
#             if ( $day =~ /\d/ ) {
#                 $w->{FRM_ARR}->[$i][$j]{lfb}->packForget();
#                 $w->{FRM_ARR}->[$i][$j]{efb}->pack();
#             }
#             else {
#                 $w->{FRM_ARR}->[$i][$j]{lfb}->pack();
#                 $w->{FRM_ARR}->[$i][$j]{efb}->packForget();
#                 $w->{MON_ARR}->[$i][$j]->configure(
#                     -background => $w->{bg} );
#             }

#             $day++ if $day ne " ";
#             $day = " " if $day =~ /\d/ and $day > $dim;
#         }
#     }

#     # callback if defined:
#     $w->{CALLBACK}->{'<Display-Month>'}( $yyyy, $mm, 1 )
#       if defined $w->{CALLBACK}->{'<Display-Month>'};

#     # if current month contains selected day: hilight it
#     # _select_day( $w, $w->{SEL_YEAR}, $w->{SEL_MONTH}, $w->{SEL_DAY},
#     #     $w->{BG_SEL_COLOR}, $w->{FG_SEL_COLOR} );

#     return;
# } # display_month }}}

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

# sub _configure_labels_wkday {
#     my ($w) = @_;
#     for ( my $i = 0 ; $i < 5 ; $i++ ) {
#         for ( my $j = 0 ; $j < 5 ; $j++ ) {
#             # print "wkday: $i,$j\n";
#             $w->{MON_ARR}->[$i][$j]->configure(
#                 -background => $w->{BG_WKDAY_COLOR},
#                 -foreground => $w->{FG_WKDAY_COLOR},
#             );
#         }
#     }
#     return;
# }

# sub _configure_labels_wkend {
#     my ($w) = @_;
#     for ( my $i = 0 ; $i < 5 ; $i++ ) {
#         for ( my $j = 5 ; $j < 7 ; $j++ ) {
#             # print "wkend: $i,$j\n";
#             $w->{MON_ARR}->[$i][$j]->configure(
#                 -background => $w->{BG_WKEND_COLOR},
#                 -foreground => $w->{FG_WKEND_COLOR},
#             );
#         }
#     }
#     return;
# }

# check, if $i, $j position is a valid date {{{
# sub _check_i_j {
#     my ( $w, $i, $j ) = @_;
#     my $dow = Day_of_Week( $w->{YEAR}, $w->{MONTH}, 1 );
#     my $pos = $i * 7 + $j + 2 - $dow;
#     if ( $pos > 0 and $pos <= Days_in_Month( $w->{YEAR}, $w->{MONTH} ) ) {
#         return ( $w->{YEAR}, $w->{MONTH}, $pos );
#     }
#     else {
#         return ( undef, undef, undef );
#     }
# }    # _check_i_j }}}

# }}}


1;

__END__

# POD {{{

=head1 AUTHOR

Lorenz Domke, E<lt>lorenz.domke@gmx.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Lorenz Domke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

# end POD Section }}}
