package Tpda3::Tk::MaxiCalendar;

use strict;
use warnings;

our $VERSION = '0.14';
our $TKV = '804.027';

use Tk;
use Carp;
use Date::Calc qw(
  check_date
  Days_in_Month
  Day_of_Week
  Add_Delta_Days
  Today
);

require Tk::Frame;
use base qw(Tk::Frame);
#use Data::Dumper;

Construct Tk::Widget 'MaxiCalendar';

# POD Section {{{

=head1 NAME

Tk::MaxiCalendar - simple calendar widget for date selection

=head1 SYNOPSIS

 use Tk;
 use Tk::MaxiCalendar;

 my $minical = <PARENT>->MaxiCalendar(-day   => $dd,
                                      -month => $mm,
                                      -year  => $yyyy,
                                      -day_names   => \@DAYNAMES,
                                      -month_names => \@MONTHNAMES);

 $minical->pack;
 # or:
 $minical->grid( ... );

 my ($yyyy, $mm, $dd) = $minical->date; # --> (2004, 09, 16)

=head1 DESCRIPTION

C<Tk::MaxiCalendar> provides a tiny calendar widget
which can be used to select valid dates.

=head2 Graphical Representation

The widget looks like:

  +------------------------------+
  |        September 2004        |
  |                              |
  |  L   Ma  Mi  J   V   S   D   |
  |           1   2   3   4   5  |
  |   6   7   8   9  10  11  12  |
  |  13  14  15 [16] 17  18  19  |
  |  20  21  22  23  24  25  26  |
  |  27  28  29  30              |
  +------------------------------+

Clicking with mouse button one on a day selects that day. The selected
day can be retrieved with the $minical->date() method.

=head2 Handlers

It is possible to register user provided handlers for the MaxiCalendar
widget.  You may for example register a "double-button-1" handler
which is invoked by doubleclicking one of the days.

Example:

 $minical->register('<Double-1>', \&double_1_handler);

 <Display-Month>

If one of those events occurs on one of the displayed days, the
registered callback is invoked with the following parameters:

 $yyyy, $mm, $dd   (year, month and day)

NOTE: If there are two handlers for <Button-n> and <Double-n> then
both handlers are invoked in case of a double-button-n event because a
double-button-n event is also a button-n event.

A callback routine for the special "event" E<lt>Display-MonthE<gt>
will be called each time the minicalendar is updated i.e. when a month
has been displayed. This can be used to hilight certain days with
different colors. See also C<hilight> method below. Note that in this
case the $dd parameter is always set to 1.

=head1 EXAMPLE

Here is a fullblown example for the usage of Tk::MaxiCalendar

 use Tk;
 use Tk::MaxiCalendar;

 use strict;
 my $top = MainWindow->new;

 my $frm1 = $top->Frame->pack;  # Frame to place MaxiCalendar in

 my $minical = $frm1->MaxiCalendar->pack;

 my $frm2 = $top->Frame->pack;  # Frame for Ok Button
 my $b_ok = $frm2->Button(-text => "Ok",
                -command => sub {
                  my ($year, $month, $day) = $minical->date;
                  print "Selected date: $year/$month/$day\n";
                  exit;
                },
            )->pack;
 MainLoop;

=head1 OPTIONS

The following options can be specified for Tk::MaxiCalendar:

=over 4

=item * -day => <day>

Sepcify first selected day.

=item * -month => <month>

Sepcify first selected month.

=item * -year => <year>

Sepcify first selected year.

=item * -day_names => <array_ref>

Reference to an array which holds the labels for the day names.
This can be used to define labels for another language.

=item * -month_names => <array_ref>

Reference to an array which holds the labels for the month names.

=item * -bg => <color>

Background color. Note that this changes only the outer part of the widget. Day name labels and the
main area of the calendar are not affected.

=item * -bg_color => <color>

Background color for the area which contains the day numbers.

=item * -fg_color => <color>

Foreground color for the day numbers.

=item * -bg_label_color => <color>

Background color for the day name labels. Should be the same as -bg.

=item * -fg_label_color => <color>

Foreground color for the day name labels.

=item * -bg_sel_color => <color>

Background color for the selected day.

=item * -fg_sel_color => <color>

Foreground color for the selected day.

=back

=head1 METHODS

