package Tpda3::App::Test::Products2;

use strict;
use warnings;

use base 'Tpda3::Tk::Screen';

=head1 NAME

Tpda3::App::Test::Products2 screen

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    require Tpda3::App::Test::Products2;

    my $scr = Tpda3::App::Test::Products2->new;

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
        -disabledbackground => $self->{bg},
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

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'products.conf'
    $self->{controls} = {
        productcode        => [ undef, $eproductcode ],
        productname        => [ undef, $eproductname ],
        productline        => [ undef, $eproductline ],
        productlinecode    => [ undef, $eproductlinecode ],
        productscale       => [ undef, $eproductscale ],
        productvendor      => [ undef, $eproductvendor ],
        quantityinstock    => [ undef, $equantityinstock ],
        buyprice           => [ undef, $ebuyprice ],
        msrp               => [ undef, $emsrp ],
        productdescription => [ undef, $tproductdescription ],
    };

    # Required fields: fld_name => [#, Label]
    # If there is no value in the screen for this fields show a dialog message
    $self->{req_controls} = {
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

1; # End of Tpda3::App::Test::Products2
