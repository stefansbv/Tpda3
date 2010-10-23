package Tpda3::App::test::Products2;

use strict;
use warnings;

=head1 NAME

Tpda3::App::test::Products2 screen

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    require Tpda3::App::test::Products2;

    my $scr = Tpda3::App::test::Products2->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my $type = shift;

    my $self = {};

    bless( $self, $type );

    return $self;
}

=head2 run_screen

The screen layout

=cut

sub run_screen {

    my ( $self, $inreg_p ) = @_;

    my $gui    = $inreg_p->toplevel;
    my $main_p = $inreg_p->parent;
    my $bg     = $gui->cget('-background');

    # Products
    my $frame1 = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Product',
        -labelside  => 'acrosstop',
    )->pack( -expand => 1, -fill => 'x' );

    # Code (productcode)
    my $lproductcode = $frame1->Label( -text => 'Code' );
    $lproductcode->grid(
        -row    => 0,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
    );

    my $eproductcode = $frame1->Entry( -width => 15 );
    $eproductcode->grid(
        -row    => 0,
        -column => 1,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
        -columnspan => 2,
    );
    Tk::grid
    # Name (productname)
    my $lproductname = $frame1->Label( -text => 'Name' );
    $lproductname->grid(
        -row    => 1,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
    );

    my $eproductname = $frame1->Entry( -width => 35 );
    $eproductname->grid(
        -row    => 1,
        -column => 1,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
        -columnspan => 2,
    );

    # Line (productline)
    my $lproductline = $frame1->Label( -text => 'Line' );
    $lproductline->grid(
        -row    => 2,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
    );

    my $eproductline = $frame1->Entry( -width => 28 );
    $eproductline->grid(
        -row    => 2,
        -column => 1,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
        -columnspan => 2,
    );
    $eproductline->bind(
        '<KeyPress-Return>' => sub {
            $self->{cautare}->Dict( $gui, 'productlines' );
        }
    );

    # + Productlinecode
    my $eproductlinecode = $frame1->Entry(
        -width              => 5,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $eproductlinecode->grid(
        -row    => 2,
        -column => 2,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'e',
        -padx => 5,
        -pady => 5,
    );

    # Scale (productscale)
    my $lproductscale = $frame1->Label( -text => 'Scale' );
    $lproductscale->grid(
        -row    => 3,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
    );

    my $eproductscale = $frame1->Entry( -width => 10 );
    $eproductscale->grid(
        -row    => 3,
        -column => 1,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
        -columnspan => 2,
    );

    # Vendor (productvendor)
    my $lproductvendor = $frame1->Label( -text => 'Vendor' );
    $lproductvendor->grid(
        -row    => 5,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
    );

    my $eproductvendor = $frame1->Entry( -width => 35 );
    $eproductvendor->grid(
        -row    => 5,
        -column => 1,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
        -columnspan => 2,
    );

    # Stock (quantityinstock)
    my $lquantityinstock = $frame1->Label( -text => 'Stock' );
    $lquantityinstock->grid(
        -row    => 6,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
    );

    my $equantityinstock = $frame1->Entry( -width => 5 );
    $equantityinstock->grid(
        -row    => 6,
        -column => 1,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
        -columnspan => 2,
    );

    # Buy price (buyprice)
    my $lbuyprice = $frame1->Label( -text => 'Buy price' );
    $lbuyprice->grid(
        -row    => 7,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
    );

    my $ebuyprice = $frame1->Entry( -width => 8 );
    $ebuyprice->grid(
        -row    => 7,
        -column => 1,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
        -columnspan => 2,
    );

    # MSRP (msrp)
    my $lmsrp = $frame1->Label( -text => 'MSRP' );
    $lmsrp->grid(
        -row    => 8,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
    );

    my $emsrp = $frame1->Entry( -width => 8 );
    $emsrp->grid(
        -row    => 8,
        -column => 1,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
        -columnspan => 2,
    );

    # Frame 2

    my $frame2 = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Description',
        -labelside  => 'acrosstop',
    )->pack( -expand => 1, -fill => 'x' );

    # Font
    my $my_font = $eproductcode->cget('-font');

    # Products
    my $tproductdescription = $frame2->Scrolled(
        'Text',
        -width      => 45,
        -height     => 4,
        -wrap       => 'word',
        -scrollbars => 'e',
        -font       => $my_font,
    );

    $tproductdescription->grid(
        -row    => 0,
        -column => 0,
        -ipadx  => 5,
        -ipady  => 5,
        -sticky => 'w',
        -padx => 5,
        -pady => 5,
    );

    # Entry objects
    #     fld_name => [0-tip_entry, 1-w|r-updatable? 2-var_asoc, 3-var_obiect,
    #                            4-state, 5-color, 6-decimals, 7-type_of_find]
    # Type_of_find: 0=none, 1=all number, 2=contains_str, 3=all_str
    $self->{eobj_rec} = {
        productcode =>
          [ 'e', 'w', undef, $eproductcode, 'normal', 'white', undef, 2 ],
        buyprice =>
          [ 'e', 'w', undef, $ebuyprice, 'normal', 'white', undef, 0 ],
        msrp =>
          [ 'e', 'w', undef, $emsrp, 'normal', 'white', undef, 0 ],
        productvendor =>
          [ 'e', 'w', undef, $eproductvendor, 'normal', 'white', undef, 1 ],
        productscale =>
          [ 'e', 'w', undef, $eproductscale, 'normal', 'white', undef, 1 ],
        quantityinstock =>
          [ 'e', 'w', undef, $equantityinstock, 'normal', 'white', undef, 1 ],
        productline =>
          [ 'e', 'r', undef, $eproductline, 'normal', 'lightgreen', undef, 2 ],
        productlinecode => [
            'e', 'w', undef, $eproductlinecode, 'disabled', 'lightgrey', undef,
            1
        ],
        productdescription => [
            't', 'w', undef, $tproductdescription, 'normal', 'white', undef, 2
        ],
        productname =>
          [ 'e', 'w', undef, $eproductname, 'normal', 'white', undef, 2 ],
    };

    # Required fields: fld_name => [#, Label]
    # If there is no value in the screen for this fields show a dialog message
    $self->{fld_label} = {
        productcode        => [ 0, '  Product code' ],
        productname        => [ 1, '  Product name' ],
        productlinecode    => [ 2, '  Product Line' ],
        productscale       => [ 3, '  Product scale' ],
        productvendor      => [ 4, '  Product vendor' ],
        quantityinstock    => [ 5, '  Quantity in stock' ],
        buyprice           => [ 6, '  Buy price' ],
        msrp               => [ 7, '  MSRP' ],
        productdescription => [ 8, '  Product description' ],
    };

    return $eproductcode;
}

=head2 get_eobj_rec

return record

=cut

sub get_eobj_rec { return $_[0]->{eobj_rec}; }

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

1; # End of Tpda3::App::test::Products2
