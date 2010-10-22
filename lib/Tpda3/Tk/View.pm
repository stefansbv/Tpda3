package Tpda3::Tk::View;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);

use File::Spec::Functions qw(abs2rel);
use Tk;
use Tk::widgets qw(ToolBar NoteBook StatusBar Dialog
  Checkbutton LabFrame MListbox JComboBox Font);

use base 'Tk::MainWindow';

use Tpda3::Config;

=head1 NAME

Tpda3::Tk::App - Tk Perl application class

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Tk::Notebook;

    $self->{_nb} = Tpda3::Tk::Notebook->new( $gui );


=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;
    my $model = shift;

    #- The MainWindow

    my $self = __PACKAGE__->SUPER::new(@_);

    $self->geometry('490x80+672+320');
    $self->title(" Tpda ");

    $self->{_model} = $model;

    #-- Menu
    $self->_create_menu();

    #-- ToolBar
    $self->_create_toolbar();

    #-- Statusbar
    $self->_create_statusbar();

    #-- Notebook
    # $self->{_nb} = Tpda3::Tk::Notebook->new( $self );

    $self->_set_model_callbacks();

    return $self;
}

=head2 _model

Return model instance

=cut

sub _model {
    my $self = shift;

    $self->{_model};
}

=head2 _set_model_callbacks

Define the model callbacks

=cut

sub _set_model_callbacks {
    my $self = shift;

    my $co = $self->_model->get_connection_observable;
    $co->add_callback(
        sub { $self->toggle_tool_check( 'tb_cn', $_[0] ) } );

    my $em = $self->_model->get_findmode_observable;
    $em->add_callback(
        sub { $self->toggle_tool_check( 'tb_fm', $_[0] ) } );

    my $ad = $self->_model->get_addmode_observable;
    $ad->add_callback(
        sub { $self->toggle_tool_check( 'tb_ad', $_[0] ) } );

    my $so = $self->_model->get_stdout_observable;
    $so->add_callback( sub { $self->log_msg( $_[0] ) } );

    my $st = $self->_model->get_statusmsg_observable;
    $st->add_callback( sub { $self->set_status(@_) } );
}

=head2 log_msg

Log messages

=cut

sub log_msg {
    my ( $self, $msg ) = @_;

    my $log = get_logger();

    $log->info($msg);
}

=head2 create_menu

Create the menu

=cut

sub _create_menu {
    my $self = shift;

    ### Menu

    ## Menu bar

    $self->{_menu} = $self->Menu();

    # Get MenuBar atributes
    my $cfg     = Tpda3::Config->instance();
    my $attribs = $cfg->menubar;

    #-- Sort by id
    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{id} } keys %{$attribs};

    #- Sort with  ST
    my @attribs = map { $_->[0] }
      sort { $a->[1] <=> $b->[1] }
      map { [ $_ => $temp{$_} ] }
      keys %temp;

    # Create menus
    foreach my $menu_name (@attribs) {

        $self->{_menu}{$menu_name} = $self->{_menu}->Menu();

        my @popups = sort { $a <=> $b } keys %{ $attribs->{$menu_name}{popup} };
        foreach my $id (@popups) {
            $self->make_popup_item(
                $self->{_menu}{$menu_name},
                $attribs->{$menu_name}{popup}{$id},
            );
        }

        $self->{_menu}->add(
            'cascade',
            -menu      => $self->{_menu}{$menu_name},
            -label     => $attribs->{$menu_name}{label},
            -underline => $attribs->{$menu_name}{underline},
        );
    }

    $self->configure( -menu => $self->{_menu} );

    $self->bind( '<Alt-x>' => sub { $self->on_quit } );
}

=head2 make_popup_item

Make popup item

=cut

sub make_popup_item {
    my ( $self, $menu, $item ) = @_;

    $menu->add('separator') if $item->{sep} eq 'before';

    $self->{_menu}{ $item->{name} } = $menu->command(
        -label       => $item->{label},
        -accelerator => $item->{key},
        -underline   => $item->{underline},
    );

    $menu->add('separator') if $item->{sep} eq 'after';
}

