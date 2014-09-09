package Tpda3::Tk::App::Test::Orders;

# ABSTRACT: The Tpda3::App::Test::Orders screen

use strict;
use warnings;

use Tk::widgets qw(DateEntry JComboBox);    #  MatchingBE

use base 'Tpda3::Tk::Screen';

use Tpda3::Tk::TM;


sub run_screen {
    my ( $self, $nb ) = @_;

    my $rec_page = $nb->page_widget('rec');
    my $det_page = $nb->page_widget('det');
    $self->{view} = $nb->toplevel;
    $self->{bg}   = $self->{view}->cget('-background');

    my $validation
        = Tpda3::Tk::Validation->new( $self->{scrcfg}, $self->{view} );

    my $date_format = $self->{scrcfg}->app_dateformat();

    #- Top Frame

    my $frm_top = $rec_page->Frame()->pack(
        -expand => 0,
        -fill   => 'x',
    );

    #- Top Left Frame

    my $frame1 = $frm_top->LabFrame(
        -foreground => 'blue',
        -label      => 'Order',
        -labelside  => 'acrosstop'
    )->pack(
        -side   => 'left',
        -expand => 0,
        -fill   => 'both'
    );

    #- Top Right Frame

    my $frame2 = $frm_top->LabFrame(
        -foreground => 'blue',
        -label      => 'Comments',
        -labelside  => 'acrosstop'
    )->pack(
        -side   => 'left',
        -expand => 1,
        -fill   => 'both'
    );

    #- Frame t => Tabel

    my $frm_t = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Articles',
        -labelside  => 'acrosstop'
    )->pack(
        -expand => 1,
        -fill   => 'both'
    );

    #- Frame bottom

    my $frm_bl = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Order total',
        -labelside  => 'acrosstop'
    )->pack(
        -side   => 'bottom',
        -expand => 0,
        -fill   => 'x'
    );

    #- Customers

    my $lcustomername = $frame1->Label( -text => 'Customer, No', );
    $lcustomername->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 5,
    );

    my $ecustomername = $frame1->MEntry( -width => 35 );
    $ecustomername->form(
        -top  => [ '&', $lcustomername, 0 ],
        -left => [ %0,  110 ],
    );

    #-+ Customer number (customernumber)

    my $ecustomernumber = $frame1->MEntry(
        -width              => 6,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $ecustomernumber->form(
        -top      => [ '&',            $lcustomername, 0 ],
        -left     => [ $ecustomername, 5 ],
        -padright => 5,
    );

    #- Ordernumber (ordernumber)

    my $lordernumber = $frame1->Label( -text => 'Order ID' );
    $lordernumber->form(
        -top     => [ $lcustomername, 8 ],
        -left    => [ %0,             0 ],
        -padleft => 5,
    );

    my $eordernumber = $frame1->MEntry(
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
            Tpda3::Utils->dateentry_parse_date( $date_format, @_ );
        },
        -formatcmd => sub {
            Tpda3::Utils->dateentry_format_date( $date_format, @_ );
        },
        -todaybackground => 'lightgreen',
    );

    $dorderdate->form(
        -top   => [ '&',  $eordernumber, 0 ],
        -right => [ %100, -5 ],
    );

    my $lorderdate = $frame1->Label( -text => 'Order date' );
    $lorderdate->form(
        -top     => [ '&',         $lordernumber, 0 ],
        -right   => [ $dorderdate, -20 ],
        -padleft => 5,
    );

    #- Requireddate (requireddate)

    my $lrequireddate = $frame1->Label( -text => 'Required date' );
    $lrequireddate->form(
        -top     => [ $lordernumber, 8 ],
        -left    => [ %0,            0 ],
        -padleft => 5,
    );

    my $vrequireddate;
    my $drequireddate = $frame1->DateEntry(

        # -daynames   => \@daynames,
        -variable   => \$vrequireddate,
        -arrowimage => 'calmonth16',
        -parsecmd   => sub {
            Tpda3::Utils->dateentry_parse_date( $date_format, @_ );
        },
        -formatcmd => sub {
            Tpda3::Utils->dateentry_format_date( $date_format, @_ );
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
        -top     => [ '&', $lrequireddate, 0 ],
        -left    => [ '&', $lorderdate,    0 ],
        -padleft => 5,
    );

    my $vshippeddate;
    my $dshippeddate = $frame1->DateEntry(

        # -daynames   => \@daynames,
        -variable   => \$vshippeddate,
        -arrowimage => 'calmonth16',
        -parsecmd   => sub {
            Tpda3::Utils->dateentry_parse_date( $date_format, @_ );
        },
        -formatcmd => sub {
            Tpda3::Utils->dateentry_format_date( $date_format, @_ );
        },
        -todaybackground => 'lightgreen',
    );

    $dshippeddate->form(
        -top   => [ '&',  $lshippeddate, 0 ],
        -right => [ %100, -5 ],
    );

    #- Status code (statuscode)

    my $lstatuscode = $frame1->Label( -text => 'Status' );
    $lstatuscode->form(
        -top     => [ $lrequireddate, 8 ],
        -left    => [ %0,             0 ],
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
        -top       => [ '&', $lstatuscode, 0 ],
        -left      => [ %0,  110 ],
        -padbottom => 6,
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
        -height     => 6,
        -wrap       => 'word',
        -scrollbars => 'e',
        -font       => $my_font,
    )->pack(
        -expand => 1,
        -fill   => 'x',
        -padx => 5,
        -pady => 5,
    );

    #--- Details
    #-
    #

    #-- Toolbar
    $self->make_toolbar_for_table( 'tm1', $frm_t );

    my $header = $self->{scrcfg}->dep_table_header_info('tm1');

    #-- TableMatrix

    my $xtvar1 = {};
    my $xtable = $frm_t->Scrolled(
        'TM',
        -rows           => 6,
        -cols           => 1,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -variable       => $xtvar1,
        -selectmode     => 'single',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -bg             => 'white',
        -scrollbars     => 'osw',
        -validate       => 1,
        -vcmd           => sub { $validation->validate_table_cell('tm1',@_) },
    );

    $xtable->pack( -expand => 1, -fill => 'both' );

    $xtable->init( $frm_t, $header );

    #- Ordertotal (ordertotal)

    my $eordertotal = $frm_bl->MEntry(
        -width   => 12,
        -justify => 'right',
    );
    $eordertotal->form(
        -top       => [ %0,   0 ],
        -right     => [ %100, -5 ],
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
    $self->{tm_controls} = { tm1 => \$xtable };

    # Required fields: fld_name => [#, Label]
    # If there is no value in the screen for this fields show a dialog message
    $self->{rq_controls} = {
        orderdate      => [ 0, '  Order date' ],
        requireddate   => [ 1, '  Required date' ],
        customernumber => [ 2, '  Customer number' ],
    };

    # Prepare screen configuration data for tables
    foreach my $tm_ds ( keys %{ $self->{tm_controls} } ) {
        $validation->init_cfgdata($tm_ds);
    }

    return;
}


sub calculate_order_line {
    my ( $self, $row ) = @_;

    my $xt = ${ $self->{tm_controls}{tm1} };

    $self->{view}->set_status( '', 'ms'); # clear status message

    my $quantityordered = $xt->get("$row,3");
    my $priceeach       = $xt->get("$row,4");

    # Numeric validation would be appropriate here
    eval {
        if ( defined($quantityordered) and defined($priceeach) )
        {
            my $orderlinevalue
                = sprintf( "%.2f", ( $quantityordered * $priceeach ) );
            $xt->set( "$row,5", $orderlinevalue );
        }
        else {
            $self->{view}->set_status( 'No valid data.', 'ms' );
        }
    };

    # In case of Error
    if ($@) {
        $self->{view}->set_status( 'Calculus went wrong!', 'ms');
    }

    # Refreshing the table...
    $xt->configure( -padx => $xt->cget('-padx') );

    $self->calculate_order($xt);

    return;
}


sub calculate_order {
    my ( $self, $xt ) = @_;

    $self->{view}->set_status( '', 'ms'); # clear status message

    my $rows_no  = $xt->cget('-rows');
    my $rows_idx = --$rows_no;

    my $row            = 1;
    my $orderlinevalue = 0;
    for ( $row = 1; $row <= $rows_idx; $row++ ) {

        my $val = $xt->get("$row,5");

        if ( defined($val) ) {
            $orderlinevalue += $val;
        }
        else {
            $self->{view}->set_status( 'No valid data.', 'ms');
        }
    }

    # Rounding to 2 decimals
    $orderlinevalue = sprintf( "%.2f", $orderlinevalue );

    # Add more pairs if needed
    my %fields = (
         ordertotal => $orderlinevalue,
    );

    # Update controls
    foreach my $c ( keys %fields ) {
        my $v = $fields{$c};
        $self->{controls}{$c}[1]->delete( 0, 'end' );
        $self->{controls}{$c}[1]->insert( 0, $v );
        $self->{controls}{$c}[1]->xview('end');
    }

    return;
}


sub on_load_record {
    my $self = shift;
    $self->{view}->set_status( '', 'ms'); # clear status message
    return;
}


sub on_mode_add {
    my $self = shift;
    return;
}


sub on_mode_edit {
    my $self = shift;

    return;
}


sub on_mode_idle {
    my $self = shift;

    return;
}

1;

=head1 SYNOPSIS

    require Tpda3::App::Test::Orders;

    my $scr = Tpda3::App::Test::Orders->new;

    $scr->run_screen($args);

=head2 run_screen

The screen layout.

=head2 calculate_order_line

Calculate order line.

=head2 calculate_order

Calculate order values.

=head2 on_load_record

On load record event.

=head2 on_mode_add

On mode add event.

=head2 on_mode_edit

On mode edit event.

=head2 on_mode_idle

On mode idle event.

=cut
