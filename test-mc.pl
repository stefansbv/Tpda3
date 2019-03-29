#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Tk;

use Tpda3::Tk::MaxiCalendar;

my $top = MainWindow->new;

my $frm1 = $top->Frame->pack;  # Frame to place MaxiCalendar in

my $minical = $frm1->MaxiCalendar->pack;

$minical->select_date(2019, 9, 1);

my $frm2 = $top->Frame->pack;    # Frame for Ok Button
my $b_ok = $frm2->Button(
    -text    => "Ok",
    -command => sub {
        my ( $year, $month, $day ) = $minical->date;
        print "Selected date: $year-$month-$day\n";
        exit;
    },
)->pack;

MainLoop;
