package Tpda3::Tk::Screen;

# ABSTRACT: Tpda3 Screen base class

use strict;
use warnings;
use Carp;

use Tpda3::Tk::Entry;
#use Tpda3::Tk::Text;

use Tpda3::Utils;
use Tpda3::Tk::TB;
use Tpda3::Config::Screen;

require Tpda3::Tk::Validation;


sub new {
    my ( $class, $args ) = @_;

    my $self = {};

    bless $self, $class;

    $self->{scrcfg}  = Tpda3::Config::Screen->new($args);
    $self->{toolscr} = $args->{toolscr};

    return $self;
}


sub run_screen {
    my ( $self, $nb ) = @_;

    print 'run_screen not implemented in ', __PACKAGE__, "\n";

    return;
}


sub get_controls {
    my ($self, $field) = @_;

    # croak "'get_controls' not implemented.\n"
    #     unless exists $self->{controls}
    #         and scalar %{ $self->{controls} };

    if ($field) {
        return $self->{controls}{$field};
    }
    else {
        return $self->{controls};
    }
}


sub get_tm_controls {
    my ( $self, $tm_ds ) = @_;

    return {} if !exists $self->{tm_controls};

    if ($tm_ds) {
        ( exists $self->{tm_controls}{$tm_ds} )
            ? ( return ${ $self->{tm_controls}{$tm_ds} } )
            : ( croak "No TM $tm_ds in screen!" );
    }
    else {
        return $self->{tm_controls};
    }
}


sub get_rq_controls {
    my $self = shift;

    return {} if !exists $self->{rq_controls};

    return $self->{rq_controls};
}


sub get_toolbar_btn {
    my ( $self, $tm_ds, $name ) = @_;
    return $self->{tb}{$tm_ds}->get_toolbar_btn($name);
}


sub enable_tool {
    my ( $self, $tm_ds, $btn_name, $state ) = @_;

    die "No ToolBar '$tm_ds' ($btn_name)"
        if not defined $self->{tb}{$tm_ds};

    $self->{tb}{$tm_ds}->enable_tool( $btn_name, $state );

    return;
}


sub get_bgcolor {
    my $self = shift;
    return $self->{bg};
}


sub make_toolbar_for_table {
    my ( $self, $name, $tb_frame ) = @_;

    $self->{tb}{$name} = $tb_frame->TB();

    my ($toolbars) = $self->{scrcfg}->scr_toolbar_names($name);
    my $attribs    = $self->{scrcfg}->app_toolbar_attribs($name);

    $self->{tb}{$name}->make_toolbar_buttons( $toolbars, $attribs );

    return;
}


sub tmatrix_add_row {
    my ( $self, $tm_ds ) = @_;

    my $tmx = $self->get_tm_controls($tm_ds);
    $tmx->add_row();
    $self->screen_update();

    return;
}


sub tmatrix_remove_row {
    my ( $self, $tm_ds ) = @_;

    my $tmx = $self->get_tm_controls($tm_ds);
    my $row = $tmx->get_active_row();
    $tmx->remove_row($row) if $row;
    $self->screen_update();

    return;
}


sub app_toolbar_names {
    my ($self, $name) = @_;

    my ($toolbars) = $self->{scrcfg}->scr_toolbar_names($name);
    my $attribs    = $self->{scrcfg}->app_toolbar_attribs;

    return ( $toolbars, $attribs );
}


sub screen_update {
    my $self = shift;
    return;
}


sub toolscr {
    my $self = shift;
    return $self->{toolscr};
}

1;

=head1 SYNOPSIS

    use base 'Tpda3::Tk::Screen';

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
            -label      => 'Customer',
            -foreground => 'blue',
            -labelside  => 'acrosstop',
        )->pack;

        # Fields

        my $lcustomername = $frame1->Label( -text => 'Customer' );
        ...

        my $ecustomername = $frame1->MEntry(
            -width    => 35,
            -validate => 'key',
            -vcmd     => sub {
                $validation->validate_entry( 'customername', @_ );
            },
        );
        ...

        # Entry objects: var_asoc, var_obiect
        # Other configurations in '<screen>.conf'
        $self->{controls} = {
            customername     => [ undef, $ecustomername ],
            customernumber   => [ undef, $ecustomernumber ],
            ...
        };
    }

=head2 new

Constructor method.

=head2 run_screen

The screen layout.

=head2 get_controls

Get a data structure containing references to the widgets.

=head2 get_tm_controls

Get a data structure containing references to table matrix widgets.
If TM Id parameter is provided return a reference to that TM object.

=head2 get_rq_controls

Get a HoA reference data structure with the field names that are
required to have values as keys and labels as values.

Usually all fields from the table marked in the I<SQL> structure as
I<NOT NULL>.

=head2 get_toolbar_btn

Return a toolbar button when we know its name.

=head2 enable_tool

Toggle tool bar button.  If state is defined then set to state do not
toggle.  State can come as 0 | 1 and normal | disabled.

=head2 get_bgcolor

Return the background color of the main window.

Must be setup like this in run_screen method of every screen

 my $gui     = $inreg_p->toplevel;
 $self->{bg} = $gui->cget('-background');

=head2 make_toolbar_for_table

Make toolbar for TableMatrix widget, usually with I<add> and I<remove>
buttons.

=head2 tmatrix_add_row

Add new row to the Tk::TableMatrix widget.

=head2 tmatrix_remove_row

Remove row to the Tk::TableMatrix widget.

=head2 app_toolbar_names

Configuration for toolbar buttons.

Get Toolbar names as array reference from screen config.

=head2 screen_update

Update method. To be overridden in the screen module.

Now called only by L<tmatrix_add_row> and L<tmatrix_remove_row>
methods.

=head2 toolscr

Return the toolscr variable.

=cut
