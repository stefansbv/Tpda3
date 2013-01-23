package Tpda3::Tk::Dialog::Configs;

use strict;
use warnings;
use utf8;

use Tk;
use File::Spec;

require Tpda3::Config;
require Tpda3::Tk::TB;

=head1 NAME

Tpda3::Tk::Dialog::Configs - Dialog for user configuration options

=head1 VERSION

Version 0.62

=cut

our $VERSION = 0.62;

=head1 SYNOPSIS

Set and save configuaration options.

    use Tpda3::Tk::Dialog::Configs;

    my $fd = Tpda3::Tk::Dialog::Configs->new;

    $fd->run_dialog($self);

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {};

    $self->{tb4} = {};       # ToolBar
    $self->{tlw} = {};       # TopLevel
    $self->{cfg} = Tpda3::Config->instance();

    bless $self, $class;

    $self->_init();

    return $self;
}

=head2 _cfg

Return config instance variable

=cut

sub _cfg {
    my $self = shift;

    return $self->{cfg};
}

=head2 _init

Executable files have diferent names on different platforms
Report Manager print preview: 'printrep.bin' on GNU/linux
                               'printrepxp.exe' on MSW
TODO: Add other platforms

=cut

sub _init {
    my $self = shift;

    my $os = $^O;

    $self->{repman} =
       $os eq q{}       ? ''
     : $os =~ /mswin/i  ? 'printrepxp.exe'
     : $os =~ /linux/i  ? 'printrep.bin'
     :                    '';

    $self->{latex} =
       $os eq q{}       ? ''
     : $os =~ /mswin/i  ? 'pdflatex.exe'
     : $os =~ /linux/i  ? 'pdflatex'
     :                    '';

    $self->{initial_dir} =
       $os eq q{}       ? ''
     : $os =~ /mswin/i  ? 'C:/'
     : $os =~ /linux/i  ? '/'
     :                    '';

    return;
}

=head2 make_toolbar

Create a tool bar.

=cut

sub make_toolbar {
    my $self = shift;

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
            'tooltip' => 'Save configration',
            'icon'    => 'filesave16',
            'sep'     => 'none',
            'help'    => 'Save configration',
            'method'  => sub { $self->save_as_default(); },
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

    return;
}

sub save_as_default {
    my $self = shift;

    foreach my $field ( keys %{ $self->{controls} } ) {
        print " $field\n";
    }

    return;
}

=head2 make_statusbar

Create a status bar.

=cut

sub make_statusbar {
    my $self = shift;

    #-- StatusBar

    my $sb = $self->{tlw}->StatusBar();

    # Dummy label for left space
    my $ldumy = $sb->addLabel(
        -width  => 1,
        -relief => 'flat',
    );

    $self->{_sb}{ms} = $sb->addLabel( -relief => 'flat' );

    return;
}

=head2 _set_status

Display message in the status bar.  Colour name can also be passed to
the method in the message string separated by a # char.

=cut

sub _set_status {
    my ( $self, $text, $color ) = @_;

    my $sb_label = $self->{_sb}{'ms'};

    return unless ( $sb_label and $sb_label->isa('Tk::Label') );

    # ms
    $sb_label->configure( -text       => $text )  if defined $text;
    $sb_label->configure( -foreground => $color ) if defined $color;

    return;
}

=head2 run_dialog

Show dialog

=cut

