package Tpda3::Tk::Dialog::Configs;

# ABSTRACT: Dialog for user configuration options

use strict;
use warnings;
use utf8;

use Tk;
use Tk::widgets qw(JFileDialog);
use File::Copy;
use File::Spec;

require Tpda3::Config;
require Tpda3::Config::Utils;


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


sub cfg {
    my $self = shift;
    return $self->{cfg};
}


sub _init {
    my $self = shift;

    my $os = $^O;

    $self->{initial_dir} =
       $os eq q{}       ? ''
     : $os =~ /mswin/i  ? 'C:/'
     : $os =~ /linux/i  ? '/'
     :                    '';

    # External apps

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

    $self->{chm_viewer} =
       $os eq q{}       ? ''
     : $os =~ /mswin/i  ? 'NOT USED'
     : $os =~ /linux/i  ? 'chm viewer'
     :                    '';

    return;
}


sub save_as_default {
    my $self = shift;

    $self->_set_status('');    # clear

    $self->backup_main();

    #- External apps section in main.yml

    my $appscfg_ref = $self->cfg->cfextapps;

    foreach my $field ( qw{repman latex chm_viewer} ) {
        my $value = $self->{controls}{$field}[1]->get();
        $self->save_yaml_main( 'externalapps', $field,
            { 'exe_path', $value } )
            if $value;
    }

    #- Runtime section in main.yml

    my $runcfg_ref = $self->cfg->cfrun;

    foreach my $field ( keys %{$runcfg_ref} ) {
        my $value = $self->{controls}{$field}[1]->get();
        $self->save_yaml_main( 'runtime', 'docspath', $value )
            if $value;
    }

    $self->_set_status('Configuration updated');

    return;
}


sub save_yaml_main {
    my ( $self, $section, $key, $value ) = @_;

    my $main_yml = $self->cfg->cfmainyml;

    Tpda3::Config::Utils->save_yaml( $main_yml, $section, $key, $value );

    return;
}


sub backup_main {
    my $self = shift;

    my $yml_file = $self->cfg->cfmainyml;

    my $ext = (-f "$yml_file.orig") ? 'old' : 'orig';

    my $bak_file = "$yml_file.$ext";

    copy( $yml_file, $bak_file )
        or die "can't copy $yml_file to $bak_file: $!";

    return;
}


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


sub _set_status {
    my ( $self, $text, $color ) = @_;

    my $sb_label = $self->{_sb}{'ms'};

    return unless ( $sb_label and $sb_label->isa('Tk::Label') );

    # ms
    $sb_label->configure( -text       => $text )  if defined $text;
    $sb_label->configure( -foreground => $color ) if defined $color;

    return;
}


