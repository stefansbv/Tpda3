#!/usr/bin/perl

package TableFrame;

use strict;
use warnings;
use Carp;

use Wx qw[:everything];
use base qw(Wx::Frame);

use lib 'lib';

use Tpda3::Wx::Grid;

sub new {

    my $self = shift;

    $self = $self->SUPER::new(
        undef, -1, 'Table demo',
        [ -1, -1 ],
        [ -1, -1 ],
        wxDEFAULT_FRAME_STYLE,
    );

    Wx::InitAllImageHandlers();

    #- Grid Sizer

    my $panel = Wx::Panel->new($self);

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);

    my $table = Tpda3::Wx::Grid->new($panel);

    $sizer->Add($table, 1, wxEXPAND, 5 );

    $panel->SetSizerAndFit($sizer);

    return $self;
}

1;

package TableApp;

use base 'Wx::App';

sub OnInit {

    my $frame = TableFrame->new();

    $frame->Show( 1 );
}

package main;

use strict;
use warnings;

my $app = TableApp->new();

$app->MainLoop;

1;