The following methods are provided by Tk::MaxiCalendar:

=cut

#}}}


# valid options for MaxiCalendar:
my @validArgs = qw( -day -month -year -day_names -month_names -bg_color -fg_color
 -bg_label_color -fg_label_color
 -bg_sel_color -fg_sel_color
);


sub Populate {    # {{{
    my ( $w, $args ) = @_;

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
        $w->{DAYNAME} = [qw(L Ma Mi J V S D)];
        $w->{MONNAME} = [
            qw(ianuarie februarie martie aprilie mai iunie iulie august septembrie octombrie noiembrie decembrie)
        ];
        $w->{DAY}      = $d;    # default is Today
        $w->{MONTH}    = $m;
        $w->{YEAR}     = $y;
        $w->{CALLBACK} = {};
        $w->{MON_ARR}  = [];

        # Global array of 6 x 7 day labels
        # $MON_ARR[$i][$j] is on position $j in line $i
        #                  0 <= $i <= 5,  0 <= $j <= 6

        # color options
        $w->{BG_COLOR}       = 'white';
        $w->{FG_COLOR}       = 'black';
        $w->{BG_SEL_COLOR}   = 'blue';
        $w->{FG_SEL_COLOR}   = 'white';
        $w->{BG_LABEL_COLOR} = '#bFbFbF';
        $w->{FG_LABEL_COLOR} = 'black';

        # handle options:
        $w->{DAY}   = $received{"-day"}   if defined $received{"-day"};
        $w->{MONTH} = $received{"-month"} if defined $received{"-month"};
        $w->{YEAR}  = $received{"-year"}  if defined $received{"-year"};
        $w->{DAYNAME} = $received{"-day_names"}
          if defined $received{"-day_names"};
        $w->{MONNAME} = $received{"-month_names"}
          if defined $received{"-month_names"};

        # check: 7 names for DAYNAME, 12 names for MONNAME
        if ( defined $received{"-day_names"}
            and @{ $received{"-day_names"} } != 7 )
        {
            croak
"error in names array for -day_names option: must provide 7 names";
        }
        if ( defined $received{"-month_names"}
            and @{ $received{"-month_names"} } != 12 )
        {
            croak
"error in names array for -month_names option: must provide 12 names";
        }
    }    # %received goes out of scope and will be deleted ...
    croak "error in initial date: ", $w->{YEAR}, ", ", $w->{MONTH}, ", ",
        $w->{DAY}
        unless check_date( $w->{YEAR}, $w->{MONTH}, $w->{DAY} );

    $w->{YEAR_BAK} = $w->{YEAR};

    # selected day: (need not be visible in current month)
    $w->{SEL_DAY}   = $w->{DAY};
    $w->{SEL_MONTH} = $w->{MONTH};
    $w->{SEL_YEAR}  = $w->{YEAR};

    $w->SUPER::Populate($args)
      ;    # handle other widget options like -relief, -background, ...

    $w->ConfigSpecs(
        -day   => [ METHOD => "day",   "Day",   $d ],
        -month => [ METHOD => "month", "Month", $m ],
        -year  => [ METHOD => "year",  "Year",  $y ],
        -day_names =>
          [ PASSIVE => "day_names", "Day_names", \@{ $w->{DAYNAME} } ],
        -month_names =>
          [ PASSIVE => "month_names", "Month_names", \@{ $w->{MONNAME} } ],
        -bg_color     => [ METHOD => "bg_color",     "Bg_color",     'white' ],
        -fg_color     => [ METHOD => "fg_color",     "Fg_color",     'black' ],
        -bg_sel_color => [ METHOD => "bg_sel_color", "Bg_sel_color", 'blue' ],
        -fg_sel_color => [ METHOD => "fg_sel_color", "Fg_sel_color", 'white' ],
        -bg_label_color =>
          [ METHOD => "bg_label_color", "Bg_label_color", '#bFbFbF' ],
        -fg_label_color =>
          [ METHOD => "fg_label_color", "Fg_label_color", 'black' ],
    );

    #
    # Contents of widget:
    # ===================

    my $frm1 = $w->Frame()->pack();
    my $frm2 = $w->Frame()->pack();

    $w->{l_mm} = $frm1->Label(
        -text       => label_yyyymm($w),
        -width      => 20,
        -background => "#FFFFFF",
    )->pack( -side => "left" );

    $w->{bg} = $w->cget('-background');

    # Calendar frame for month
    my $i = 0;
    foreach my $day ( @{ $w->{DAYNAME} } ) {
        $w->{LABELS}->[$i] = $frm2->Label(
            -text       => $day,
            -background => $w->{BG_LABEL_COLOR},
            -foreground => $w->{FG_LABEL_COLOR},
            -width      => 3,
        );
        $w->{LABELS}->[$i]->grid(
            -column => $i,
            -row    => 0,
            -sticky => "w",
            -padx   => 1,
            -pady   => 2
        );
        $i++;
    }
    my $day = ' ';
    for ( $i = 0 ; $i < 6 ; $i++ ) {
        for ( my $j = 0 ; $j < 7 ; $j++ ) {
            my $mf = $frm2->Frame(
                -borderwidth => 2,
                -relief      => 'ridge',
            )->grid(
                -column => $j,
                -row    => $i + 1,
                -sticky => "w",
                -padx   => 3,
                -pady   => 3,
            );
            my $ft = $mf->Frame()->pack;
            $w->{MON_ARR}->[$i][$j] = $ft->Label(
                -text       => $day,
                -width      => 4,
                -background => "#FFFFFF",
            )->pack;
            $w->{FRM_ARR}->[$i][$j]{lfb} = $mf->Frame()->pack;
            $w->{FRM_ARR}->[$i][$j]{efb} = $mf->Frame();
            $w->{FRM_ARR}->[$i][$j]{lfb}->Label(
                -text   => ' ',
                -width  => 2,
                -background => $w->{bg},
            )->pack(
                -padx => 5,
                -pady => 3,
            );
            $w->{FRM_ARR}->[$i][$j]{efb}->Entry(
                -width  => 2,
                -relief => 'flat',
            )->pack(
                -padx => 5,
                -pady => 3,
            );

            my ( $ii, $jj ) =
              ( $i, $j );    # $ii and $jj are variables in a closure ...

            $w->{MON_ARR}->[$i][$j]->bind(
                '<Button-1>',
                sub {
                    _sel( $w, $ii, $jj );
                }
            );
        }
    }
    display_month( $w, $w->{YEAR}, $w->{MONTH} );

    #
    # calendar_day_stub($w);

    # print "-----\n";
    # print Dumper $w;
    return;
}    # Populate }}}

