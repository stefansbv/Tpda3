package Tpda3::Wx::App::Test::Orders;

use strict;
use warnings;

use Wx qw{:everything};
use Wx::XRC;

use base 'Tpda3::Wx::Screen';

use Wx::Event qw(EVT_DATE_CHANGED);
use Wx::Calendar;
use Wx::ArtProvider qw(:artid);

use Tpda3::Wx::Factory;

use Tpda3::Wx::ComboBox;
use Tpda3::Wx::Grid;
use Tpda3::Wx::Grid::DataTable;

Wx::XmlResource::AddSubclassFactory( Tpda3::Wx::Factory->new );

=head1 NAME

Tpda3::App::Test::Orders screen

=head1 VERSION

Version 0.67

=cut

our $VERSION = 0.67;

=head1 SYNOPSIS

    require Tpda3::App::Test::Orders;

    my $scr = Tpda3::App::Test::Orders->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout.

=cut

sub run_screen {
    my ( $self, $nb ) = @_;

    my $rec_page = $nb->GetPage(0);
    my $det_page = $nb->GetPage(2);
    #$self->{view} = $nb->GetGrandParent();
    $self->{view} = $nb->GetParent();
    $self->{bg}   = $rec_page->GetBackgroundColour();

    $self->{cfg} = Tpda3::Config->instance();

    # TODO: use Wx::Perl::TextValidator

    my $res = Wx::XmlResource->new;
    $res->InitAllHandlers();
    my $res_file = $self->{cfg}->resource_path_for( 'Orders.xrc', 'res' );
    die "XRC file not found: $res_file" unless $res_file;
    $res->Load($res_file);

    my $main_hbox_sz = Wx::BoxSizer->new( Wx::wxHORIZONTAL );

    $self->{frame} = $res->LoadPanel($rec_page, 'Orders');

    $main_hbox_sz->Add( $self->{frame}, 1, wxGROW );
    $rec_page->SetSizer( $main_hbox_sz );

    my $vorderdate = Wx::DateTime->new();
    my $vrequireddate = Wx::DateTime->new();
    my $vshippeddate = Wx::DateTime->new();

    my $ecustomername   = $self->XRC('ecustomername');
    my $ecustomernumber = $self->XRC('ecustomernumber');
    my $eordernumber    = $self->XRC('eordernumber');
    my $dorderdate      = $self->XRC('dorderdate');
    my $drequireddate   = $self->XRC('drequireddate');
    my $dshippeddate    = $self->XRC('dshippeddate');
    my $bstatuscode     = $self->XRC('bstatuscode');
    my $ecomments       = $self->XRC('ecomments');
    my $eordertotal     = $self->XRC('eordertotal');

    #-- Layout end

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'orders.conf'
    $self->{controls} = {
        customername   => [ undef, $ecustomername ],
        customernumber => [ undef, $ecustomernumber ],
        ordernumber    => [ undef, $eordernumber ],
        orderdate      => [ undef, $dorderdate ],
        requireddate   => [ undef, $drequireddate ],
        shippeddate    => [ undef, $dshippeddate ],
        statuscode     => [ undef, $bstatuscode ],
        comments       => [ undef, $ecomments ],
        ordertotal     => [ undef, $eordertotal ],
    };

    # Grid objects; just one for now :)
    #$self->{tm_controls} = { rec => { tm1 => \$table, }, };

    return;
}

sub XRC {
    my ( $self, $object ) = @_;

    return  $self->{frame}->FindWindow(Wx::XmlResource::GetXRCID($object) );
}

sub gbpos { Wx::GBPosition->new(@_) }

sub gbspan { Wx::GBSpan->new(@_) }

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::App::Test::Orders