=head2 get_menu_popup_item

Return a menu popup by name

=cut

sub get_menu_popup_item {
    my ( $self, $name ) = @_;

    return $self->{_menu}{$name};
}

=head2 create_statusbar

Create the status bar

=cut

sub _create_statusbar {
    my $self = shift;

    my $sb = $self->StatusBar();

    # Dummy label for left space
    my $ldumy = $sb->addLabel(
        -width  => 1,
        -relief => 'flat',
    );

    $self->{_sb}{ll} = $sb->addLabel( -relief => 'flat' );

    $self->{_sb}{cn} = $sb->addLabel(
        -width  => 20,
        -relief => 'raised',
        -anchor => 'center',
        -side   => 'right',
    );

    $self->{_sb}{ld} = $sb->addLabel(
        -width  => 15,
        -anchor => 'center',
        -side   => 'right',
    );

    $self->{_sb}{pr} = $sb->addProgressBar(
        -length     => 100,
        -from       => 0,
        -to         => 100,
        -variable   => \$self->{progres},
        -foreground => 'blue',
    );

    $self->{_sb}{lr} = $sb->addLabel(
        -width      => 6,
        -anchor     => 'center',
        -side       => 'right',
        -foreground => 'blue',
        -background => 'yellow',
    );
}

=head2 get_statusbar

Return the status bar handler

=cut

sub get_statusbar {
    my ( $self, $sb_id ) = @_;

    return $self->{_sb}{$sb_id};
}

=head2 set_status

Set message to status bar

=cut

sub set_status {
    my ( $self, $msg, $color ) = @_;

    my ( $text, $sb_id ) = split ':', $msg;    # Work around until I learn how
                                               # to pass other parameters ;)

    my $sb = $self->get_statusbar($sb_id);

    if ( $sb_id eq 'cn' ) {
        $sb->configure( -image => $text ) if defined $text;
    }
    else {
        $sb->configure( -textvariable => \$text ) if defined $text;
        $sb->configure( -foreground   => $color ) if defined $color;
    }

    return;
}

=head2 _create_toolbar

Create toolbar

=cut

sub _create_toolbar {
    my $self = shift;

    # Frame for toolbar
    my $tbf = $self->Frame();
    $tbf->pack( -side => 'top', -anchor => 'nw', -fill => 'x' );

    $self->{_tb} = $tbf->ToolBar(qw/-movable 0 -side top -cursorcontrol 0/);

    # Get ToolBar button atributes
    my $cfg     = Tpda3::Config->instance();
    my $attribs = $cfg->toolbar;

    #-- Sort by id

    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{id} } keys %$attribs;

    #- Sort with  ST
    my @attribs = map { $_->[0] }
      sort { $a->[1] <=> $b->[1] }
      map { [ $_ => $temp{$_} ] }
      keys %temp;

    # Create buttons in ID order; use sub defined by 'type'
    foreach my $name (@attribs) {
        my $type = $attribs->{$name}{type};
        $self->$type( $name, $attribs->{$name} );
    }
}

=head2 item_normal

Create a normal toolbar button

=cut

sub _item_normal {
    my ( $self, $name, $attribs ) = @_;

    $self->{_tb}->separator if $attribs->{sep} =~ m{before};

    $self->{_tb}{$name} = $self->{_tb}->ToolButton(
        -image => $attribs->{icon},
        -tip   => $attribs->{tooltip},
    );

    $self->{_tb}->separator if $attribs->{sep} =~ m{after};

    return;
}

=head2 item_check

Create a check toolbar button

=cut

sub _item_check {
    my ( $self, $name, $attribs ) = @_;

    $self->{_tb}->separator if $attribs->{sep} =~ m{before};

    $self->{_tb}{$name} = $self->{_tb}->ToolButton(
        -image       => $attribs->{icon},
        -type        => 'Checkbutton',
        -indicatoron => 0,
        -tip         => $attribs->{tooltip},
    );

    $self->{_tb}->separator if $attribs->{sep} =~ m{after};

    return;
}