# Methods

sub label_yyyymm {
    my $w = shift;
    return 'none' if !$w->{SEL_MONTH} and !$w->{SEL_YEAR};
    return $w->{MONNAME}[ $w->{SEL_MONTH} - 1 ] . '  ' . $w->{SEL_YEAR};
}

sub index_of { # {{{
  my $w = shift;
  my $m_name = shift;
  my $i = 0;
  foreach my $mnm ( @{ $w->{MONNAME} }){
    $i++;
    return $i if $mnm eq $m_name;
  }
  return $i;
} # index_of }}}

sub day { # {{{
  my ($w, $d) = @_;
  if ($#_ > 0 ){
    $w->{SEL_DAY} = $d;
    display_month($w, $w->{SEL_YEAR}, $w->{SEL_MONTH});
    return;
  } else {
    return $w->{SEL_DAY};
  }
} # }}}

sub month { # {{{
  my ($w, $m) = @_;
  if ($#_ > 0 ){
    $w->{SEL_MONTH} = $m;
    display_month($w, $w->{SEL_YEAR}, $w->{SEL_MONTH});
  } else {
    return $w->{SEL_MONTH};
  }
  return;
} # }}}

sub year { # {{{
  my ($w, $y) = @_;
  if ($#_ > 0 ){
    $w->{SEL_YEAR} = $y;
    display_month($w, $w->{SEL_YEAR}, $w->{SEL_MONTH});
  } else {
    return $w->{SEL_YEAR};
  }
  return;
} # }}}

sub fg_color { # {{{
  my ($w, $c) = @_;
  if ($#_ > 0 ){
    $w->{FG_COLOR} = $c;
    display_month($w, $w->{SEL_YEAR}, $w->{SEL_MONTH});
  } else {
    return $w->{FG_COLOR};
  }
  return;
} # }}}

