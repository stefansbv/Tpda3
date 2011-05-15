package Tpda3::Tk::App::Test::Orders;

use strict;
use warnings;

use Tk::widgets qw(DateEntry JComboBox TableMatrix); #  MatchingBE

use base 'Tpda3::Tk::Screen';

use Tpda3::Config;
use Tpda3::Tk::ToolBar;

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

sub run_screen {
    my ( $self, $inreg_p ) = @_;

    my $gui     = $inreg_p->toplevel;
    my $main_p  = $inreg_p->parent;
    $self->{bg} = $gui->cget('-background');

    #- Frame bottom

    my $frm_bl = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Bottom',
        -labelside  => 'acrosstop'
    )->pack(
        -side   => 'bottom',
        -expand => 0,
        -fill   => 'both'
    );

    #- Frame t => Tabel

    my $frm_t = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Bottom',
        -labelside  => 'acrosstop'
    )->pack(
        -side   => 'bottom',
        -expand => 1,
        -fill   => 'both'
    );

    #- Top Left Frame

    my $frame1 = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Top Left',
        -labelside  => 'acrosstop'
    )->pack(
        -side   => 'left',
        -expand => 1,
        -fill   => 'both'
    );

    #- Top Right Frame

    my $frame2 = $inreg_p->LabFrame(
        -foreground => 'blue',
        -label      => 'Comments',
        -labelside  => 'acrosstop'
    )->pack(
        -side   => 'right',
        -expand => 1,
        -fill   => 'both'
    );

    #- Customers

    my $lcustomername = $frame1->Label(
        -text => 'Customer, No',
    );
    $lcustomername->form(
        -top  => [ %0, 0 ],
        -left => [ %0, 0 ],
        -padleft => 5,
    );

    my $ecustomername = $frame1->Entry( -width => 35 );
    $ecustomername->form(
        -top  => [ '&', $lcustomername, 0 ],
        -left => [ %0,  110 ],
    );

    #-+ Customer number (customernumber)

    my $ecustomernumber = $frame1->Entry(
        -width              => 6,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $ecustomernumber->form(
        -top  => [ '&',            $lcustomername, 0 ],
        -left => [ $ecustomername, 5 ],
        -padright => 5,
    );

    #- Ordernumber (ordernumber)

    my $lordernumber = $frame1->Label( -text => 'Order ID' );
    $lordernumber->form(
        -top  => [ $lcustomername, 8 ],
        -left => [ %0,             0 ],
        -padleft => 5,
    );

    my $eordernumber = $frame1->Entry(
        -width              => 10,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eordernumber->form(
        -top  => [ '&', $lordernumber, 0 ],
        -left => [ %0,  110 ],
    );

    #-+ Orderdate (orderdate)

    my $vorderdate;
    my $dorderdate = $frame1->DateEntry(
        # -daynames   => \@daynames,
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
        -top   => [ '&', $eordernumber,   0 ],
        -right => [ %100, -5 ],
    );

    my $lorderdate = $frame1->Label( -text => 'Order date' );
    $lorderdate->form(
        -top   => [ '&',         $lordernumber, 0 ],
        -right => [ $dorderdate, -20 ],
        -padleft => 5,
    );

    #- Requireddate (requireddate)

    my $lrequireddate = $frame1->Label( -text => 'Required date' );
    $lrequireddate->form(
        -top  => [ $lordernumber, 8 ],
        -left => [ %0,            0 ],
        -padleft => 5,
    );

    my $vrequireddate;
    my $drequireddate = $frame1->DateEntry(
        # -daynames   => \@daynames,
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
        -left => [ %0,  110 ],
    );

    #-+ Shippeddate (shippeddate)

    my $lshippeddate = $frame1->Label( -text => 'Shipped date' );
    $lshippeddate->form(
        -top  => [ '&', $lrequireddate,  0 ],
        -left => [ '&', $lorderdate,     0 ],
        -padleft => 5,
    );

    my $vshippeddate;
    my $dshippeddate = $frame1->DateEntry(
        # -daynames   => \@daynames,
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
        -right => [ %100, -5 ],
    );

    #- Status code (statuscode)

    my $lstatuscode = $frame1->Label( -text => 'Status' );
    $lstatuscode->form(
        -top  => [ $lrequireddate, 8 ],
        -left => [ %0,             0 ],
        -padleft => 5,
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
        -left => [ %0,  110 ],
        -padbottom => 5,
    );

    # my $vstatuscode;
    # my $lvstatuscode = [ { value => 'no value', label => 'not set' } ];
    # my $bstatuscode = $frame1->MatchingBE(
    #     # -entrywidth         => 15,         # can't set :(
    #     -relief             => 'sunken',
    #     -disabledbackground => $self->{bg},
    #     -disabledforeground => 'black',
    #     -labels_and_values  => $lvstatuscode,
    #     -value_variable     => \$vstatuscode,
    # );
    # $bstatuscode->form(
    #     -top  => [ '&', $lstatuscode, 0 ],
    #     -left => [ %0,  110 ],
    # );

    #-- Font
    my $my_font = $eordernumber->cget('-font');

    #- Comments (comments)

    my $tcomments = $frame2->Scrolled(
        'Text',
        -width      => 33,
        -height     => 7,
        -wrap       => 'word',
        -scrollbars => 'e',
        -font       => $my_font,
    );

    $tcomments->form(
        -left => [ %0, 0 ],
        -top  => [ %0, 0 ],
        -padx => 5,
    );

    #--- Details
    #-
    #

    #-- Toolbar

    my $tbf1 = $frm_t->Frame();
    $tbf1->pack(
        -anchor => 'n',
        -expand => 'n',
        -fill   => 'x',
    );

    # TODO: move this from here
    $self->{tb} = Tpda3::Tk::ToolBar->new($tbf1);

    my $cfg = Tpda3::Config->instance();

    my $toolbar = [ qw(tb2ad tb2rm) ];       # Order of creation
    my $attribs = $cfg->toolbar2;

    $self->{tb}->make_toolbar_buttons($toolbar, $attribs);

    #- TableMatrix
    my $xtvar = {};                          # Must init as hash reference!
    my $xtable = $frm_t->Scrolled(
        'TableMatrix',
        -rows           => 5,
        -cols           => 5,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -validate       => 1,
        -variable       => $xtvar,
        -selectmode     => 'single',
        -resizeborders  => 'none',
        -colstretchmode => 'unset',
        -bg             => 'white',
        -scrollbars     => 'osw',
    );
    $xtable->pack( -expand => 1, -fill => 'both' );

    #- Bindings

    # Make the active area move after we press return: Have to use
    # class binding here so that we override the default return
    # binding
    my $t1     = $xtable->Subwidget('scrolled');
    my $params = {
        $t1 => 'T1',
        gui => $gui,
    };

    $xtable->bind( 'Tk::TableMatrix',
                   '<Return>' => [ \&callback, $self, $params ] );

    #- Ordertotal (ordertotal)

    my $eordertotal = $frm_bl->Entry(
        -width   => 12,
        -justify => 'right',
    );
    $eordertotal->form(
        -top   => [ %0,   0 ],
        -right => [ %100, -5 ],
        -padbottom => 5,
    );

    my $lordertotal = $frm_bl->Label( -text => 'Order total' );
    $lordertotal->form(
        -top   => [ '&',          $eordertotal, 0 ],
        -right => [ $eordertotal, -15 ],
    );

    #---

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'orders.conf'
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

    # TableMatrix objects; just one for now :)
    $self->{tm_controls} = {
        rec => {
            tm1 => \$xtable,
        },
    };

    # Required fields: fld_name => [#, Label]
    # If there is no value in the screen for this fields show a dialog message
    $self->{req_controls} = {
        orderdate      => [ 0, '  Order date' ],
        requireddate   => [ 1, '  Required date' ],
        customernumber => [ 2, '  Customer number' ],
    };

    # This makes TableMatrix expand !!! or not :(
    $xtable->update;

    return;
}

=head2 callback

Callback for table matrix.

=cut

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
            # my $cols_skip = $self->{cautare}->tDict(
            #     $p2->{gui},
            #     'products',
            #     $r, $c,
            #     $w1 );
            # $cols_skip++;
            # $w1->activate("$r,$cols_skip");
        }
        elsif ( $c == 4 ) {
            # $self->calculate_order_line( $w1, $r );
            # $self->calculate_order( $w1, $r );
            # $p2->{add1}->focus;
            $w1->activate( ++$r . ",0" );
        }
        else {
            $w1->activate( "$r," . ++$c );
        }

        # Tk->break;
    }
    $w1->see('active');
}

