package Tpda3::Tk::Dialog::SSelect;

use strict;
use warnings;
use utf8;

use Tk;

use Tpda3::Config;
use Tpda3::Tk::TB;
use Tpda3::Tk::TM;
use Tpda3::Utils;

use base q{Tpda3::Tk::Screen};

=head1 NAME

Tpda3::Tk::Dialog::RepMan - Dialog for preview and print RepMan reports.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Help;

    my $fd = Tpda3::Tk::Dialog::Help->new;

    $fd->search($self);

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    $self->{tb4} = {};       # ToolBar
    $self->{tlw} = {};       # TopLevel
    $self->{_tm} = undef;    # TableMatrix
    $self->{_rl} = undef;    # report titles list
    $self->{_rd} = undef;    # report details

    return $self;
}

=head2 search_dialog

Define and show search dialog.

=cut

sub run_screen {
    my ( $self, $view ) = @_;

    $self->{tlw} = $view->Toplevel();
    $self->{tlw}->title('Select');
#    $self->{tlw}->geometry('480x520');

    my $f1d = 110;              # distance from left

    #- Toolbar frame

    my $tbf0 = $self->{tlw}->Frame();
    $tbf0->pack(
        -side   => 'top',
        -anchor => 'nw',
        -fill   => 'x',
    );

    my $bg = $self->{tlw}->cget('-background');

    # Frame for main toolbar
    my $tbf1 = $tbf0->Frame();
    $tbf1->pack( -side => 'left', -anchor => 'w' );

    #-- ToolBar

    $self->{tb4} = $tbf1->TB();

    my $attribs = {
        'tb4pr' => {
            'tooltip' => 'Preview and print report',
            'icon'    => 'fileprint16',
            'sep'     => 'none',
            'help'    => 'Preview and print report',
            'method'  => sub { $self->preview_report(); },
            'type'    => '_item_normal',
            'id'      => '20101',
        },
        'tb4qt' => {
            'tooltip' => 'Close',
            'icon'    => 'actexit16',
            'sep'     => 'after',
            'help'    => 'Quit',
            'method'  => sub { $self->dlg_exit; },
            'type'    => '_item_normal',
            'id'      => '20102',
        }
    };

    my $toolbars = [ 'tb4pr', 'tb4qt', ];

    $self->{tb4}->make_toolbar_buttons( $toolbars, $attribs );

    #-- end ToolBar

    #-- StatusBar

    my $sb = $self->{tlw}->StatusBar();

    my ($label_l, $label_d, $label_r);

    $sb->addLabel(
        -relief       => 'flat',
        -textvariable => \$label_l,
    );

    $sb->addLabel(
        -width        => '10',
        -anchor       => 'center',
        -textvariable => \$label_d,
        -side         => 'right'
    );

    $sb->addLabel(
        -width        => '10',
        -anchor       => 'center',
        -textvariable => \$label_r,
        -side         => 'right',
        -foreground   => 'blue'
    );

    #-- end StatusBar

    #- Main frame

    my $mf = $self->{tlw}->Frame();
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

    my $header = $self->{scrcfg}->dep_table_header_info('tm2');

    $self->{_tm}->init( $frm_top, $header );

    # $self->load_report_list($view, $header->{selectorcol} );

    $self->{_tm}->configure(-state => 'disabled');

    # $self->load_report_details($view);

    return;
}

=head2 dlg_exit

Quit Dialog.

=cut

sub dlg_exit {
    my $self = shift;

    $self->{tlw}->destroy;

    return;
}

1;
