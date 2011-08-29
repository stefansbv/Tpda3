package Tpda3::Tk::App::Test::WidgetsAll;

use strict;
use warnings;
use utf8;

use Tk::widgets qw(DateEntry JComboBox RadiobuttonGroup);

use base q{Tpda3::Tk::Screen};

use POSIX qw (strftime);
use Date::Calc qw(check_date);

=head1 NAME

Tpda3::App::Test::WidgetsAll screen

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    require Tpda3::App::Test::WidgetsAll;

    my $scr = Tpda3::App::Test::WidgetsAll->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $inreg_p ) = @_;

    my $gui    = $inreg_p->toplevel;
    my $main_p = $inreg_p->parent;
    $self->{bg} = $gui->cget('-background');

    # # For DateEntry day names
    # my @daynames = ();
    # foreach ( 0 .. 6 ) {
    #     push @daynames, strftime( "%a", 0, 0, 0, 1, 1, 1, $_ );
    # }

    #-- Frame 1

    my $frame1 = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Date personale',
        -labelside  => 'acrosstop'
    );
    $frame1->grid(
        $frame1,
        -row        => 0,
        -column     => 0,
        -ipadx      => 3,
        -sticky     => 'nsew',
        -columnspan => 2,
    );

    my $f1d = 110;    # distance from left

    # id_pers (id_pers)
    my $lid_pers = $frame1->Label( -text => 'Identificator' );
    $lid_pers->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 5,
    );

    my $eid_pers = $frame1->Entry(
        -width              => 6,
        -disabledbackground => 'lightgrey',
        -disabledforeground => 'black'
    );
    $eid_pers->form(
        -top  => [ '&', $lid_pers, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-+ cnp

    my $ecnp = $frame1->Entry( -width => 13, );
    $ecnp->form(
        -top   => [ '&',  $lid_pers, 0 ],
        -right => [ %100, -5 ],
    );
    my $lcnp = $frame1->Label( -text => 'CNP', );
    $lcnp->form(
        -top     => [ '&',   $lid_pers, 0 ],
        -right   => [ $ecnp, -10 ],
        -padleft => 5,
    );

    #-- Nume (nume)

    my $lnume = $frame1->Label( -text => 'Nume' );
    $lnume->form(
        -top     => [ $lid_pers, 8 ],
        -left    => [ %0,        0 ],
        -padleft => 5,
    );
    my $enume = $frame1->Entry( -width => 18, );
    $enume->form(
        -top  => [ '&', $lnume, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-+ prenume

    my $eprenume = $frame1->Entry( -width => 25, );
    $eprenume->form(
        -top   => [ '&',  $lnume, 0 ],
        -right => [ %100, -5 ],
    );
    my $lprenume = $frame1->Label( -text => 'Prenume', );
    $lprenume->form(
        -top     => [ '&',       $lnume, 0 ],
        -right   => [ $eprenume, -10 ],
        -padleft => 5,
    );

    #-- Data nasterii

    my $vdata_nas;
    my $ldata_nas = $frame1->Label( -text => 'Data nașterii', );
    $ldata_nas->form(
        -top     => [ $lnume, 8 ],
        -left    => [ %0,     0 ],
        -padleft => 5,
    );
    my $ddata_nas = $frame1->DateEntry(

        # -daynames   => \@daynames,
        -variable   => \$vdata_nas,
        -arrowimage => 'calmonth16',
        -parsecmd   => sub {
            my ( $y, $m, $d ) = ( $_[0] =~ m/(\d*)\-(\d*)\-(\d*)/ );
            return ( $y, $m, $d );
        },
        -formatcmd => sub {
            sprintf( "%04d\-%02d\-%02d", $_[0], $_[1], $_[2] );
        },
        -todaybackground => 'lightgreen',
    );
    $ddata_nas->form(
        -top  => [ '&', $ldata_nas, 0 ],
        -left => [ %0,  $f1d ],
    );

    my $my_font = $enume->cget('-font');    # font

    #-- Localitate domiciliu stabil

    my $lloc_ds = $frame1->Label( -text => 'Localitate' );
    $lloc_ds->form(
        -top     => [ $ldata_nas, 8 ],
        -left    => [ %0,         0 ],
        -padleft => 5
    );

    my $eloc_ds = $frame1->Entry( -width => 30, );
    my ( $eid_jud_ds, $ecod_p_ds );
    $eloc_ds->form(
        -top  => [ '&', $lloc_ds, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-+ id_jud_ds

    $eid_jud_ds = $frame1->Entry(
        -width              => 3,
        -disabledbackground => 'lightgrey',
        -disabledforeground => 'black',

    );
    $eid_jud_ds->form(
        -top  => [ '&',      $lloc_ds, 0 ],
        -left => [ $eloc_ds, 6 ]
    );

    #-+ cod_p_ds (Cod postal localitate domiciliu stabil)

    $ecod_p_ds = $frame1->Entry(
        -width              => 6,
        -disabledbackground => 'lightgrey',
        -disabledforeground => 'black'
    );
    $ecod_p_ds->form(
        -top  => [ '&',         $lloc_ds, 0 ],
        -left => [ $eid_jud_ds, 5 ]
    );

    #-+ id_loc_ds

    my $eid_loc_ds = $frame1->Entry(
        -width              => 5,
        -disabledbackground => 'lightgrey',
        -disabledforeground => 'black'
    );
    $eid_loc_ds->form(
        -top  => [ '&',        $lloc_ds, 0 ],
        -left => [ $ecod_p_ds, 5 ],
    );

    #-- Judet (judet)

    my $ljudet = $frame1->Label( -text => 'Judet', );
    $ljudet->form(
        -left    => [ %0,       0 ],
        -top     => [ $lloc_ds, 8 ],
        -padleft => 5,
    );

    my $ejudet = $frame1->Entry( -width => 25, );
    $ejudet->form(
        -top  => [ '&', $ljudet, 0 ],
        -left => [ %0,  80 ],
    );

    #-- id_judet (SMALLINT)

    my $eid_judet = $frame1->Entry(
        -width              => 3,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black'
    );
    $eid_judet->form(
        -top  => [ '&',     $ljudet, 0 ],
        -left => [ $ejudet, 6 ],
    );

    #-- Adresa (adresa)

    my $ladresa = $frame1->Label( -text => 'Adresă' );
    $ladresa->form(
        -top     => [ $ljudet, 10 ],
        -left    => [ %0,      0 ],
        -padleft => 5
    );

    my $tadresa = $frame1->Scrolled(
        'Text',
        -width      => 60,
        -height     => 3,
        -wrap       => 'word',
        -scrollbars => 'e',
        -font       => $my_font
    );

    $tadresa->form(
        -top  => [ '&', $ladresa, 0 ],
        -left => [ %0,  $f1d ],
    );

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'persoane.conf'
    $self->{controls} = {
        id_pers   => [ undef,       $eid_pers ],
        cnp       => [ undef,       $ecnp ],
        nume      => [ undef,       $enume ],
        prenume   => [ undef,       $eprenume ],
        data_nas  => [ \$vdata_nas, $ddata_nas ],
        loc_ds    => [ undef,       $eloc_ds ],
        id_jud_ds => [ undef,       $eid_jud_ds ],
        cod_p_ds  => [ undef,       $ecod_p_ds ],
        id_loc_ds => [ undef,       $eid_loc_ds ],
        judet     => [ undef,       $ejudet ],
        id_judet  => [ undef,       $eid_judet ],
        adresa    => [ undef,       $tadresa ],
    };

    # Required fields: fld_name => [#, Label] If there is no value in
    # the screen for this fields show a dialog message
    $self->{fld_label} = {
        cnp     => [ 0, '  CNP' ],
        nume    => [ 1, '  Nume' ],
        prenume => [ 2, '  Prenume' ],
        adresa  => [ 4, '  Adresa' ],
        gen     => [ 5, '  Gen' ],
    };

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Tk::App::Test::WidgetsAll
