package Tpda3::Tk::Dialog::SSelect;

use strict;
use warnings;
use utf8;

use Tk;

use Tpda3::Config;
#use Tpda3::Tk::TB;
use Tpda3::Tk::TM;
use Tpda3::Utils;

use base q{Tpda3::Tk::Screen};

=head1 NAME

Tpda3::Tk::Dialog::RepMan - Dialog for preview and print RepMan reports.

=head1 VERSION

Version 0.57

=cut

our $VERSION = 0.57;

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Help;

    my $fd = Tpda3::Tk::Dialog::Help->new;

    $fd->search($self);

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my $class = shift;

    return bless( {}, $class );
}

=head2 select_dialog

Define and show select dialog.

=cut

sub select_dialog {
    my ( $self, $view, $para, $filter ) = @_;

    #--- Dialog Box

    my $dlg = $view->DialogBox(
        -title   => 'Select dialog',
        -buttons => [ 'Load', 'Cancel' ],
    );

    #-- Key bindings

    $dlg->bind( '<Escape>', sub { $dlg->Subwidget('B_Cancel')->invoke } );
    $dlg->bind( '<Alt-r>' , sub { $dlg->Subwidget('B_Clear' )->invoke } );

    #-- Main frame

    my $f1d = 110;              # distance from left

    #- Toolbar frame

    my $tbf0 = $dlg->Frame();
    $tbf0->pack(
        -side   => 'top',
        -anchor => 'nw',
        -fill   => 'x',
    );

    my $bg = $dlg->cget('-background');

    # Frame for main toolbar
    my $tbf1 = $tbf0->Frame();
    $tbf1->pack( -side => 'left', -anchor => 'w' );

    #- Main frame

    my $mf = $dlg->Frame();
    $mf->pack(
        -side   => 'top',
        -expand => 1,
        -fill   => 'both',
    );

    #-  Frame top - TM

    my $frm_top = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'List',
        -labelside  => 'acrosstop'
    )->pack(
        -expand => 1,
        -fill   => 'both',
    );

    my $xtvar1 = {};
    $self->{_tm} = $frm_top->Scrolled(
        'TM',
        -rows           => 5,
        -cols           => 3,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -variable       => $xtvar1,
        -selectmode     => 'single',
        -selecttype     => 'row',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -colstretchmode => 'unset',
        -bg             => 'white',
        -scrollbars     => 'osw',
    );
    $self->{_tm}->pack(
        -expand => 1,
        -fill => 'both',
    );

    #-- Bindings for selection handling

    # Clean up if mouse leaves the widget
    $self->{_tm}->bind(
        '<FocusOut>',
        sub {
            my $w = shift;
            $w->selectionClear('all');
        }
    );

    # Highlight the cell under the mouse
    $self->{_tm}->bind(
        '<Motion>',
        sub {
            my $w  = shift;
            my $Ev = $w->XEvent;
            if ( $w->selectionIncludes( '@' . $Ev->x . "," . $Ev->y ) ) {
                Tk->break;
            }
            $w->selectionClear('all');
            $w->selectionSet( '@' . $Ev->x . "," . $Ev->y );
            Tk->break;
        }
    );

    # MouseButton 1 toggles the value of the cell
    $self->{_tm}->bind(
        '<1>',
        sub {
            my $w = shift;
            $w->focus;
            my ($rc) = @{ $w->curselection };
            my ( $r, $c ) = split( ',', $rc );
            $self->{_tm}->set_selected($r);
            # $self->load_report_details($view);
        }
    );

    # Entry objects
    $self->{controls} = {};

    #-- TM header

    # my $header = $self->{scrcfg}->dep_table_header_info('tm2');

    # $self->{_tm}->init( $frm_top, $header );

    # $self->load_report_list($view, $header->{selectorcol} );

    # $self->{_tm}->configure(-state => 'disabled');

    # $self->load_report_details($view);

    #---

    my $result = $dlg->Show;
    my $ind_cod;

    if ( $result =~ /Load/i ) {

        # Sunt inreg. in lista?
        # eval { $ind_cod = $self->{box}->curselection(); };
        # if ($@) {
        #     warn "Error: $@";

        #     return;
        # }
        # else {
        #     unless ($ind_cod) { $ind_cod = 0; }
        # }
        # my @values = $self->{box}->getRow($ind_cod);

        # #- Prepare data and return as hash reference

        # my $row_data = {};
        # for ( my $i = 0; $i < @columns; $i++ ) {
        #     $row_data->{ $columns[$i] } = $values[$i];
        # }

        # return $row_data;
    }
    else {
        return;
    }
}

1;
