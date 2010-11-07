package Tpda3::App::Test::Orders;

use strict;
use warnings;

use Tk::widgets qw(DateEntry JComboBox TableMatrix);

use base 'Tpda3::Tk::Screen';

=head1 NAME

Tpda3::App::Test::Orders screen

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    require Tpda3::App::Test::Orders;

    my $scr = Tpda3::App::Test::Orders->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

our (@daynames, $conn, $xtvar);

sub run_screen {
    my ( $self, $inreg_p ) = @_;

    my $gui     = $inreg_p->toplevel;
    my $main_p  = $inreg_p->parent;
    $self->{bg} = $gui->cget('-background');

    # Toolbar buttons
    my ( $add_button, $del_button );

    my $eordernumber;

    #-- Frame 1 - Order

    my $frame1 = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Order',
        -labelside  => 'acrosstop',
    );
    $frame1->grid(
        $frame1,
        -row     => 0, -column  => 0,
        -ipadx   => 3, -ipady   => 3,
        -rowspan => 2,
        -sticky  => 'nsew',
    );

    #- Customers

    my $lcustomername = $frame1->Label(
        -text => 'Customer, No',
    );
    $lcustomername->form(
        -top  => [ %0, 0 ],
        -left => [ %0, 0 ],
        -padx => 5, -pady => 5,
    );

    my $ecustomername = $frame1->Entry( -width => 35 );
    $ecustomername->form(
        -top  => [ '&', $lcustomername, 0 ],
        -left => [ %0,  90 ],
    );
    $ecustomername->bind(
        '<KeyPress-Return>' => sub {
            $self->{cautare}->Dict( $gui, 'customers' );
        }
    );

    #-+ Customer number (customernumber)

    my $ecustomernumber = $frame1->Entry(
        -width              => 6,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $ecustomernumber->form(
        -top  => [ '&',            $lcustomername, 0 ],
        -left => [ $ecustomername, 5 ]
    );

    #- Ordernumber (ordernumber)

    my $lordernumber = $frame1->Label( -text => 'Order ID' );
    $lordernumber->form(
        -top  => [ $lcustomername, 0 ],
        -left => [ %0,             0 ],
        -padx => 5, -pady => 5,
    );

    $eordernumber = $frame1->Entry(
        -width              => 10,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eordernumber->form(
        -top  => [ '&', $lordernumber, 0 ],
        -left => [ %0,  90 ],
    );

    #-+ Orderdate (orderdate)

    my $vorderdate;
    my $dorderdate = $frame1->DateEntry(
        -daynames   => \@daynames,
        -variable   => \$vorderdate,
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

    $dorderdate->form(
        -top   => [ '&', $lordernumber,    0 ],
        -right => [ '&', $ecustomernumber, 0 ],
    );

    my $lorderdate = $frame1->Label( -text => 'Order date' );
    $lorderdate->form(
        -top   => [ '&',         $lordernumber, 0 ],
        -right => [ $dorderdate, -20 ],
        -pady  => 5,
    );

    #- Requireddate (requireddate)

    my $lrequireddate = $frame1->Label( -text => 'Required date' );
    $lrequireddate->form(
        -top  => [ $lordernumber, 0 ],
        -left => [ %0,            0 ],
        -padx => 5, -pady => 5,
    );

    my $vrequireddate;
    my $drequireddate = $frame1->DateEntry(
        -daynames   => \@daynames,
        -variable   => \$vrequireddate,
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

    $drequireddate->form(
        -top  => [ '&', $lrequireddate, 0 ],
        -left => [ %0,  90 ],
    );

    #-+ Shippeddate (shippeddate)

    my $lshippeddate = $frame1->Label( -text => 'Shipped date' );
    $lshippeddate->form(
        -top  => [ '&', $lrequireddate, 0 ],
        -left => [ '&', $lorderdate,    0 ],
        -pady => 5,
    );

    my $vshippeddate;
    my $dshippeddate = $frame1->DateEntry(
        -daynames   => \@daynames,
        -variable   => \$vshippeddate,
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

    $dshippeddate->form(
        -top   => [ '&', $lshippeddate,    0 ],
        -right => [ '&', $ecustomernumber, 0 ],
    );

    #- Status code (statuscode)

    my $lstatuscode = $frame1->Label( -text => 'Status' );
    $lstatuscode->form(
        -left => [ %0,             0 ],
        -top  => [ $lrequireddate, 0 ],
        -padx => 5,
    );

    my $vstatuscode;
    my $bstatuscode = $frame1->JComboBox(
        -entrywidth         => 15,
        -relief             => 'sunken',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
        -textvariable       => \$vstatuscode,
    );

    $bstatuscode->form(
        -top  => [ '&', $lstatuscode, 0 ],
        -left => [ %0,  90 ],
    );

    #-- Frame2 - Comments

    my $frame2 = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Comments',
        -labelside  => 'acrosstop',
    );
    $frame2->grid(
        $frame2,
        -row     => 0, -column  => 1,
        -rowspan => 2,
        -sticky  => 'nsew',
    );

    #-- Font
    my $my_font = $eordernumber->cget('-font');

    #- Comments (comments)

    my $tcomments = $frame2->Scrolled(
        'Text',
        -width      => 30,
        -height     => 7,
        -wrap       => 'word',
        -scrollbars => 'e',
        -font       => $my_font,
    );

    $tcomments->form(
        -left => [ %0, 0 ],
        -top  => [ %0, 0 ],
        -padx => 5, -pady => 5,
    );

    #--- Details
    #-
    #

    #-- Frame t => Tabel

    my $frm_t = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Order Items',
        -labelside  => 'acrosstop',
    );
    $frm_t->grid(
        $frm_t,
        -row        => 2, -column     => 0,
        -columnspan => 2,
        -sticky     => 'nsew',
    );

    #-- Toolbar

    my $tbf1 = $frm_t->Frame();
    $tbf1->pack(
        -anchor => 'n',
        -expand => 'y',
        -fill   => 'x',
    );

    my $xtabel = $frm_t->Scrolled(
        'TableMatrix',
        -rows          => 5,
        -cols          => 5,
        -width         => -1,
        -height        => -1,
        -ipadx         => 3,
        -titlerows     => 1,
        -validate      => 1,
        -variable      => $xtvar,
        -selectmode    => 'single',
        -resizeborders => 'none',
        -bg            => 'white',
        -scrollbars    => 'osw',
    );

    # Bindings:
    # Make enter do the same thing as return?:
    $xtabel->bind( '<KP_Enter>', $xtabel->bind('<Return>') );
    $xtabel->pack( -expand => 1, -fill => 'both' );

    # Add toolbar buttons
    my $mw1 = $tbf1->Frame();
    $mw1->pack(
        -anchor => 'n',
        -expand => 'n',
        -fill   => 'x',
    );

    my $tb1 = $mw1->ToolBar(qw/-movable 0 -side top -cursorcontrol 0/);

    # $add_button = $self->{tpda}->{gui}->gui_build_tb_button(
    #     $tb1,
    #     'Adaug rand',
    #     sub {
    #         $self->{tpda}->{gui}->insert_tmatrix_row($xtabel);
    #     },
    #     'actitemadd16',
    # );
    # $del_button = $self->{tpda}->{gui}->gui_build_tb_button(
    #     $tb1,
    #     'Sterg rand',
    #     sub {
    #         $self->{tpda}->{gui}->delete_tmatrix_row($xtabel);
    #     },
    #     'actitemdelete16',
    # );
    ### end Toolbar

    # Bindings:
    # Make the active area move after we press return:
    # We Have to use class binding here so that we override
    #  the default return binding
    my $t1     = $xtabel->Subwidget('scrolled');
    my $params = {
        $t1    => 'T1',
        'conn' => $conn,
        'gui'  => $gui,
        'add1' => $add_button,
    };

    $xtabel->bind( 'Tk::TableMatrix',
        '<Return>' => [ \&callback, $self, $params ] );

    #-- Frame Bottom Right

    my $frm_bl = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Total',
        -labelside  => 'acrosstop',
    );

    $frm_bl->grid(
        $frm_bl,
        -row        => 3, -column     => 0,
        -ipady      => 3,
        -columnspan => 2,
        -sticky     => 'nsew',
    );

    #- Ordertotal (ordertotal)

    my $eordertotal = $frm_bl->Entry(
        -width   => 12,
        -justify => 'right',
    );
    $eordertotal->form(
        -top   => [ %0,   0 ],
        -right => [ %100, -5 ],
    );

    my $lordertotal = $frm_bl->Label( -text => 'Order total' );
    $lordertotal->form(
        -right => [ $eordertotal, -15 ],
        -top => [ '&', $eordertotal, 0 ],
    );

    # This makes TableMatrix expand !!!
    $xtabel->update;

    #---

    # Entry objects fld_name => [0-tip_entry, 1-w|r-updatable? 2-var_asoc,
    #               3-var_obiect, 4-state, 5-color, 6-decimals, 7-type_of_find]
    # Type_of_find: 0=none, 1=all number, 2=contains_str, 3=all_str
    $self->{controls} = {
        customername   => [ undef,           $ecustomername ],
        customernumber => [ undef,           $ecustomernumber ],
        ordernumber    => [ undef,           $eordernumber ],
        orderdate      => [ \$vorderdate,    $dorderdate ],
        requireddate   => [ \$vrequireddate, $drequireddate ],
        shippeddate    => [ \$vshippeddate,  $dshippeddate ],
        statuscode     => [ \$vstatuscode,   $bstatuscode ],
        comments       => [ undef,           $tcomments ],
        ordertotal     => [ undef,           $eordertotal ],
    };

    # TableMatrix objects
    # Campuri tabel
    # nume_camp => [#,Header,order_by,ro|rw,size,align,type:size:dec]
    $self->{tmxobj} = {
        rec => {
            tm1 => {
                defs => [ \$xtabel, 'orderdetails', 'v_orderdetails' ],
                cols => {
                    orderlinenumber =>
                        [ 0, 'Art', 1, 'rw', 5, 'ro_center', '_digit:5' ],
                    productcode => [
                        1, 'Code', 0, 'rw', 15, 'find_center', '_alpha_num:15'
                    ],
                    productname => [
                        2, 'Product', 0, 'ro', 37, 'ro_left', '_alpha_num:37'
                    ],
                    quantityordered => [
                        3, 'Quantity', 0, 'rw', 8, 'enter_right', '_digit:5'
                    ],
                    priceeach => [
                        4, 'Price', 0, 'rw', 12, 'enter_right',
                        '_digit_prec:10:2'
                    ],
                    ordervalue => [
                        5, 'Value', 0, 'ro', 12, 'ro_right',
                        '_digit_prec:10:2'
                    ],
                },
            },
        },
    };

    # Required fields: fld_name => [#, Label]
    # If there is no value in the screen for this fields show a dialog message
    $self->{fld_label} = {
        orderdate      => [ 0, '  Order date' ],
        requireddate   => [ 1, '  Required date' ],
        customernumber => [ 2, '  Customer number' ],
    };

    return $eordernumber;
}

sub callback {

    my ( $w1, $self, $p2 ) = @_;

    my $r = $w1->index( 'active', 'row' );
    my $c = $w1->index( 'active', 'col' );

    # Table refresh
    $w1->activate('origin');
    $w1->activate("$r,$c");
    $w1->reread();

    if ( $p2->{$w1} eq 'T1' ) {
        if ( $c == 1 ) {
            my $cols_skip = $self->{cautare}->tDict(
                $p2->{gui},
                'products',
                $r, $c,
                $w1 );
            $cols_skip++;
            $w1->activate("$r,$cols_skip");
        }
        elsif ( $c == 4 ) {
            $self->calculate_order_line( $w1, $r );
            $self->calculate_order( $w1, $r );
            $p2->{add1}->focus;
            $w1->activate( ++$r . ",0" );
        }
        else {
            $w1->activate( "$r," . ++$c );
        }

        # Tk->break;
    }
    $w1->see('active');
}

sub calculate_order_line {

 # +-------------------------------------------------------------------------+
 # | Description: Calculate value                                            |
 # | Parameters :                                                            |
 # +-------------------------------------------------------------------------+

    my $self = $_[0];
    my $xt   = $_[1];
    my $rand = $_[2];

    # print "Row = $rand\n";
    my $cant = $xt->get("$rand,3");    # print "Cant = $cant\n";
    my $pret = $xt->get("$rand,4");    # print "Pret = $pret\n";

    eval {
        if ( defined($cant) and defined($pret) )
        {
            my $valoare = sprintf( "%.2f", ( $cant * $pret ) );
            $xt->set( "$rand,5", $valoare );
            print "Valoare = $valoare\n";
        }
        else {
            warn "Nu am valori!\n";
        }
    };

    # In case of Error
    if ($@) {
        warn "Wrong calculus!: $@";
    }

    # Refreshing the table...
    $xt->configure( -padx => $xt->cget( -padx ) );
}

sub calculate_order {

 # +-------------------------------------------------------------------------+
 # | Description: Calculate order value                                      |
 # | Parameters :                                                            |
 # +-------------------------------------------------------------------------+

    my $self = $_[0];
    my $xt   = $_[1];

    my $valoare = 0;
    my ( $c, $v );

    my $rows_no  = $xt->cget( -rows );
    my $rows_idx = --$rows_no;

    my $rand = 1;
    for ( $rand = 1; $rand <= $rows_idx; $rand++ ) {

        my $val = $xt->get("$rand,5");    # print "Val = $val\n";

        if ( defined $val ) {
            $valoare += $val;             # print "Valoare = $valoare\n";
        }
        else {
            print "No values!\n";
        }
    }

    # Rotunjiri
    $valoare = sprintf( "%.2f", $valoare );

    # Update screen

    # More than one value can be calculated
    my %campuri = ( ordertotal => $valoare );
    while ( ( $c, $v ) = each(%campuri) ) {
        $self->{eobj_rec}->{$c}[3]->delete( 0, 'end' );
        $self->{eobj_rec}->{$c}[3]->insert( 0, $v );
        $self->{eobj_rec}->{$c}[3]->xview('end');
    }
}

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

1; # End of Tpda3::App::Test::Orders
