#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Data::Dump; 

use Tk;

use Tpda3::Tk::EntryCalendar;

my $top = MainWindow->new;

my $frm1 = $top->Frame->pack;  # Frame to place EntryCalendar in

my $minical = $frm1->EntryCalendar(
    # -bg_label_color => 'thistle4',
    # -fg_label_color => 'thistle1',
    -bg_sel_color   => 'grey95',
    -fg_sel_color   => 'black',
    # -bg_color       => 'gray95',
    # -fg_color       => 'green',
    # -bg_wkday_color => 'blue',
    # -fg_wkday_color => 'blue',
    # -bg_wkend_color => 'blue',
    # -fg_wkend_color => 'blue',
)->pack;

$minical->select_date(2019, 9, 1);

my $frm2 = $top->Frame->pack;    # Frame for Ok Button
my $b_ok = $frm2->Button(
    -text    => "Ok",
    -command => sub {
        my ( $year, $month, $day ) = $minical->date;
        print "Selected date: $year-$month-$day\n";
        my $eary = $minical->dump_entry();
        my $poz = 0;
        foreach my $ez ( @{$eary} ) {
            print "$poz: ", $ez->get, "\n";
            $poz++;
        }
        # dd $eary;
        exit;
    },
)->pack;

MainLoop;