=head2 calculate_order_line

Calculate order line.

=cut

sub calculate_order_line {
    my ($self, $xt, $rand) = @_;

    # print "Row = $rand\n";
    my $cant = $xt->get("$rand,3");    # print "Cant = $cant\n";
    my $pret = $xt->get("$rand,4");    # print "Pret = $pret\n";

    eval {
        if ( defined($cant) and defined($pret) ) {
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

=head2 calculate_order

Calculate order values.

=cut

sub calculate_order {
    my ($self, $xt) = @_;

    my $rows_no  = $xt->cget( -rows );
    my $rows_idx = --$rows_no;

    my $row   = 1;
    my $value = 0;
    for ( $row = 1; $row <= $rows_idx; $row++ ) {

        my $val = $xt->get("$row,5");    # print "Val = $val\n";

        if ( defined $val ) {
            $value += $val;              # print "Value = $value\n";
        }
        else {
            print "No values!\n";
        }
    }

    # Rounding to 2 decimals
    $value = sprintf( "%.2f", $value );

    # Add more pairs if needed
    my %fields = ( ordertotal => $value );

    # Update controls
    while ( my ( $c, $v ) = each(%fields) ) {
        $self->{controls}->{$c}[3]->delete( 0, 'end' );
        $self->{controls}->{$c}[3]->insert( 0, $v );
        $self->{controls}->{$c}[3]->xview('end');
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

1; # End of Tpda3::Tk::App::Test::Orders
