package Tpda3::App::test::Products;

use strict;
use warnings;

sub new {
    my $type = shift;

    my $self = {};

    bless( $self, $type );

    return $self;
}

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
    );
    $frame1->grid(
        $frame1,
        -row    => 0,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'nsew',
    );

    # Code (productcode)
    my $lproductcode = $frame1->Label( -text => 'Code' );
    $lproductcode->form(
        -left => [ %0, 0 ],
        -top  => [ %0, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eproductcode = $frame1->Entry( -width => 15 );
    $eproductcode->form(
        -top  => [ '&', $lproductcode, 0 ],
        -left => [ %0,  80 ],
    );

    # Name (productname)
    my $lproductname = $frame1->Label( -text => 'Name' );
    $lproductname->form(
        -left => [ %0,            0 ],
        -top  => [ $lproductcode, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eproductname = $frame1->Entry( -width => 35 );
    $eproductname->form(
        -top  => [ '&', $lproductname, 0 ],
        -left => [ %0,  80 ],
    );

    # Line (productline)
    my $lproductline = $frame1->Label( -text => 'Line' );
    $lproductline->form(
        -left => [ %0,            0 ],
        -top  => [ $lproductname, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eproductline = $frame1->Entry( -width => 28 );
    $eproductline->form(
        -top  => [ '&', $lproductline, 0 ],
        -left => [ %0,  80 ],
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
    $eproductlinecode->form(
        -top   => [ '&', $lproductline, 0 ],
        -right => [ '&', $eproductname, 0 ],
    );

    # Scale (productscale)
    my $lproductscale = $frame1->Label( -text => 'Scale' );
    $lproductscale->form(
        -left => [ %0,            0 ],
        -top  => [ $lproductline, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eproductscale = $frame1->Entry( -width => 10 );
    $eproductscale->form(
        -top  => [ '&', $lproductscale, 0 ],
        -left => [ %0,  80 ],
    );

    # Vendor (productvendor)
    my $lproductvendor = $frame1->Label( -text => 'Vendor' );
    $lproductvendor->form(
        -left => [ %0,             0 ],
        -top  => [ $lproductscale, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eproductvendor = $frame1->Entry( -width => 35 );
    $eproductvendor->form(
        -top  => [ '&', $lproductvendor, 0 ],
        -left => [ %0,  80 ]
    );

    # Stock (quantityinstock)
    my $lquantityinstock = $frame1->Label( -text => 'Stock' );
    $lquantityinstock->form(
        -left => [ %0,              0 ],
        -top  => [ $lproductvendor, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $equantityinstock = $frame1->Entry( -width => 5 );
    $equantityinstock->form(
        -top  => [ '&', $lquantityinstock, 0 ],
        -left => [ %0,  80 ],
    );

    # Buy price (buyprice)
    my $lbuyprice = $frame1->Label( -text => 'Buy price' );
    $lbuyprice->form(
        -left => [ %0,                0 ],
        -top  => [ $lquantityinstock, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $ebuyprice = $frame1->Entry( -width => 8 );
    $ebuyprice->form( -top => [ '&', $lbuyprice, 0 ], -left => [ %0, 80 ] );

    # MSRP (msrp)
    my $lmsrp = $frame1->Label( -text => 'MSRP' );
    $lmsrp->form(
        -left => [ %0,         0 ],
        -top  => [ $lbuyprice, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $emsrp = $frame1->Entry( -width => 8 );
    $emsrp->form( -top => [ '&', $lmsrp, 0 ], -left => [ %0, 80 ] );

    # Frame 2

    my $frame2 = $inreg_p->LabFrame(
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

# +--------------------------------------------------------------------------+
# | G e t   e n t r y   o b j e c t s   m e t h o d s.                       |
# +--------------------------------------------------------------------------+

sub get_eobj_rec { return $_[0]->{eobj_rec}; }

sub get_eobj_det { return undef; }

sub get_tmxobj { return undef; }

sub get_treeobj { return undef; }

sub get_eobj_lst { return undef; }

sub get_eobj_pre { return undef; }

sub get_eobj_lbl { return $_[0]->{fld_label}; }

1;