sub bg_color { # {{{
  my ($w, $c) = @_;
  if ($#_ > 0 ){
    $w->{BG_COLOR} = $c;
    display_month($w, $w->{SEL_YEAR}, $w->{SEL_MONTH});
  } else {
    return $w->{BG_COLOR};
  }
  return;
} # }}}

sub fg_label_color { # {{{
  my ($w, $c) = @_;
  if ($#_ > 0 ){
    $w->{FG_LABEL_COLOR} = $c;
    _configure_labels($w);
  } else {
    return $w->{FG_LABEL_COLOR};
  }
  return;
} # }}}

sub bg_label_color { # {{{
  my ($w, $c) = @_;
  if ($#_ > 0 ){
    $w->{BG_LABEL_COLOR} = $c;
    _configure_labels($w);
  } else {
    return $w->{BG_LABEL_COLOR};
  }
  return;
} # }}}

sub fg_sel_color { # {{{
  my ($w, $c) = @_;
  if ($#_ > 0 ){
    $w->{FG_SEL_COLOR} = $c;
  } else {
    return $w->{FG_SEL_COLOR};
  }
  return;
} # }}}

sub bg_sel_color { # {{{
  my ($w, $c) = @_;
  if ($#_ > 0 ){
    $w->{BG_SEL_COLOR} = $c;
  } else {
    return $w->{BG_SEL_COLOR};
  }
  return;
} # }}}

sub date{ #{{{ -----------------------------------------------------

=head2 my ($year, $month, $day) = $minical->date()

Returns the selected date from Tk::MaxiCalendar.
Day and month numbers are always two digits (with leading zeroes).

=cut

  my ($w) = @_;
  my $yyyy = sprintf("%4d",  $w->{SEL_YEAR});
  my $mm   = sprintf("%02d", $w->{SEL_MONTH});
  my $dd   = sprintf("%02d", $w->{SEL_DAY});
  return ($yyyy, $mm, $dd);
} # date }}}

sub select_date {    #{{{ ----------------------------------------------

=head2 $minical->select_date($year, $month, $day)

Selects a date and positions the MaxiCalendar to the corresponding
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
    }
    else {
        croak "Error in date: $yyyy, $mm, $dd";
    }
    return;
}    # select_date }}}

sub display_month {    #{{{ --------------------------------------------

=head2 $minical->display_month($year, $month)

Displays the specified month. When a callback for the
E<lt>Display-MonthE<gt> event has been registered it will be called
with ($year, $month, 1) as parameters.

=cut

    my ( $w, $yyyy, $mm ) = @_;

    croak "error in date:  $mm, $yyyy" unless check_date( $yyyy, $mm, 1 );

    $w->{YEAR}     = $yyyy;
    $w->{YEAR_BAK} = $yyyy;
    $w->{MONTH}    = $mm;

    $w->{mtxt} = $w->{MONNAME}[ $mm - 1 ];

    my $day = " ";
    my $dim = Days_in_Month( $yyyy, $mm );
    my $dow = Day_of_Week( $yyyy, $mm, 1 );
    for ( my $i = 0 ; $i < 6 ; $i++ ) {
        for ( my $j = 0 ; $j < 7 ; $j++ ) {

            # Set $day to 1 if the first day reaches the correct day
            # of the week for the first day of the month
            $day = 1 if $day eq " " and $i == 0 and $j + 1 == $dow;
            $w->{MON_ARR}->[$i][$j]->configure(
                -text       => $day,
                -background => $w->{BG_COLOR},
                -foreground => $w->{FG_COLOR},
            );
            if ( $day =~ /\d/ ) {
                $w->{FRM_ARR}->[$i][$j]{lfb}->packForget();
                $w->{FRM_ARR}->[$i][$j]{efb}->pack();
            }
            else {
                $w->{FRM_ARR}->[$i][$j]{lfb}->pack();
                $w->{FRM_ARR}->[$i][$j]{efb}->packForget();
                $w->{MON_ARR}->[$i][$j]->configure(
                    -background => $w->{bg} );
            }

            $day++ if $day ne " ";
            $day = " " if $day =~ /\d/ and $day > $dim;
        }
    }

    # callback if defined:
    $w->{CALLBACK}->{'<Display-Month>'}( $yyyy, $mm, 1 )
      if defined $w->{CALLBACK}->{'<Display-Month>'};

    # if current month contains selected day: hilight it
    _select_day( $w, $w->{SEL_YEAR}, $w->{SEL_MONTH}, $w->{SEL_DAY},
        $w->{BG_SEL_COLOR}, $w->{FG_SEL_COLOR} );

    return;
}    # display_month }}}

