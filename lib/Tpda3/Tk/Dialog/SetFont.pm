package Tpda3::Tk::Dialog::SetFont;

use strict;
use warnings;

use Tk;
use Tk::FontDialog;

=head1 NAME

Tpda3::Tk::Dialog::SetFont - The great new Tpda3::Tk::Dialog::SetFont!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Tpda3::Tk::Dialog::SetFont;

    my $foo = Tpda3::Tk::Dialog::SetFont->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

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
    $self->{tlw}->title('Set Font');
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

    # Font
    my $lfont = $frame1->Label( -text => 'Font' );
    $lfont->form(
        -left => [ %0, 0 ],
        -top  => [ %0, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $efont = $frame1->Entry(
        -width => 25,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $efont->form(
        -top  => [ '&', $lfont, 0 ],
        -left => [ %0,  80 ],
    );

    # Font button
    my $fontb1 = $frame1->Button(
        -text => 'Select',
        -width => 10,
        -command => sub {
            $self->dialog_show($mw);
        },
    );

    $fontb1->form(
        -top  => [ '&', $lfont, 0 ],
        -left => [ $efont,  10 ],
    );

    # Quit button
    my $qb = $self->{tlw}->Button(
        -text => 'Close',
        -width => 10,
        -command => sub {
            $self->dialog_quit;
        },
    );

    $qb->grid(
        $qb,
        -row    => 1,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'nsew',
    );

    return;
}

sub dialog_show {
    my ($self, $mw) = @_;

    my $fd = $mw->FontDialog(
        -nicefont => 0,
        #-font => $b->cget(-font),
        -title => 'Font selection',
        -fixedfontsbutton => 1,
        -nicefontsbutton => 0,
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

sub dialog_quit {
    my $self = shift;

    $self->{'tlw'}->destroy;

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users.sourceforge.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tpda3-tk-dialog-setfont at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tpda3-Tk-Dialog-SetFont>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Tk::Dialog::SetFont


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tpda3-Tk-Dialog-SetFont>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tpda3-Tk-Dialog-SetFont>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tpda3-Tk-Dialog-SetFont>

=item * Search CPAN

L<http://search.cpan.org/dist/Tpda3-Tk-Dialog-SetFont/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

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

1; # End of Tpda3::Tk::Dialog::SetFont
