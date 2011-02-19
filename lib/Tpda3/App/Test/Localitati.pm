package Tpda3::App::Test::Localitati;

use strict;
use warnings;

use base q{Tpda3::Tk::Screen};

=head1 NAME

Tpda3::App::Test::Localitati screen

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    require Tpda3::App::Test::Localitati;

    my $scr = Tpda3::App::Test::Localitati->new;

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

    #- Frame1

    my $frame1 = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Localitate',
        -labelside  => 'acrosstop'
    );

    $frame1->grid(
        $frame1,
        -row => 0, -column => 0,
        -ipadx => 3, -ipady => 3,
        -sticky  => 'nsew',
    );

    #-- cod_p (cod_p)
    my $lcod_p = $frame1->Label(
        -text => 'Cod',
    );
    $lcod_p->form(
        -top  => [ %0, 0 ],
        -left => [ %0, 0 ],
        -padleft => 5,
    );

    my $ecod_p = $frame1->Entry(
        -width => 7,
        -validate => 'key',
        # -vcmd     => sub {
        #     $self->{utils}->entry_limit( '_alpha_num:6', @_ );
        # }
    );
    $ecod_p->form(
        -top => [ '&', $lcod_p, 0 ],
        -left => [ %0, 80 ],
    );

    #-- Localitate (localitate)
    my $llocalitate = $frame1->Label(
        -text => 'Localitate',
    );
    $llocalitate->form(
        -top  => [ $lcod_p, 8 ],
        -left => [ %0,      0 ],
        -padleft => 5,
    );

    my $elocalitate = $frame1->Entry(
        -width => 30,
        -validate => 'key',
        # -vcmd     => sub {
        #     $self->{utils}->entry_limit( '_alpha_num_plus:40', @_ );
        # }
    );
    $elocalitate->form(
        -top  => [ '&', $llocalitate, 0 ],
        -left => [ %0, 80 ],
    );
    $elocalitate->bind(
        '<KeyPress-Return>' => sub {
            $self->{cautare}->Dict( $gui, 'judete' );
        }
    );

    #-- Judet (judet)
    my $ljudet = $frame1->Label(
        -text => 'Judet',
    );
    $ljudet->form(
        -left => [ %0,           0 ],
        -top  => [ $llocalitate, 8 ],
        -padleft => 5,
    );

    my $ejudet = $frame1->Entry(
        -width => 25,
    );
    $ejudet->form(
        -top  => [ '&', $ljudet, 0 ],
        -left => [ %0, 80 ],
    );
    $ejudet->bind(
        '<KeyPress-Return>' => sub {
            $self->{cautare}->Dict( $gui, 'judete' );
        }
    );

    # id_judet (SMALLINT)
    my $eid_judet = $frame1->Entry(
        -width              => 3,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black'
    );
    $eid_judet->form(
        -top => [ '&', $ljudet, 0 ],
        -left => [ $ejudet, 6 ],
    );

    #- Frame2

    my $frame2 = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Adresa primarie',
        -labelside  => 'acrosstop'
    );
    $frame2->grid(
        $frame2,
        -row    => 1, -column => 0,
        -ipadx => 3, -ipady => 3,
        -sticky  => 'nsew',
    );

    # my $prim  = 0;
    # my $eprim = $frame2->Checkbutton(
    #     -text     => 'Primarie',
    #     -variable => \$prim,
    #     -offvalue => 0,
    #     -onvalue  => 1,
    #     -relief   => 'flat'
    # );
    # $eprim->form(
    #     -top  => [ %0, 0 ],
    #     -left => [ %0, 0 ],
    #     -padleft => 7,
    # );

    #- Font

    my $my_font = $ecod_p->cget('-font');

    #- Prim adresa (prim_adresa)
    my $tprim_adresa = $frame2->Scrolled(
        'Text',
        -width      => 50,
        -height     => 3,
        -wrap       => 'word',
        -scrollbars => 'e',
        -font       => $my_font
    );

    $tprim_adresa->form(
        -left => [ %0, 0 ],
        -top  => [ %0, 3 ],
        -padleft => 7,
    );

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'products.conf'
    $self->{controls} = {
        localitate  => [ undef,  $elocalitate ],
        judet       => [ undef,  $ejudet ],
        id_judet    => [ undef,  $eid_judet ],
        cod_p       => [ undef,  $ecod_p ],
        # prim        => [ \$prim, $eprim ],
        prim_adresa => [ undef,  $tprim_adresa, ],
    };

    # Required fields: fld_name => [#, Label]
    # If there is no value in the screen for this fields show a dialog message
    $self->{req_controls} = {
        cod_p      => [ 0, '  Cod  tert'  ],
        localitate => [ 1, '  Localitate' ],
        id_judet   => [ 2, '  Judet   '   ],
    };

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::App::Test::Localitati