# Internal methods

sub hilight { # {{{

=head2 $minical->hilight($year, $month, $day, $background, $foreground)

This method can be used to hilight the specified day with different background/foreground colors.
May be used in a callback for the E<lt>Display-MonthE<gt> event.

=cut

  my ($w, $yyyy, $mm, $dd, $bg, $fg) = @_;
  _select_day($w, $yyyy, $mm, $dd, $bg, $fg);
  return;
} # hilight }}}

sub _select_day { # {{{
  my ($w, $yyyy, $mm, $dd, $bg, $fg) = @_;
 #print $w, "\n";
  return if $yyyy != $w->{YEAR};
  return if $mm   != $w->{MONTH};

  # current year and month contains day which must be hilighted
  my $dow = Day_of_Week($yyyy, $mm, 1); # first day in month ...
  my $pos = $dow -2 + $dd;  # position (index) of $dd in linear mode
  #        +--- $dow -1   ($dow == 3)
  #        |
  #        v
  #  0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 .... (indices in linear mode)
  #  Mo Di Mi Do Fr Sa So Mo Di Mi Do Fr Sa So Mo Di Mi Do Fr Sa So ...
  #        1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 ...
  #                                ^
  #                                |
  #                         $dd ---+
  #
  # Example: Do, 9 has linear index 10, i. e. $dow -2 + 9
  # $pos determines $i and $j:
  #
  my $i = int($pos / 7);
  my $j = $pos % 7;
# print " yyyy: $yyyy  mm: $mm  dd: $dd   dow: $dow\npos: $pos, i: $i, j: $j\n";
  $w->{MON_ARR}->[$i][$j]->configure(
    -background => $bg,
    -foreground => $fg,
  );
  return;
} # _select_day }}}

sub _sel { #{{{
  my ($w, $i, $j) = @_;
  $w->{SEL_YEAR} = $w->{YEAR};
  $w->{SEL_MONTH} = $w->{MONTH};
  my $dow = Day_of_Week($w->{YEAR}, $w->{MONTH}, 1);
  my $pos = $i*7 + $j + 2 - $dow;
#print "i: $i, j: $j  --> pos: $pos\n";
  return if $pos < 1;
  return if $pos > Days_in_Month($w->{YEAR}, $w->{MONTH});
  croak "error in selected date: ", $w->{SEL_YEAR}, ", ", $w->{SEL_MONTH}, ", ", $pos
    unless check_date($w->{SEL_YEAR}, $w->{SEL_MONTH}, $pos);
  $w->{SEL_DAY} = $pos; # ok to use it ...

  display_month($w,  $w->{YEAR}, $w->{MONTH});
  $w->{CALLBACK}->{'<Button-1>'}($w->{SEL_YEAR}, $w->{SEL_MONTH}, $w->{SEL_DAY}) if defined $w->{CALLBACK}->{'<Button-1>'};
  return;
} # _sel }}}

sub _configure_labels { # {{{

  my ($w) = @_;
  for (my $i=0; $i< 7; $i++) {

    $w->{LABELS}->[$i]->configure(
        -background => $w->{BG_LABEL_COLOR},
        -foreground => $w->{FG_LABEL_COLOR},
      );
  }
  return;
} # _configure_labels }}}

# Event Handling: {{{
#
sub register {# {{{
  my ($w, $event, $coderef) = @_;
  $w->{CALLBACK}->{$event} = $coderef;

  return;
} # register }}}

# check, if $i, $j position is a valid date {{{
sub _check_i_j {
  my ($w, $i, $j) = @_;
  my $dow = Day_of_Week($w->{YEAR}, $w->{MONTH}, 1);
  my $pos = $i*7 + $j + 2 - $dow;
  if ($pos > 0 and $pos <= Days_in_Month($w->{YEAR}, $w->{MONTH})) {
    return ($w->{YEAR}, $w->{MONTH}, $pos);
  } else {
    return (undef, undef, undef);
  }
} # _check_i_j }}}
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

 vim:foldmethod=marker:foldcolumn=4