sub show_cfg_dialog {
    my ( $self, $view ) = @_;

    $self->{view} = $view;
    $self->{tlw}  = $view->Toplevel();
    $self->{tlw}->title('Configs');
    #$self->{tlw}->geometry('480x520');

    $self->{bg} = $view->cget('-background');
    my $f1d = 135;              # distance from left

    #-- Key bindings

    $self->{tlw}->bind( '<Escape>', sub { $self->dlg_exit } );

    $self->make_toolbar();
    $self->make_statusbar();

    #- Main frame

    my $mf = $self->{tlw}->Frame();
    $mf->pack(
        -side   => 'top',
        -expand => 1,
        -fill   => 'both',
    );

    #-  Frame top - Entries

    my $frm_top = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'External apps',
        -labelside  => 'acrosstop'
    );
    $frm_top->pack(
        -expand => 0,
        -fill   => 'x',
        -ipadx  => 3,
        -ipady  => 3,
    );

    #-- extapp1

    my $lextapp1 = $frm_top->Label( -text => 'Report Manager', );
    $lextapp1->form(
        -top     => [ %0, 0 ],
        -right   => [ %100, -35 ],
        -padleft => 5,
    );

    #-- repman

    my $repman_label = "File: $self->{repman}";
    my $lrepman = $frm_top->Label( -text => $repman_label, );
    $lrepman->form(
        -top     => [ $lextapp1, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );

    my $erepman = $frm_top->Entry(
        -width => 36,
    );
    $erepman->form(
        -top  => [ '&', $lrepman, 0 ],
        -left => [ %0, ($f1d + 1) ],
    );

    #-- button

    $frm_top->Button(
        -image   => 'fileopen16',
        -command => sub { $self->update_value('repman', 'file') },
    )->form(
        -top  => [ '&', $lrepman, 0 ],
        -left => [ $erepman, 3 ],
    );

    #-- extapp2

    my $lextapp2 = $frm_top->Label(
        -text => 'LaTeX / MikTex',
    );
    $lextapp2->form(
        -top     => [ $lrepman, 8 ],
        -right   => [ %100, -35 ],
        -padleft => 5,
    );

    #-- latex

    my $latex_label = "File: $self->{latex}";
    my $llatex = $frm_top->Label( -text => $latex_label, );
    $llatex->form(
        -top     => [ $lextapp2, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );

    my $elatex = $frm_top->Entry(
        -width => 36,
    );
    $elatex->form(
        -top  => [ '&', $llatex, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- button
    $frm_top->Button(
        -image   => 'fileopen16',
        -command => sub { $self->update_value('latex', 'file') },
    )->form(
        -top  => [ '&', $llatex, 0 ],
        -left => [ $elatex, 3 ],
    );

    #-  Frame bottom - Entries

    my $frm_bottom = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'Other paths',
        -labelside  => 'acrosstop'
    );
    $frm_bottom->pack(
        -side   => 'bottom',
        -expand => 1,
        -fill   => 'x',
        -ipadx  => 3,
        -ipady  => 3,
    );

    #-- docspath
    my $ldocspath = $frm_bottom->Label( -text => 'Documents output' );
    $ldocspath->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 5,
    );
    my $edocspath = $frm_bottom->MEntry(
        -width              => 36,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $edocspath->form(
        -top     => [ '&', $ldocspath, 0 ],
        -left    => [ %0, $f1d ],
    );

    #-- button
    $frm_bottom->Button(
        -image   => 'folderopen16',
        -command => sub { $self->update_value('docspath', 'path') },
    )->form(
        -top  => [ '&', $ldocspath, 0 ],
        -left => [ $edocspath, 3 ],
    );

    # Entry objects: var_asoc, var_obiect
    # Other configurations in '.conf'
    $self->{controls} = {
        repman   => [ undef, $erepman ],
        latex    => [ undef, $elatex ],
        docspath => [ undef, $edocspath ],
    };

    $self->load_config();

    return;
}

sub load_config {
    my $self = shift;

    #- externalapps section in main.yml
    my $appscfg_ref = $self->cfg->cfextapps;
    foreach my $field ( keys %{$appscfg_ref} ) {
        my $path = $appscfg_ref->{$field}{exe_path};
        $self->update_path_field( $field, $path, 'file' );
    }

    #- runtime section in main.yml
    my $runcfg_ref = $self->cfg->cfrun;
    foreach my $field ( keys %{$runcfg_ref} ) {
        my $path = $runcfg_ref->{$field};
        $self->update_path_field( $field, $path, 'path' );
    }

    return;
}

=head2 update_value

Callback to update the value of the paramater, using the file search
dialog.

=cut

sub update_value {
    my ($self, $field, $type) = @_;

    $self->_set_status('');     # clear status

    my $sub_name = "dialog_$type";
    my $path = $self->$sub_name($field);

    $self->update_path_field($field, $path, $type);

    # Check if file name match the desired one
    if ( $type eq 'file' ) {
        my ( $vol, $dir, $file ) = File::Spec->splitpath($path);
        unless ( $self->{$field} eq $file ) {
            $self->_set_status( "Error, wrong file '$file'", 'red' );
        }
    }

    return;
}

=head2 dialog_file

File dialog.

=cut

sub dialog_file {
    my ($self, $field) = @_;

    my $initialdir = $self->get_init_dir($field);

    my $types = [ [ 'Executable', $self->{$field} ], [ 'All Files', '*', ], ];
    my $path = $self->{tlw}->getOpenFile(
        -filetypes  => $types,
        -initialdir => $initialdir,
    );

    unless ($path and -f $path) {
        $self->_set_status('Error, file not found', 'red');
    }

    return $path;
}

=head2 dialog_path

Path dialog.

=cut

sub dialog_path {
    my ($self, $field) = @_;

    my $initialdir = $self->get_init_dir($field);

    my $path = $self->{tlw}->chooseDirectory(
        -initialdir => '~',
        -title      => 'Choose a folder',
    );

    unless ($path and -d $path) {
        $self->_set_status('Error, path not found', 'red');
    }

    return $path;
}

=head2 get_init_dir

If there is a value in the filed, use the path as initial dir for the
dialog, else use the default.

TODO: check on MSW, what about vol?

=cut

sub get_init_dir {
    my ($self, $field) = @_;

    my $path = $self->{controls}{$field}[1]->get();

    if ($path) {
        return ( File::Spec->splitpath($path) )[1]; # dir
    }
    else {
        return $self->{initial_dir};
    }
}

sub update_path_field {
    my ($self, $field, $value, $type) = @_;

    return unless $field and $value;

    eval {
        my $state = $self->{controls}{$field}[1]->cget( -state );
        $self->{controls}{$field}[1]->configure( -state => 'normal' );
        $self->{controls}{$field}[1]->delete( 0, 'end' );
        $self->{controls}{$field}[1]->insert( 0, $value );
        $self->{controls}{$field}[1]->xview('end');
        $self->{controls}{$field}[1]->configure( -state => $state );
    };
    if ($@) {
        warn "Error: $@";
    }

    my $color;
    if ($type eq 'path') {
        $color = -d $value ? 'darkgreen' : 'darkred';
    }
    else {
        $color = -f $value ? 'darkgreen' : 'darkred';
    }
    $self->{controls}{$field}[1]->configure( -fg => $color );

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

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Tk::Dialog::Configs

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1;    # End of Tpda3::Tk::Dialog::Configs
