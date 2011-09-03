package Tpda3::Tk::App::Test::Products;

use strict;
use warnings;

use base 'Tpda3::Tk::Screen';

=head1 NAME

Tpda3::App::Test::Products screen

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    require Tpda3::App::Test::Products;

    my $scr = Tpda3::App::Test::Products->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $nb ) = @_;

    my $rec_page = $nb->page_widget('rec');
    my $det_page = $nb->page_widget('det');

    $self->{view} = $nb->toplevel;
    $self->{bg}   = $self->{view}->cget('-background');

    my $validation = Tpda3::Tk::Validation->new( $self->{scrcfg} );

    #- Frame1 - Products

    my $frame1 = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Product',
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

    #- Code (productcode)

    my $lproductcode = $frame1->Label( -text => 'Code', );
    $lproductcode->form(
        -left => [ %0, 0 ],
        -top  => [ %0, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eproductcode = $frame1->MEntry(
        -width              => 15,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eproductcode->form(
        -top  => [ '&', $lproductcode, 0 ],
        -left => [ %0,  80 ],
    );

    #- Name (productname)

    my $lproductname = $frame1->Label( -text => 'Name', );
    $lproductname->form(
        -left => [ %0,            0 ],
        -top  => [ $lproductcode, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eproductname = $frame1->MEntry(
        -width              => 35,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eproductname->form(
        -top  => [ '&', $lproductname, 0 ],
        -left => [ %0,  80 ],
    );

    #- Line (productline)

    my $lproductline = $frame1->Label( -text => 'Line', );
    $lproductline->form(
        -left => [ %0,            0 ],
        -top  => [ $lproductname, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eproductline = $frame1->MEntry(
        -width              => 28,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eproductline->form(
        -top  => [ '&', $lproductline, 0 ],
        -left => [ %0,  80 ],
    );

    #-+ Productlinecode

    my $eproductlinecode = $frame1->MEntry(
        -width              => 5,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eproductlinecode->form(
        -top   => [ '&', $lproductline, 0 ],
        -right => [ '&', $eproductname, 0 ],
    );

    #- Scale (productscale)

    my $lproductscale = $frame1->Label( -text => 'Scale', );
    $lproductscale->form(
        -left => [ %0,            0 ],
        -top  => [ $lproductline, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eproductscale = $frame1->MEntry(
        -width              => 10,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eproductscale->form(
        -top  => [ '&', $lproductscale, 0 ],
        -left => [ %0,  80 ],
    );

    #- Vendor (productvendor)

    my $lproductvendor = $frame1->Label( -text => 'Vendor', );
    $lproductvendor->form(
        -left => [ %0,             0 ],
        -top  => [ $lproductscale, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eproductvendor = $frame1->MEntry(
        -width              => 35,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eproductvendor->form(
        -top  => [ '&', $lproductvendor, 0 ],
        -left => [ %0,  80 ],
    );

    #- Stock (quantityinstock)

    my $lquantityinstock = $frame1->Label( -text => 'Stock', );
    $lquantityinstock->form(
        -left => [ %0,              0 ],
        -top  => [ $lproductvendor, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $equantityinstock = $frame1->MEntry(
        -width              => 8,
        -justify            => 'right',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $equantityinstock->form(
        -top  => [ '&', $lquantityinstock, 0 ],
        -left => [ %0,  80 ],
    );

    #- Buy price (buyprice)

    my $lbuyprice = $frame1->Label( -text => 'Buy price', );
    $lbuyprice->form(
        -left => [ %0,                0 ],
        -top  => [ $lquantityinstock, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $ebuyprice = $frame1->MEntry(
        -width              => 8,
        -justify            => 'right',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $ebuyprice->form(
        -top  => [ '&', $lbuyprice, 0 ],
        -left => [ %0,  80 ],
    );

    #- MSRP (msrp)
    my $lmsrp = $frame1->Label( -text => 'MSRP', );
    $lmsrp->form(
        -left => [ %0,         0 ],
        -top  => [ $lbuyprice, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $emsrp = $frame1->MEntry(
        -width              => 8,
        -justify            => 'right',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $emsrp->form(
        -top  => [ '&', $lmsrp, 0 ],
        -left => [ %0,  80 ],
    );

    # Frame 2

    my $frame2 = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Description',
        -labelside  => 'acrosstop',
    );
    $frame2->grid(
        $frame2,
        -row    => 1,
        -column => 0,
        -sticky => 'nsew',
    );

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

    $tproductdescription->form(
        -left => [ %0, 0 ],
        -top  => [ %0, 0 ],
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
    $self->{rq_controls} = {
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

1;    # End of Tpda3::Tk::App::Test::Products
