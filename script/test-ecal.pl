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

$minical->select_month(2019, 9);
# $minical->move_first_day(+1);

my $frm2 = $top->Frame->pack;    # Frame for Ok Button

$frm2->Button(
    -text    => "<<",
    -command => sub {
        $minical->move_first_day(-1);
        my $eary = $minical->get_label_entry_array;
        my $poz = 0;
        foreach my $ez ( @{$eary} ) {
            print "$poz: ", $ez->[1]->get, "\n";
            $poz++;
        }
        # dd $eary;
        print " index of day #1 = ", $minical->index_of_day(1), "\n";
    },
)->pack(-side => 'left');

$frm2->Button(
    -text    => "Reset",
    -command => sub {
        $minical->reset_places();
    },
)->pack(-side => 'left');

$frm2->Button(
    -text    => ">>",
    -command => sub {
        $minical->move_first_day(+1);
        my $eary = $minical->get_label_entry_array;
        my $poz = 0;
        foreach my $ez ( @{$eary} ) {
            print "$poz: ", $ez->[1]->get, "\n";
            $poz++;
        }
        # dd $eary;
        print " index of day #1 = ", $minical->index_of_day(1), "\n";
    },
)->pack(-side => 'left');

MainLoop;
