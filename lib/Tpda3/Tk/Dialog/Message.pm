package Tpda3::Tk::Dialog::Message;

use strict;
use warnings;
use utf8;

use Tk::DialogBox;

=head1 NAME

Tpda3::Tk::Dialog::Message - Dialog for messages.

=head1 VERSION

Version 0.52

=cut

our $VERSION = 0.52;

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Message;

    my $fd = Tpda3::Tk::Dialog::Message->new;

    $fd->search($self);

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my ($class, $opts, $no_cancel) = @_;

    my $self = {
        dialog    => $opts,
        no_cancel => $no_cancel,
    };

    bless( $self, $class );

    return $self;
}

=head2 search_dialog

Define and show message dialog.  MsgBox doesn't allow to change the
button labels.

=cut

sub message_dialog {
    my ( $self, $view, $message, $details ) = @_;

    my $title    = $self->{dialog}{title};
    my $b_yes    = $self->{dialog}{b_yes};
    my $b_cancel = $self->{dialog}{b_cancel};
    my $b_no     = $self->{dialog}{b_no};

    #--- Dialog Box

    # # Make all buttons same width
    # my $len = max map { length } ($b_yes, $b_cancel, $b_no);
    # my $len_l = int($len / 2);
    # my $len_r = $len - $len_l;
    # $padded = sprintf("%*s", $len_l, $text);
    # $padded = sprintf("%-*s", $len_r, $text);

    my $buttons = $self->{no_cancel}
                ? [ $b_yes, $b_no ]
                : [ $b_yes, $b_cancel, $b_no ]
                ;

    my $dlg = $view->DialogBox(
        -title   => 'Dialog',
        -buttons => $buttons,
    );

    #--- Frame top

    my $frame_top = $dlg->Frame(
    )->pack(
        -expand => 1,
        -fill   => 'x',
    );

    my $frame_top_left = $frame_top->Frame()->pack(
        -side   => 'left',
        -expand => 0,
        -fill   => 'x',
        -anchor => 'w',
        -padx   => 5,
        -pady   => 10,
    );

    my $frame_top_right = $frame_top->Frame()->pack(
        -side   => 'right',
        -expand => 1,
        -fill   => 'x',
        -anchor => 'e',
        -padx   => 5,
        -pady   => 10,
    );

    my $mid_frame = $dlg->Frame(
    )->pack(
        -expand => 1,
        -fill   => 'both',
    );

    #-- icon

    my $bg = $frame_top_left->cget(-background);
    my $w_bitmap = $frame_top_left->Canvas(
        Name                => "bitmap",
        -width              => 32,
        -height             => 32,
        -highlightthickness => 0,
        -background         => $bg,
    )->pack;

    $self->make_icon($view, $w_bitmap, 'info');

    #-- title (optional)

    my $ltitle = $frame_top_right->Label( -text => $title )
        ->pack( -anchor => 'se', );

    #-- label

    my $lmessage = $mid_frame->Label( -text => $message )->pack;
    my $ldetails = $mid_frame->Label( -text => $details )->pack;

    #---

    my $result = $dlg->Show;
    my $answer
        # button label                answer
        = $result =~ /^$b_yes$/i    ? q{yes}
        : $result =~ /^$b_no$/i     ? q{no}
        : $result =~ /^$b_cancel$/i ? q{cancel}
        :                             undef # default
        ;

    return $answer;
}

=head2 make_icon

