#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Data::Dump; 

use Tk;

use lib 'lib';
use Tpda3::Tk::EntryCalendar;

my $top = MainWindow->new;

my $frm1 = $top->Frame->pack;  # Frame to place EntryCalendar in

my $minical = $frm1->EntryCalendar()->pack;

# $minical->select_date(2019, 9, 1);
$minical->move_first_day(+1);

my $frm2 = $top->Frame->pack;    # Frame for Ok Button
my $b_ok = $frm2->Button(
    -text    => "OK",
    -command => sub {
        $minical->move_first_day(+1);
        my ( $year, $month, $day ) = $minical->date;
        print "Selected date: $year-$month-$day\n";
        my $eary = $minical->get_entry_array;
        my $poz = 0;
        foreach my $ez ( @{$eary} ) {
            print "$poz: ", $ez->get, "\n";
            $poz++;
        }
        # dd $eary;
    },
)->pack;

MainLoop;
