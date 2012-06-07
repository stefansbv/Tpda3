package Tpda3::Tk::Dialog::Configs;

use strict;
use warnings;

use Tk;
use Tk::FontDialog;

=head1 NAME

Tpda3::Tk::Dialog::Configs - Dialog for user configuration options

=head1 VERSION

Version 0.53

=cut

our $VERSION = 0.53;

=head1 SYNOPSIS

Set and save configuaration options.

    use Tpda3::Tk::Dialog::Configs;

    my $fd = Tpda3::Tk::Dialog::Configs->new;

    $fd->run_dialog($self);

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my $class = shift;

    return bless {}, $class;
}

=head2 run_dialog

Show dialog

=cut

sub run_dialog {
    my ( $self, $mw ) = @_;

    $self->{tlw} = $mw->Toplevel();
    $self->{tlw}->title('Configs');
    $self->{bg} = $mw->cget('-background');

    # Frame
    my $frame1 = $self->{tlw}->LabFrame(
        -foreground => 'blue',
        -label      => 'Font',
        -labelside  => 'acrosstop',
    );
    $frame1->grid(
        $frame1,
        -row    => 0,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'nsew',
    );

    #- Font

    my $lfont = $frame1->Label( -text => 'Current font name' );
    $lfont->form(
        -left => [ %0, 0 ],
        -top  => [ %0, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $efont = $frame1->Entry(
        -width              => 25,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $efont->form(
        -top  => [ $lfont, 0 ],
        -left => [ %0,     10 ],
    );

    #- Limit

    my $llimit
        = $frame1->Label( -text => 'Limit number of records in list to', );
    $llimit->form(
        -left => [ %0,     0 ],
        -top  => [ $efont, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $elimit = $frame1->Entry(
        -width              => 8,
        -justify            => 'right',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $elimit->form(
        -top  => [ $llimit, 0 ],
        -left => [ %0,      10 ],
    );

    #- Font button
    my $fontb1 = $frame1->Button(
        -text    => 'Sele',
        -width   => 4,
        -command => sub {
            $self->dialog_show($mw);
        },
    );

    $fontb1->form(
        -top  => [ '&',    $lfont, 0 ],
        -left => [ $efont, 10 ],
    );

    #-- Quit button frame

    # Frame
    my $frame2 = $self->{tlw}->Frame();
    $frame2->grid(
        $frame2,
        -row    => 1,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'nsew',
    );

    my $qb = $frame2->Button(
        -text    => 'Close',
        -width   => 8,
        -command => sub {
            $self->dialog_quit;
        },
    )->pack( -side => 'top' );

    return;
}

=head2 dialog_show

Show font dialog

=cut

sub dialog_show {
    my ( $self, $mw ) = @_;

    my $fd = $mw->FontDialog(
        -nicefont => 0,

        #-font => $b->cget(-font),
        -title            => 'Font selection',
        -fixedfontsbutton => 1,
        -nicefontsbutton  => 0,

        # -sampletext => $sampletext,
    );

    my $font = $fd->Show;
    if ( defined $font ) {
        my $font_descriptive = $mw->GetDescriptiveFontName($font);
        print $font_descriptive, "\n";

        $mw->RefontTree( -font => $font );
    }

    return;
}

=head2 dialog_quit

Close dialog

=cut

sub dialog_quit {
    my $self = shift;

    $self->{'tlw'}->destroy;

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Tk::Dialog::Configs

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1;    # End of Tpda3::Tk::Dialog::Configs
