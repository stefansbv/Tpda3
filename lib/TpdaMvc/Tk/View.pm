package TpdaMvc::Tk::View;

use strict;
use warnings;

use Data::Dumper;

use File::Spec::Functions qw(abs2rel);
use Tk;
use Tk::widgets qw(ToolBar NoteBook StatusBar Dialog
    Checkbutton LabFrame MListbox JComboBox Font);

use base 'Tk::MainWindow';

use TpdaMvc::Config;

=head1 NAME

TpdaMvc::Tk::App - Tk Perl application class

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use TpdaMvc::Tk::Notebook;

    $self->{_nb} = TpdaMvc::Tk::Notebook->new( $gui );


=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;
    my $model = shift;

    #- The MainWindow

    my $self = __PACKAGE__->SUPER::new( @_ );

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
    # $self->{_nb} = TpdaMvc::Tk::Notebook->new( $self );

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

    # my $tb = $self->get_toolbar();
    # #-
    # my $co = $self->_model->get_connection_observable;
    # $co->add_callback(
    #     sub { $tb->ToggleTool( $self->get_toolbar_btn_id('tb_cn'), $_[0] ) } );
    # #--
    # my $em = $self->_model->get_editmode_observable;
    # $em->add_callback(
    #     sub {
    #         $tb->ToggleTool( $self->get_toolbar_btn_id('tb_ed'), $_[0] );
    #         $self->toggle_sql_replace();
    #     }
    # );
    # #--
    # my $upd = $self->_model->get_itemchanged_observable;
    # $upd->add_callback(
    #     sub { $self->controls_populate(); } );
    # #--
    # my $so = $self->_model->get_stdout_observable;
    # #$so->add_callback( sub{ $self->log_msg( $_[0] ) } );
    # $so->add_callback( sub{ $self->status_msg( @_ ) } );
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
    my $cfg = TpdaMvc::Config->instance();
    my $attribs = $cfg->menubar;

    #-- Sort by id
    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{id} } keys %{$attribs};

    #- Sort with  ST
    my @attribs = map  { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map  { [ $_ => $temp{$_} ] }
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
}

=head2 make_popup_item

Make popup item

=cut

sub make_popup_item {
    my ( $self, $menu, $item ) = @_;

    $menu->add('separator') if $item->{sep} eq 'before';

    $menu->add(
        'command',
        -label       => $item->{label},
        -accelerator => $item->{key},
        -underline   => $item->{underline},
    );

    $menu->add('separator') if $item->{sep} eq 'after';
}

=head2 get_menubar

Return the menu bar handler

=cut

sub get_menubar {
    my $self = shift;

    return $self->{_menu};
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
        -relief => 'flat'
    );

    $self->{sb}{ll} = $sb->addLabel( -relief => 'flat' );

    $self->{sb}{lc} = $sb->addLabel(
        -width  => 20,
        -relief => 'raised',
        -anchor => 'center',
        -side   => 'right'
    );

    $self->{sb}{ld} = $sb->addLabel(
        -width  => 15,
        -anchor => 'center',
        -side   => 'right'
    );

    $self->{sb}{pr} = $sb->addProgressBar(
        -length     => 100,
        -from       => 0,
        -to         => 100,
        -variable   => \$self->{progres},
        -foreground => 'blue'
    );

    $self->{sb}{lr} = $sb->addLabel(
        -width      => 6,
        -anchor     => 'center',
        -side       => 'right',
        -foreground => 'blue'
    );
}

=head2 get_statusbar

Return the status bar handler

=cut

sub get_statusbar {
    my $self = shift;

    return $self->{_sb};
}

=head2 _setup_toolbar

Setup toolbar

=cut

sub _create_toolbar {
    my $self = shift;

    # Frame for toolbar
    my $tbf = $self->Frame();
    $tbf->pack( -side => 'top', -anchor => 'nw', -fill => 'x' );

    $self->{_tb} = $tbf->ToolBar(qw/-movable 0 -side top -cursorcontrol 0/);

    # Get ToolBar button atributes
    my $cfg = TpdaMvc::Config->instance();
    my $attribs = $cfg->toolbar;

    #-- Sort by id

    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{id} } keys %$attribs;

    #- Sort with  ST
    my @attribs = map  { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map  { [ $_ => $temp{$_} ] }
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
    my ($self, $name, $attribs) = @_;

    $self->{_tb}->separator if $attribs->{sep} =~ m{before};

    $self->{_tb}{$name} = $self->{_tb}->ToolButton(
        -image   => $attribs->{icon},
        -tip     => $attribs->{tooltip},
    );

    $self->{_tb}->separator if $attribs->{sep} =~ m{after};

    return;
}

=head2 item_check

Create a check toolbar button

=cut

sub _item_check {
    my ($self, $name, $attribs) = @_;

    $self->{_tb}->separator if $attribs->{sep} =~ m{before};

    $self->{_tb}{$name} = $self->{_tb}->ToolButton(
        -image       => $attribs->{icon},
        -type        => 'Checkbutton',
        -indicatoron => 0,
        -tip         => $attribs->{tooltip},
        #-variable    => \$self->{tpda}->{$variable},
    );

    $self->{_tb}->separator if $attribs->{sep} =~ m{after};

    return;
}

=head2 get_notebook

Return the notebook handler

=cut

sub get_notebook {
    my $self = shift;

    return $self->{_nb};
}

=head2 get_toolbar_btn

Return a toolbar button when we know the its name

=cut

sub get_toolbar_btn {
    my ($self, $name) = @_;

    return $self->{_tb}{$name};
}

=head2 get_toolbar

Return the toolbar handler

=cut

sub get_toolbar {
    my $self = shift;
    return $self->{_tb};
}

=head2 get_controls_conf

Return a AoH with information regarding the controls from the
configurations page

=cut

sub get_controls_conf {
    my $self = shift;

    return [
        { path => [ $self->{path}, 'disabled', 'lightgrey' ] },
    ];
}

=head2 get_control_by_name

Return the control instance by name

=cut

sub get_control_by_name {
    my ($self, $name) = @_;

    return $self->{$name},
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

1; # End of TpdaMvc::Tk::View
