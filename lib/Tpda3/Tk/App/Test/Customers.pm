package Tpda3::Tk::App::Test::Customers;

use strict;
use warnings;

use base 'Tpda3::Tk::Screen';

=head1 NAME

Tpda3::App::Test::Customers screen

=head1 VERSION

Version 0.49

=cut

our $VERSION = 0.49;

=head1 SYNOPSIS

    require Tpda3::App::Test::Customers;

    my $scr = Tpda3::App::Test::Customers->new;

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

    my $validation
        = Tpda3::Tk::Validation->new( $self->{scrcfg}, $self->{view} );

    #-- Frame1 - Customer

    my $frame1 = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Customer',
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

    #- Customername (customername)

    my $lcustomername = $frame1->Label( -text => 'Customer' );
    $lcustomername->form(
        -top  => [ %0, 0 ],
        -left => [ %0, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $ecustomername = $frame1->MEntry(
        -width    => 35,
        -validate => 'key',
        -vcmd     => sub {
            $validation->validate_entry( 'customername', @_ );
        },
    );
    $ecustomername->form(
        -top  => [ '&', $lcustomername, 0 ],
        -left => [ %0,  110 ],
    );

    #-+ Customernumber

    my $ecustomernumber = $frame1->MEntry(
        -width              => 5,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $ecustomernumber->form(
        -top  => [ '&',            $lcustomername, 0 ],
        -left => [ $ecustomername, 5 ],
    );

    #- Contactlastname (contactlastname)

    my $lcontactlastname = $frame1->Label( -text => 'Last name' );
    $lcontactlastname->form(
        -top  => [ $lcustomername, 0 ],
        -left => [ %0,             0 ],
        -padx => 5,
        -pady => 5,
    );

    my $econtactlastname = $frame1->MEntry( -width => 42 );
    $econtactlastname->form(
        -top  => [ '&', $lcontactlastname, 0 ],
        -left => [ %0,  110 ],
    );

    #- Contactfirstname (contactfirstname)

    my $lcontactfirstname = $frame1->Label( -text => 'First name' );
    $lcontactfirstname->form(
        -top  => [ $lcontactlastname, 0 ],
        -left => [ %0,                0 ],
        -padx => 5,
        -pady => 5,
    );

    my $econtactfirstname = $frame1->MEntry( -width => 42 );
    $econtactfirstname->form(
        -top  => [ '&', $lcontactfirstname, 0 ],
        -left => [ %0,  110 ],
    );

    #- Phone (phone)

    my $lphone = $frame1->Label( -text => 'Phone' );
    $lphone->form(
        -top  => [ $lcontactfirstname, 0 ],
        -left => [ %0,                 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $ephone = $frame1->MEntry( -width => 42 );
    $ephone->form(
        -top  => [ '&', $lphone, 0 ],
        -left => [ %0,  110 ],
    );

    #- Addressline1 (addressline1)

    my $laddressline1 = $frame1->Label( -text => 'Address line1' );
    $laddressline1->form(
        -top  => [ $lphone, 0 ],
        -left => [ %0,      0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eaddressline1 = $frame1->MEntry( -width => 42 );
    $eaddressline1->form(
        -top  => [ '&', $laddressline1, 0 ],
        -left => [ %0,  110 ],
    );

    #- Addressline2 (addressline2)

    my $laddressline2 = $frame1->Label( -text => 'Address line2' );
    $laddressline2->form(
        -top  => [ $laddressline1, 0 ],
        -left => [ %0,             0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eaddressline2 = $frame1->MEntry( -width => 42 );
    $eaddressline2->form(
        -top  => [ '&', $laddressline2, 0 ],
        -left => [ %0,  110 ],
    );

    #- City (city)

    my $lcity = $frame1->Label( -text => 'City' );
    $lcity->form(
        -top  => [ $laddressline2, 0 ],
        -left => [ %0,             0 ],
        -padx => 5,
        -pady => 5,
    );

    my $ecity = $frame1->MEntry( -width => 42 );
    $ecity->form(
        -top  => [ '&', $lcity, 0 ],
        -left => [ %0,  110 ],
    );

    #- State (state)

    my $lstate = $frame1->Label( -text => 'State' );
    $lstate->form(
        -top  => [ $lcity, 0 ],
        -left => [ %0,     0 ],
        -padx => 5,
        -pady => 5,
    );

    my $estate = $frame1->MEntry( -width => 42 );
    $estate->form(
        -top  => [ '&', $lstate, 0 ],
        -left => [ %0,  110 ],
    );

    #- Countryname (countryname)

    my $lcountryname = $frame1->Label( -text => 'Country' );
    $lcountryname->form(
        -top  => [ $lstate, 0 ],
        -left => [ %0,      0 ],
        -padx => 5,
        -pady => 5,
    );

    my $ecountryname = $frame1->MEntry( -width => 35 );
    $ecountryname->form(
        -top  => [ '&', $lcountryname, 0 ],
        -left => [ %0,  110 ],
    );

    #-+ Countrycode
    my $ecountrycode = $frame1->MEntry(
        -width              => 5,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $ecountrycode->form(
        -top  => [ '&',           $lcountryname, 0 ],
        -left => [ $ecountryname, 5 ],
    );

    #- Salesrepemployee (salesrepemployee)

    my $lsalesrepemployee = $frame1->Label( -text => 'Sales repres.' );
    $lsalesrepemployee->form(
        -top  => [ $lcountryname, 0 ],
        -padx => 5,
        -pady => 5,
        -left => [ %0,            0 ],
    );

    my $esalesrepemployee = $frame1->MEntry( -width => 35 );
    $esalesrepemployee->form(
        -top  => [ '&', $lsalesrepemployee, 0 ],
        -left => [ %0,  110 ],
    );

    #-+ Eemployeenumber

    my $eemployeenumber = $frame1->MEntry(
        -width              => 5,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eemployeenumber->form(
        -top  => [ '&',                $lsalesrepemployee, 0 ],
        -left => [ $esalesrepemployee, 5 ],
    );

    #- Creditlimit (creditlimit)

    my $lcreditlimit = $frame1->Label( -text => 'Credit limit' );
    $lcreditlimit->form(
        -top  => [ $lsalesrepemployee, 0 ],
        -left => [ %0,                 0 ],
        -padx => 5,
    );

    my $ecreditlimit = $frame1->MEntry(
        -width    => 10,
        -justify  => 'right',
        -validate => 'key',
        -vcmd     => sub {
            $validation->validate_entry( 'creditlimit', @_ );
        },
    );

    $ecreditlimit->form(
        -top  => [ '&', $lcreditlimit, 0 ],
        -left => [ %0,  110 ],
    );

    #- Postalcode

    my $epostalcode = $frame1->MEntry( -width => 15 );
    $epostalcode->form(
        -top   => [ '&',  $lcreditlimit, 0 ],
        -right => [ %100, -5 ],
    );

    my $lpostalcode = $frame1->Label(
        -text => 'Postal code',
        -padx => 5,
    );
    $lpostalcode->form(
        -top   => [ '&',          $lcreditlimit, 0 ],
        -right => [ $epostalcode, -20 ],
    );

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'customers.conf'
    $self->{controls} = {
        customername     => [ undef, $ecustomername ],
        customernumber   => [ undef, $ecustomernumber ],
        contactlastname  => [ undef, $econtactlastname ],
        contactfirstname => [ undef, $econtactfirstname ],
        phone            => [ undef, $ephone ],
        addressline1     => [ undef, $eaddressline1 ],
        addressline2     => [ undef, $eaddressline2 ],
        city             => [ undef, $ecity ],
        state            => [ undef, $estate ],
        countryname      => [ undef, $ecountryname ],
        countrycode      => [ undef, $ecountrycode ],
        salesrepemployee => [ undef, $esalesrepemployee ],
        employeenumber   => [ undef, $eemployeenumber ],
        creditlimit      => [ undef, $ecreditlimit ],
        postalcode       => [ undef, $epostalcode ],
    };

    # Required fields: fld_name => [#, Label]
    # If there is no value in the screen for this fields show a dialog message
    $self->{rq_controls} = {
        customername     => [ 0, '  Customer name' ],
        contactlastname  => [ 1, '  Contact last name' ],
        contactfirstname => [ 2, '  Contact first name' ],
        phone            => [ 3, '  Phone' ],
        addressline1     => [ 4, '  Address line 1' ],
        city             => [ 5, '  City' ],
        countrycode      => [ 6, '  Country' ],
    };

    return;
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

1;    # End of Tpda3::Tk::App::Test::Customers
