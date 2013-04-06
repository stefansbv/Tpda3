#!/bin/env perl
#
# Inspired from the test of the Wx-Scintilla module,
# Copyright (C) 2011 Ahmad M. Zawawi
#
use strict;
use warnings;

use Test::More;

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }

    eval { require Wx; };
    if ($@) {
        plan( skip_all => 'wxPerl is required for this test' );
    }
    else {
        plan tests => 17;
    }
}

package MyTimer;

use Wx qw(:everything);
use Wx::Event;

use vars qw(@ISA); @ISA = qw(Wx::Timer);

sub Notify {
    my $self  = shift;
    my $frame = Wx::wxTheApp()->GetTopWindow;
    $frame->Destroy;
    main::ok( 1, "Timer works.. Destroyed the frame!" );
}

package TestApp;

use strict;
use warnings;

use Wx qw(:everything);
use Wx::Event;
use base 'Wx::App';

use Tpda3::Wx::ComboBox;

my $choices = [
    {   '-name'  => 'Cancelled',
        '-value' => 'C'
    },
    {   '-name'  => 'Disputed',
        '-value' => 'D'
    },
    {   '-name'  => 'In Process',
        '-value' => 'P'
    },
    {   '-name'  => 'On Hold',
        '-value' => 'H'
    },
    {   '-name'  => 'Resolved',
        '-value' => 'R'
    },
    {   '-name'  => 'Shipped',
        '-value' => 'S'
    }
];

# We must override OnInit to build the window
sub OnInit {
    my $self = shift;

    my $frame = $self->{frame} = Wx::Frame->new(
        undef,                        # no parent window
        -1,                           # no window id
        'Test!',                      # Window title
    );

    my $cb = Tpda3::Wx::ComboBox->new(
        $frame,
        -1,
        q{},
        [-1, -1], [-1, -1],
        [],
        wxCB_SORT | wxTE_PROCESS_ENTER,
    );

    main::ok( $cb, 'ComboBox instance created' );

    main::is( $cb->add_choices($choices), undef, 'Add choices' );

    foreach my $choice ( @{$choices} ) {
        my $name  = $choice->{-name};
        my $value = $choice->{-value};
        #main::diag("Testing with '$name' = '$value'");
        main::is( $cb->set_selected($value), undef,  "Set selected '$value'" );
        main::is( $cb->get_selected(),       $value, "Get selected '$value'" );
    }

    # Uncomment this to observe the test
    # $frame->Show(1);

    MyTimer->new->Start( 500, 1 );

    return 1;
}

# Create the application object, and pass control to it.
package main;
my $app = TestApp->new;
$app->MainLoop;