From:

 msgbox.tcl --

    Implements messageboxes for platforms that do not have native
    messagebox support.

 RCS: @(#) $Id: msgbox.tcl,v 1.30 2006/01/25 18:22:04 dgp Exp $

 Copyright (c) 1994-1997 Sun Microsystems, Inc.

 See the file "license.terms" for information on usage and redistribution
 of this file, and for a DISCLAIMER OF ALL WARRANTIES.


 Translated to Perl/Tk by Slaven Rezic

 Version: 4.002

=cut

sub make_icon {
    my ( $self, $view, $w_bitmap, $icon ) = @_;

    my %image;

    $image{b1}{$view} = $view->Bitmap(
        -foreground => 'black',
        -data       => "#define b1_width 32\n#define b1_height 32
static unsigned char q1_bits[] = {
   0x00, 0xf8, 0x1f, 0x00, 0x00, 0x07, 0xe0, 0x00, 0xc0, 0x00, 0x00, 0x03,
   0x20, 0x00, 0x00, 0x04, 0x10, 0x00, 0x00, 0x08, 0x08, 0x00, 0x00, 0x10,
   0x04, 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x40, 0x02, 0x00, 0x00, 0x40,
   0x01, 0x00, 0x00, 0x80, 0x01, 0x00, 0x00, 0x80, 0x01, 0x00, 0x00, 0x80,
   0x01, 0x00, 0x00, 0x80, 0x01, 0x00, 0x00, 0x80, 0x01, 0x00, 0x00, 0x80,
   0x01, 0x00, 0x00, 0x80, 0x02, 0x00, 0x00, 0x40, 0x02, 0x00, 0x00, 0x40,
   0x04, 0x00, 0x00, 0x20, 0x08, 0x00, 0x00, 0x10, 0x10, 0x00, 0x00, 0x08,
   0x60, 0x00, 0x00, 0x04, 0x80, 0x03, 0x80, 0x03, 0x00, 0x0c, 0x78, 0x00,
   0x00, 0x30, 0x04, 0x00, 0x00, 0x40, 0x04, 0x00, 0x00, 0x40, 0x04, 0x00,
   0x00, 0x80, 0x04, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x06, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};"
    );

    $image{b2}{$view} = $view->Bitmap(
        -foreground => 'white',
        -data       => "#define b2_width 32\n#define b2_height 32
static unsigned char b2_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x1f, 0x00, 0x00, 0xff, 0xff, 0x00,
   0xc0, 0xff, 0xff, 0x03, 0xe0, 0xff, 0xff, 0x07, 0xf0, 0xff, 0xff, 0x0f,
   0xf8, 0xff, 0xff, 0x1f, 0xfc, 0xff, 0xff, 0x3f, 0xfc, 0xff, 0xff, 0x3f,
   0xfe, 0xff, 0xff, 0x7f, 0xfe, 0xff, 0xff, 0x7f, 0xfe, 0xff, 0xff, 0x7f,
   0xfe, 0xff, 0xff, 0x7f, 0xfe, 0xff, 0xff, 0x7f, 0xfe, 0xff, 0xff, 0x7f,
   0xfe, 0xff, 0xff, 0x7f, 0xfc, 0xff, 0xff, 0x3f, 0xfc, 0xff, 0xff, 0x3f,
   0xf8, 0xff, 0xff, 0x1f, 0xf0, 0xff, 0xff, 0x0f, 0xe0, 0xff, 0xff, 0x07,
   0x80, 0xff, 0xff, 0x03, 0x00, 0xfc, 0x7f, 0x00, 0x00, 0xf0, 0x07, 0x00,
   0x00, 0xc0, 0x03, 0x00, 0x00, 0x80, 0x03, 0x00, 0x00, 0x80, 0x03, 0x00,
   0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};"
    );

    $image{'q'}{$view} = $view->Bitmap(
        -foreground => 'blue',
        -data       => "#define q_width 32\n#define q_height 32
static unsigned char q_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x07, 0x00,
   0x00, 0x10, 0x0f, 0x00, 0x00, 0x18, 0x1e, 0x00, 0x00, 0x38, 0x1e, 0x00,
   0x00, 0x38, 0x1e, 0x00, 0x00, 0x10, 0x0f, 0x00, 0x00, 0x80, 0x07, 0x00,
   0x00, 0xc0, 0x01, 0x00, 0x00, 0xc0, 0x00, 0x00, 0x00, 0xc0, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0xc0, 0x00, 0x00, 0x00, 0xe0, 0x01, 0x00,
   0x00, 0xe0, 0x01, 0x00, 0x00, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};"
    );

    $image{'i'}{$view} = $view->Bitmap(
        -foreground => 'blue',
        -data       => "#define i_width 32\n#define i_height 32
static unsigned char i_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0xe0, 0x01, 0x00, 0x00, 0xf0, 0x03, 0x00, 0x00, 0xf0, 0x03, 0x00,
   0x00, 0xe0, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0xf8, 0x03, 0x00, 0x00, 0xf0, 0x03, 0x00, 0x00, 0xe0, 0x03, 0x00,
   0x00, 0xe0, 0x03, 0x00, 0x00, 0xe0, 0x03, 0x00, 0x00, 0xe0, 0x03, 0x00,
   0x00, 0xe0, 0x03, 0x00, 0x00, 0xe0, 0x03, 0x00, 0x00, 0xf0, 0x07, 0x00,
   0x00, 0xf8, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};"
    );

    $image{'w1'}{$view} = $view->Bitmap(
        -foreground => 'black',
        -data       => "#define w1_width 32\n#define w1_height 32
static unsigned char w1_bits[] = {
   0x00, 0x80, 0x01, 0x00, 0x00, 0x40, 0x02, 0x00, 0x00, 0x20, 0x04, 0x00,
   0x00, 0x10, 0x04, 0x00, 0x00, 0x10, 0x08, 0x00, 0x00, 0x08, 0x08, 0x00,
   0x00, 0x08, 0x10, 0x00, 0x00, 0x04, 0x10, 0x00, 0x00, 0x04, 0x20, 0x00,
   0x00, 0x02, 0x20, 0x00, 0x00, 0x02, 0x40, 0x00, 0x00, 0x01, 0x40, 0x00,
   0x00, 0x01, 0x80, 0x00, 0x80, 0x00, 0x80, 0x00, 0x80, 0x00, 0x00, 0x01,
   0x40, 0x00, 0x00, 0x01, 0x40, 0x00, 0x00, 0x02, 0x20, 0x00, 0x00, 0x02,
   0x20, 0x00, 0x00, 0x04, 0x10, 0x00, 0x00, 0x04, 0x10, 0x00, 0x00, 0x08,
   0x08, 0x00, 0x00, 0x08, 0x08, 0x00, 0x00, 0x10, 0x04, 0x00, 0x00, 0x10,
   0x04, 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x20, 0x01, 0x00, 0x00, 0x40,
   0x01, 0x00, 0x00, 0x40, 0x01, 0x00, 0x00, 0x40, 0x02, 0x00, 0x00, 0x20,
   0xfc, 0xff, 0xff, 0x1f, 0x00, 0x00, 0x00, 0x00};"
    );

    $image{'w2'}{$view} = $view->Bitmap(
        -foreground => 'yellow',
        -data       => "#define w2_width 32\n#define w2_height 32
static unsigned char w2_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x01, 0x00, 0x00, 0xc0, 0x03, 0x00,
   0x00, 0xe0, 0x03, 0x00, 0x00, 0xe0, 0x07, 0x00, 0x00, 0xf0, 0x07, 0x00,
   0x00, 0xf0, 0x0f, 0x00, 0x00, 0xf8, 0x0f, 0x00, 0x00, 0xf8, 0x1f, 0x00,
   0x00, 0xfc, 0x1f, 0x00, 0x00, 0xfc, 0x3f, 0x00, 0x00, 0xfe, 0x3f, 0x00,
   0x00, 0xfe, 0x7f, 0x00, 0x00, 0xff, 0x7f, 0x00, 0x00, 0xff, 0xff, 0x00,
   0x80, 0xff, 0xff, 0x00, 0x80, 0xff, 0xff, 0x01, 0xc0, 0xff, 0xff, 0x01,
   0xc0, 0xff, 0xff, 0x03, 0xe0, 0xff, 0xff, 0x03, 0xe0, 0xff, 0xff, 0x07,
   0xf0, 0xff, 0xff, 0x07, 0xf0, 0xff, 0xff, 0x0f, 0xf8, 0xff, 0xff, 0x0f,
   0xf8, 0xff, 0xff, 0x1f, 0xfc, 0xff, 0xff, 0x1f, 0xfe, 0xff, 0xff, 0x3f,
   0xfe, 0xff, 0xff, 0x3f, 0xfe, 0xff, 0xff, 0x3f, 0xfc, 0xff, 0xff, 0x1f,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};"
    );

    $image{'w3'}{$view} = $view->Bitmap(
        -foreground => 'black',
        -data       => "#define w3_width 32\n#define w3_height 32
static unsigned char w3_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0xc0, 0x03, 0x00, 0x00, 0xe0, 0x07, 0x00, 0x00, 0xe0, 0x07, 0x00,
   0x00, 0xe0, 0x07, 0x00, 0x00, 0xe0, 0x07, 0x00, 0x00, 0xe0, 0x07, 0x00,
   0x00, 0xc0, 0x03, 0x00, 0x00, 0xc0, 0x03, 0x00, 0x00, 0xc0, 0x03, 0x00,
   0x00, 0x80, 0x01, 0x00, 0x00, 0x80, 0x01, 0x00, 0x00, 0x80, 0x01, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x01, 0x00, 0x00, 0xc0, 0x03, 0x00,
   0x00, 0xc0, 0x03, 0x00, 0x00, 0x80, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};"
    );

    if ( $icon eq 'error' ) {
        $w_bitmap->create(qw(oval 0 0 31 31 -fill red -outline black));
        $w_bitmap->create(qw(line 9 9 23 23 -fill white -width 4));
        $w_bitmap->create(qw(line 9 23 23 9 -fill white -width 4));
    }
    elsif ( $icon eq 'info' ) {
        $w_bitmap->create( qw(image 0 0 -anchor nw),
            -image => $image{b1}{$view} );
        $w_bitmap->create( qw(image 0 0 -anchor nw),
            -image => $image{b2}{$view} );
        $w_bitmap->create( qw(image 0 0 -anchor nw),
            -image => $image{i}{$view} );
    }
    elsif ( $icon eq 'question' ) {
        $w_bitmap->create( qw(image 0 0 -anchor nw),
            -image => $image{b1}{$view} );
        $w_bitmap->create( qw(image 0 0 -anchor nw),
            -image => $image{b2}{$view} );
        $w_bitmap->create( qw(image 0 0 -anchor nw),
            -image => $image{'q'}{$view} );
    }
    else {
        $w_bitmap->create( qw(image 0 0 -anchor nw),
            -image => $image{w1}{$view} );
        $w_bitmap->create( qw(image 0 0 -anchor nw),
            -image => $image{w2}{$view} );
        $w_bitmap->create( qw(image 0 0 -anchor nw),
            -image => $image{w3}{$view} );
    }
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Tk::Dialog::Message