sub show_cfg_dialog {
    my ( $self, $view ) = @_;

    $self->{view} = $view;
    $self->{tlw}  = $view->Toplevel();
    $self->{tlw}->title('Configs');

    $self->{bg} = $view->cget('-background');
    my $f1d = 135;              # distance from left

    #-- Key bindings

    $self->{tlw}->bind( '<Escape>', sub { $self->dlg_exit } );

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
        -command => sub { $self->update_value('repman', 'file', 'strict') },
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
        -command => sub { $self->update_value('latex', 'file', 'strict') },
    )->form(
        -top  => [ '&', $llatex, 0 ],
        -left => [ $elatex, 3 ],
    );

    #-- extapp3

    my $lextapp3 = $frm_top->Label(
        -text => 'CHM viewer',
    );
    $lextapp3->form(
        -top     => [ $llatex, 8 ],
        -right   => [ %100, -35 ],
        -padleft => 5,
    );

    #-- CHM viewer

    my $chm_label = "File: $self->{chm_viewer}";
    my $lchm_viewer = $frm_top->Label( -text => $chm_label, );
    $lchm_viewer->form(
        -top     => [ $lextapp3, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );

    my $echm_viewer = $frm_top->Entry(
        -width => 36,
    );
    $echm_viewer->form(
        -top  => [ '&', $lchm_viewer, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- button
    $frm_top->Button(
        -image   => 'fileopen16',
        -command => sub { $self->update_value('chm_viewer', 'file') },
    )->form(
        -top  => [ '&', $lchm_viewer, 0 ],
        -left => [ $echm_viewer, 3 ],
    );

    #-  Frame middle - Entries

    my $frm_middle = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'Other paths',
        -labelside  => 'acrosstop'
    );
    $frm_middle->pack(
        #-side   => 'bottom',
        -expand => 1,
        -fill   => 'x',
        -ipadx  => 3,
        -ipady  => 3,
    );

    #-- docspath
    my $ldocspath = $frm_middle->Label( -text => 'Documents output' );
    $ldocspath->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 5,
    );
    my $edocspath = $frm_middle->MEntry(
        -width              => 36,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $edocspath->form(
        -top     => [ '&', $ldocspath, 0 ],
        -left    => [ %0, $f1d ],
    );

    #-- button
    $frm_middle->Button(
        -image   => 'folderopen16',
        -command => sub { $self->update_value('docspath', 'path') },
    )->form(
        -top  => [ '&', $ldocspath, 0 ],
        -left => [ $edocspath, 3 ],
    );

    #-  Frame bottom - Buttons

    my $frm_bottom = $mf->Frame();
    $frm_bottom->pack(
        -expand => 0,
        -fill   => 'both',
    );

    my $test_b = $frm_bottom->Button(
        -text    => 'Set',
        -width   => 10,
        -command => sub { $self->save_as_default() },
    );
    $test_b->pack( -side => 'left', -padx => 20, -pady => 5 );

    my $close_b = $frm_bottom->Button(
        -text    => 'Close',
        -width   => 10,
        -command => sub { $self->dlg_exit },
    );
    $close_b->pack( -side => 'right', -padx => 20, -pady => 5 );

    # End

    # Entry objects: var_asoc, var_obiect
    # Other configurations in '.conf'
    $self->{controls} = {
        repman     => [ undef, $erepman ],
        latex      => [ undef, $elatex ],
        chm_viewer => [ undef, $echm_viewer ],
        docspath   => [ undef, $edocspath ],
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


sub update_value {
    my ($self, $field, $type, $strict) = @_;

    $self->_set_status('');     # clear status

    my $sub_name = "dialog_$type";
    my $path = $self->$sub_name($field);

    $self->update_path_field($field, $path, $type);

    # Check if file name match the desired one
    if ( $type eq 'file' ) {
        if ($strict) {
            my ( $vol, $dir, $file ) = File::Spec->splitpath($path);
            unless ( $self->{$field} eq $file ) {
                $self->_set_status( "Wrong file '$file'!", 'blue' );
            }
        }
        else {
            unless ( $path and -x $path ) {
                $self->_set_status( "No file!", 'blue' );
            }
        }
    }

    return;
}


sub dialog_file {
    my ($self, $field) = @_;

    my $initialdir = $self->get_init_dir($field);

    my $types = [ [ 'Executable', $self->{$field} ], [ 'All Files', '*', ], ];
    my $path = $self->{tlw}->getOpenFile(
        -filetypes  => $types,
        -initialdir => $initialdir,
    );

    # my $file_dlg = $self->{tlw}->JFileDialog(
    #     -Title  => 'Select file',
    #     -Create => 0,
    #     -Path   => $initialdir,
    #     -FPat    => '*',
    #     -ShowAll => 'NO',
    # );
    # my $path = $file_dlg->Show(-Horiz => 1);

    unless ($path and -f $path) {
        $self->_set_status('Error, file not found', 'red');
    }

    return $path;
}


sub dialog_path {
    my ($self, $field) = @_;

    my $initialdir = $self->get_init_dir($field);

    my $path = $self->{tlw}->Tk::chooseDirectory(
        -initialdir => '~',
        -title      => 'Select folder',
    );

    if ( !defined $path ) {
        $self->_set_status( 'Canceled.', 'blue' );
        return;
    }
    if ( !-d $path ) {
        $self->_set_status( 'Error, path not found', 'orange' );
        return;
    }

    return $path;
}


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
        my $state = $self->{controls}{$field}[1]->cget('-state');
        $self->{controls}{$field}[1]->configure( -state => 'normal' );
        $self->{controls}{$field}[1]->delete( 0, 'end' );
        $self->{controls}{$field}[1]->insert( 0, $value );
        $self->{controls}{$field}[1]->xview('end');
        $self->{controls}{$field}[1]->configure( -state => $state );
    };
    if ($@) {
        warn "Error: $@";
    }

    my $color
        = $type eq 'path'
        ? ( -d $value ? 'darkgreen' : 'darkred' )
        : ( -f $value ? 'darkgreen' : 'darkred' );

    $self->{controls}{$field}[1]->configure( -fg => $color );

    return;

}


sub dlg_exit {
    my $self = shift;

    $self->{tlw}->destroy;

    return;
}

1;

=head1 SYNOPSIS

Set and save configuaration options.

    use Tpda3::Tk::Dialog::Configs;

    my $fd = Tpda3::Tk::Dialog::Configs->new;

    $fd->run_dialog($self);

=head2 new

Constructor method.

=head2 cfg

Return configuration instance object.

=head2 _init

Executable files have diferent names on different platforms
Report Manager print preview: 'printrep.bin' on GNU/linux
                               'printrepxp.exe' on MSW
TODO: Add other platforms

=head2 save_as_default

Backup the I<main.yml> configuration file.  Write the current content
of the widgets to the configuration file.

=head2 save_yaml_main

Create or update the I<main.yml> configuration file.

=head2 backup_main

Make a backup file named I<main.yml.orig> if it doesn't exists yet,
else make I<main.yml.old>.

=head2 make_statusbar

Create a status bar.

=head2 _set_status

Display message in the status bar.

=head2 show_cfg_dialog

Show the configuration dialog.

=head2 load_config

Load the current configuration values into the widgets.

=head2 update_value

Callback to update the value of the paramater, using the file search
dialog.

=head2 dialog_file

File dialog.

=head2 dialog_path

Path dialog.

=head2 get_init_dir

If there is a value in the filed, use the path as initial dir for the
dialog, else use the default.

TODO: check on MSW, what about vol?

=head2 update_path_field

Write into the path widget with colors.

=head2 dlg_exit

Quit Dialog.

=cut