=head2 create_notebook

Create the NoteBook and the 3 panes.  The pane first named 'rec'
contains widgets mostly of the type Entry, maped to the fields of a
table.  The pane second contains a MListbox widget and is used for
listing the search results.  The third pane is for records from a
dependent table.

=cut

sub create_notebook {
    my $self = shift;

    #- NoteBook

    $self->{_nb} = $self->NoteBook()->pack(
        -side   => 'top',
        -padx   => 3, -pady   => 3,
        -ipadx  => 6, -ipady  => 6,
        -fill   => 'both',
        -expand => 1,
    );

    #- Panels

    $self->{_nb}{rec} = $self->{_nb}->add(
        'rec',
        -label     => 'Record',
        -underline => 0,
    );

    $self->{_nb}{sel} = $self->{_nb}->add(
        'sel',
        -label     => 'List',
        -underline => 0,
    );

    $self->{_nb}{det} = $self->{_nb}->add(
        'det',
        -label     => 'Details',
        -underline => 0,
    );

    # Frame box
    my $frm_box = $self->{_nb}{sel}->LabFrame(
        -foreground => 'blue',
        -label      => 'Tpda::Search results',
        -labelside  => 'acrosstop'
    )->pack( -expand => 1, -fill => 'both' );

    $self->{_rc} = $frm_box->Scrolled(
        'MListbox',
        -scrollbars         => 'osoe',
        -background         => 'white',
        -textwidth          => 10,
        -highlightthickness => 2,
        -width              => 0,
        -selectmode         => 'browse',
        -relief             => 'sunken',
        -columns            => [ [qw/-text Nul -textwidth 10/] ]
    );

    $self->{_rc}->pack( -expand => 1, -fill => 'both' );

    $self->{_nb}->pack(
        -side   => 'top',
        -fill   => 'both',
        -padx   => 5, -pady   => 5,
        -expand => 1,
    );

    # Initialize
    $self->{_nb}->raise('rec');
}

=head2 get_notebook

Return the notebook handler

=cut

sub get_notebook {
    my $self = shift;

    return $self->{_nb};
}

=head2 destroy_notebook

Destroy existing window, before the creation of an other.

=cut

sub destroy_notebook {
    my $self = shift;

    $self->{_nb}->destroy if Tk::Exists( $self->{_nb} );
}

=head2 get_toolbar_btn

Return a toolbar button when we know the its name

=cut

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{_tb}{$name};
}

=head2 toggle_tool

Toggle tool bar button.  If state is defined then set to state do not
toggle.

State can come as 0 | 1 and normal | disabled.

=cut

sub toggle_tool {
    my ($self, $btn_name, $state) = @_;

    my $tb_btn = $self->get_toolbar_btn($btn_name);

    my $other;
    if ($state) {
        if ( $state =~ m{norma|disabled} ) {
            $other = $state;
        }
        else {
            $other = $state ? 'normal' : 'disabled';
        }
    }
    else {
        $state = $tb_btn->cget(-state);
        $other = $state eq 'normal' ? 'disabled' : 'normal';
    }

    $tb_btn->configure( -state => $other );
}

=head2 toggle_tool_check

Toggle a toolbar checkbutton.

=cut

sub toggle_tool_check {
    my ($self, $btn_name, $state) = @_;

    my $tb_btn = $self->get_toolbar_btn($btn_name);

    if ($state) {
        $tb_btn->select;
    }
    else {
        $tb_btn->deselect;
    }
}

=head2 get_controls_conf

Return a AoH with information regarding the controls from the
configurations page

=cut

sub get_controls_conf {
    my $self = shift;

    return [ { path => [ $self->{path}, 'disabled', 'lightgrey' ] }, ];
}

=head2 get_control_by_name

Return the control instance by name

=cut

sub get_control_by_name {
    my ( $self, $name ) = @_;

    return $self->{$name},;
}

=head2 on_quit

Destroy window on quit

=cut

sub on_quit {
    my $self = shift;

    $self->destroy();
}

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

1;    # End of Tpda3::Tk::View
