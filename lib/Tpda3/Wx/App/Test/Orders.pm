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

Version 0.69

=cut

our $VERSION = 0.69;

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
    $self->{view} = $nb->GetParent();
    $self->{bg}   = $rec_page->GetBackgroundColour();

    $self->{cfg} = Tpda3::Config->instance();

    # TODO: use Wx::Perl::TextValidator

    my $res = Wx::XmlResource->new;
    $res->InitAllHandlers();
    my $res_file = $self->{cfg}->resource_path_for( 'Orders.xrc', 'res' );
    die "XRC file not found: $res_file" unless $res_file;
    $res->Load($res_file);

    my $main_sz = Wx::FlexGridSizer->new( 2, 1, 0, 0 );
    my $top_sz  = Wx::BoxSizer->new(wxVERTICAL);
    my $bot_sz  = Wx::BoxSizer->new(wxHORIZONTAL);

    $main_sz->AddGrowableCol(0);
    $main_sz->AddGrowableRow(1);

    $self->{frame} = $res->LoadPanel($rec_page, 'Orders');

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

    $top_sz->Add( $self->{frame}, 1, wxALL | wxEXPAND, 5 );

    #-- Button bar
    my $button_sz  = Wx::BoxSizer->new(wxHORIZONTAL);

    foreach my $name (qw(actitemadd16 actitemdelete16)) {
        my $bmp  = $self->make_bitmap($name);
        my $button = Wx::BitmapButton->new( $rec_page, -1, $bmp, [ -1, -1 ] );
        $button_sz->Add( $button, 0, wxALIGN_CENTRE | wxGROW | wxALL, 2 );
    }

    #-- Table
    my $columns = $self->{scrcfg}->deptable( 'tm1', 'columns' );
    my $table = Tpda3::Wx::Grid->new( $rec_page, $columns );

    my $article_sb  = Wx::StaticBox->new( $rec_page, -1, ' Articles ' );
    my $article_sbs = Wx::StaticBoxSizer->new( $article_sb, wxVERTICAL, );

    $article_sbs->Add( $button_sz, 0 );
    $article_sbs->Add( $table, 1, wxALL | wxEXPAND, 5 );
    $bot_sz->Add($article_sbs, 1, wxALL | wxEXPAND, 5 );

    #-- Layout

    $main_sz->Add( $top_sz, 1, wxALL | wxGROW, 5 );
    $main_sz->Add( $bot_sz, 1, wxALL | wxGROW, 5 );

    $rec_page->SetSizerAndFit( $main_sz );

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
    $self->{tm_controls} = { rec => { tm1 => \$table, }, };

    return;
}

sub XRC {
    my ( $self, $object ) = @_;

    return  $self->{frame}->FindWindow(Wx::XmlResource::GetXRCID($object) );
}

# sub gbpos { Wx::GBPosition->new(@_) }

# sub gbspan { Wx::GBSpan->new(@_) }

sub make_bitmap {
    my ( $self, $icon ) = @_;

    my $ico_path = $self->{cfg}->cfico;

    my $bmp = Wx::Bitmap->new( $ico_path . "/$icon.gif", wxBITMAP_TYPE_ANY, );

    return $bmp;
}

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
