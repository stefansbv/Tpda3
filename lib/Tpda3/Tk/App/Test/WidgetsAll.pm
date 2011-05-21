package Tpda3::Tk::App::Test::WidgetsAll;

use strict;
use warnings;
use utf8;

use Tk::widgets qw(DateEntry JComboBox RadiobuttonGroup);

use base q{Tpda3::Tk::Screen};

use POSIX qw (strftime);
use Date::Calc qw(check_date);

=head1 NAME

Tpda3::App::Fpimm::Localitati screen

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    require Tpda3::App::Fpimm::WidgetsAll;

    my $scr = Tpda3::App::Fpimm::WidgetsAll->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $inreg_p ) = @_;

    my $gui     = $inreg_p->toplevel;
    my $main_p  = $inreg_p->parent;
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
        -row    => 0,
        -column => 0,
        -ipadx  => 3,
        -sticky => 'nsew',
        -columnspan => 2,
    );

    my $f1d = 110;              # distance from left

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
        -left => [ %0, $f1d ],
    );

    #-+ cnp

    my $ecnp = $frame1->Entry(
        -width => 13,
    );
    $ecnp->form(
        -top   => [ '&', $lid_pers, 0 ],
        -right => [ %100, -5 ],
    );
    my $lcnp = $frame1->Label( -text => 'CNP', );
    $lcnp->form(
        -top     => [ '&',   $lid_pers, 0 ],
        -right   => [ $ecnp, -10 ],
        -padleft => 5,
    );

    $ecnp->bind( '<KeyPress-Return>' => sub { $self->cnp_ok(); } );

    #- Nume (nume)

    my $lnume = $frame1->Label( -text => 'Nume' );
    $lnume->form(
        -top  => [ $lid_pers, 8 ],
        -left => [ %0,       0 ],
        -padleft => 5,
    );
    my $enume = $frame1->Entry(
        -width    => 18,
    );
    $enume->form(
        -top  => [ '&', $lnume, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-+ prenume

    my $eprenume = $frame1->Entry(
        -width    => 25,
    );
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

    #-- prenume_t

    my $lprenume_t = $frame1->Label( -text => 'Prenume, tată', );
    $lprenume_t->form(
        -top     => [ $lprenume, 8 ],
        -left    => [ %0,        0 ],
        -padleft => 5,
    );
    my $eprenume_t = $frame1->Entry( -width => 25, );
    $eprenume_t->form(
        -top  => [ '&', $lprenume_t, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-+ prenume_m

    my $eprenume_m = $frame1->Entry( -width => 25, );
    $eprenume_m->form(
        -top   => [ '&',  $lprenume_t, 0 ],
        -right => [ %100, -5 ],
    );
    my $lprenume_m = $frame1->Label( -text => 'Mamă', );
    $lprenume_m->form(
        -top     => [ '&',         $lprenume_t, 0 ],
        -right   => [ $eprenume_m, -10 ],
        -padleft => 5,
    );

    #-- data_nas

    my $vdata_nas;
    my $ldata_nas = $frame1->Label(
        -text => 'Data nașterii',
    );
    $ldata_nas->form(
        -top  => [ $lprenume_m, 8 ],
        -left => [ %0, 0 ],
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
        -left => [ %0, $f1d ],
    );

    my $my_font = $enume->cget('-font');    # font

    #-- localitate - Localitate domiciliu stabil

    my $llocalitate = $frame1->Label( -text => 'Localitate' );
    $llocalitate->form(
        -top     => [ $ldata_nas, 8 ],
        -left    => [ %0,         0 ],
        -padleft => 5
    );

    my $elocalitate = $frame1->Entry(
        -width    => 30,
    );
    my ($eid_judet, $ecod_p);
    $elocalitate->form(
        -top  => [ '&', $llocalitate, 0 ],
        -left => [ %0, $f1d ],
    );

    #-+ id_jud

    $eid_judet = $frame1->Entry(
        -width              => 3,
        -disabledbackground => 'lightgrey',
        -disabledforeground => 'black',

    );
    $eid_judet->form(
        -top  => [ '&',      $llocalitate, 0 ],
        -left => [ $elocalitate, 6 ]
    );

    #-+ cod_p (Cod postal localitate domiciliu stabil)

    $ecod_p = $frame1->Entry(
        -width              => 6,
        -disabledbackground => 'lightgrey',
        -disabledforeground => 'black'
    );
    $ecod_p->form(
        -top  => [ '&',         $llocalitate, 0 ],
        -left => [ $eid_judet, 5 ]
    );

    #-+ id_loc

    my $eid_loc = $frame1->Entry(
        -width              => 5,
        -disabledbackground => 'lightgrey',
        -disabledforeground => 'black'
    );
    $eid_loc->form(
        -top  => [ '&',        $llocalitate, 0 ],
        -left => [ $ecod_p, 5 ],
    );

    #- Adresa (adresa)
    my $ladresa = $frame1->Label( -text => 'Adresă' );
    $ladresa->form(
        -top     => [ $llocalitate, 10 ],
        -left    => [ %0,        0 ],
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
        id_pers    => [ undef,       $eid_pers ],
        cnp        => [ undef,       $ecnp ],
        nume       => [ undef,       $enume ],
        prenume    => [ undef,       $eprenume ],
        prenume_t  => [ undef,       $eprenume_t ],
        prenume_m  => [ undef,       $eprenume_m ],
        data_nas   => [ \$vdata_nas, $ddata_nas ],
        localitate => [ undef,       $elocalitate ],
        cod_p      => [ undef,       $ecod_p ],
        id_judet   => [ undef,       $eid_judet ],
        id_loc     => [ undef,       $eid_loc ],
        adresa     => [ undef,       $tadresa ],
    };

    # Required fields: fld_name => [#, Label] If there is no value in
    # the screen for this fields show a dialog message
    $self->{fld_label} = {
        cnp       => [ 0, '  CNP' ],
        nume      => [ 1, '  Nume' ],
        prenume   => [ 2, '  Prenume' ],
        adresa    => [ 4, '  Adresa' ],
        gen       => [ 5, '  Gen' ],
    };

    return;
}

sub cnp_ok {
    my $self = shift;

    my $cnp = $self->{eobj_rec}{cnp}[3]->get;    # valoare CNP

    return unless ($cnp);

    # Trim spaces to be safe
    $cnp =~ s/^\s+//;
    $cnp =~ s/\s+$//;

    if ( length($cnp) != 13 ) {
        $self->{tpda}{gui}->refresh_sb( 'll', 'CNP Eronat! != 13', 'red');
        print "CNP Eronat!\n";
        return;
    }

    my @cnp = split( //, $cnp );
    my @prd = split( //, '279146358279' );

    # Check first digit
    if ( $cnp[0] < 1 or $cnp[0] > 6 and $cnp[0] != 9 ) {
        $self->{tpda}{gui}->refresh_sb( 'll', 'CNP Eronat!', 'red');
        print " Prima cifra eronata!\n";
        return;
    }
    else {
        # Preset gen
        my $gen;
        $gen = 'Masculin' if $cnp[0] == 1;
        $gen = 'Feminin'  if $cnp[0] == 2;
        ${ $self->{eobj_rec}{gen}[2] } = $gen;
    }


    # Check date
    my $yy    = substr($cnp,1,2);
    my $month = substr($cnp,3,2);
    my $day   = substr($cnp,5,2);

    my $year = "19$yy";                # TODO: algorithm to guess year

    if ( check_date($year,$month,$day) ) {
        my $date = $self->{utils}->dateentry_format_date(
            $self->{dstyle}, $year, $month, $day);
        print "Valid date: $date\n";

        # Preset date
        $self->{eobj_rec}{data_nas}[3]->delete( 0, 'end' );
        $self->{eobj_rec}{data_nas}[3]->insert(0, $date);
    }
    else {
        $self->{tpda}{gui}->refresh_sb( 'll', 'CNP Eronat!', 'red');
        print "Data din CNP Eronata!\n";
        return;
    }

    my $suma = 0;
    foreach ( 0 .. $#prd ) {
        $suma += $cnp[$_] * $prd[$_];
    }

    # print "Suma     = $suma\n";
    my $m11 = $suma % 11;

    # print "Modulo11 = $m11\n";
    # print "CNP(13)  = $cnp[12]\n";

    my $cc;
    if ( $m11 < 10 ) {
        $cc = $m11;
    }
    else {
        if ( $m11 == 10 ) {
            $cc = 1;
        }
        else {
            $cc = -1; # Imposible?
        }
    }

    # Final chech
    if ( $cnp[12] == $cc ) {
        $self->{tpda}{gui}->refresh_sb( 'll', 'CNP Ok!', 'darkgreen');
        print "CNP Ok!\n";
    }
    else {
        $self->{tpda}{gui}->refresh_sb( 'll', 'CNP Eronat!', 'red');
        print "CNP Eronat!\n";
    }

    return;
}

sub email_ok {
    my $self = shift;

    if ( eval { require Email::Valid } ) {
        my $email = $self->{eobj_rec}{email}[3]->get; #  E-mail
        my ($msg, $color) = ('Adresa de E-mail pare ', 'darkgreen');
        if ( Email::Valid->address($email) ) {
            $msg  .= 'valida';
        }
        else {
            $msg  .= 'invalida';
            $color = 'red';
        }
        print "$msg\n";
        $self->{tpda}{gui}->refresh_sb( 'll', $msg, $color );
    }
    else {
        print "Validare E-mail indisponibila.\n";
    }

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

1; # End of Tpda3::Tk::App::Fpimm::WidgetsAll
