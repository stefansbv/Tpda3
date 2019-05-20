package Tpda3::Tk::Tools::Configs;

# ABSTRACT: Configs meta data editing screen

use 5.010;
use strict;
use warnings;
use utf8;

use base q{Tpda3::Tk::Screen};

use POSIX qw (strftime);
use File::Spec::Functions;
use File::ShareDir qw(dist_dir);

sub cfg {
    my $self = shift;
    return $self->{cfg};
}

sub _init {
    my $self = shift;

    $self->{cfg}   = Tpda3::Config->instance();

    my $os = $^O;

    $self->{initial_dir} =
       $os eq q{}       ? ''
     : $os =~ /mswin/i  ? 'C:/'
     : $os =~ /linux/i  ? '/'
     :                    '';

    # Documents base dir

    my $docs = File::HomeDir->my_documents;
    $self->{documents_dir} = $docs;

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

sub run_screen {
    my ( $self, $nb ) = @_;

    $self->_init();

    my $rec_page  = $nb->page_widget('rec');
    my $det_page  = $nb->page_widget('det');
    $self->{view} = $nb->toplevel;
    $self->{bg}   = $self->{view}->cget('-background');

    my $validation
        = Tpda3::Tk::Validation->new( $self->{scrcfg}, $self->{view} );

    #- Top Frame

    my $frm_top = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'External apps {externalapps}',
        -labelside  => 'acrosstop'
    )->pack(
        -expand => 0,
        -fill   => 'x',
        -ipadx  => 5,
        -ipady  => 5,
    );

    my $f1d = 120;              # distance from left

    #-- extapp1

    my $lextapp1 = $frm_top->Label( -text => 'Report Manager', );
    $lextapp1->form(
        -top     => [ %0, 0 ],
        -right   => [ %100, -15 ],
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
        -width              => 36,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $erepman->form(
        -top  => [ '&', $lrepman, 0 ],
        -left => [ %0, ( $f1d + 1 ) ],
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
        -right   => [ %100, -15 ],
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
        -width              => 36,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
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
        -right   => [ %100, -15 ],
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
        -width              => 36,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
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

    # my $my_font = $erepman->cget('-font');    # font

    #-- Frame bottom

    my $frm_bot = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Runtime {runtime}',
        -labelside  => 'acrosstop',
    )->pack(
        -expand => 0,
        -fill   => 'x',
        -ipadx  => 5,
        -ipady  => 5,
    );

    #-- docsoutpath

    my $lldocsoutpath = $frm_bot->Label( -text => 'Documents output', );
    $lldocsoutpath->form(
        -top     => [ %0, 0 ],
        -right   => [ %100, -15 ],
        -padleft => 5,
    );

    my $ldocsoutpath = $frm_bot->Label(
        -text       => 'docsoutpath',
        -foreground => 'green4',
    );
    $ldocsoutpath->form(
        -top     => [ $lldocsoutpath, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );
    my $edocsoutpath = $frm_bot->MEntry(
        -width              => 36,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $edocsoutpath->form(
        -top     => [ '&', $ldocsoutpath, 0 ],
        -left    => [ %0, $f1d ],
    );

    #-- button
    $frm_bot->Button(
        -image   => 'folderopen16',
        -command => sub { $self->update_value('docsoutpath', 'path') },
    )->form(
        -top  => [ '&', $ldocsoutpath, 0 ],
        -left => [ $edocsoutpath, 3 ],
    );

    #-- docsbasepath

    my $lldocsbasepath = $frm_bot->Label( -text => 'Documents', );
    $lldocsbasepath->form(
        -top     => [ $ldocsoutpath, 8 ],
        -right   => [ %100, -15 ],
        -padleft => 5,
    );

    my $ldocsbasepath = $frm_bot->Label(
        -text       => 'docsbasepath',
        -foreground => 'green4',
    );
    $ldocsbasepath->form(
        -top     => [ $lldocsbasepath, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );
    my $edocsbasepath = $frm_bot->MEntry(
        -width              => 36,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $edocsbasepath->form(
        -top     => [ '&', $ldocsbasepath, 0 ],
        -left    => [ %0, $f1d ],
    );

    #-- button
    $frm_bot->Button(
        -image   => 'folderopen16',
        -command => sub { $self->update_value('docsbasepath', 'path') },
    )->form(
        -top  => [ '&', $ldocsbasepath, 0 ],
        -left => [ $edocsoutpath, 3 ],
    );




    # Entry objects: var_asoc, var_obiect
    # Other configurations in '.conf'
    $self->{controls} = {
        repman       => [ undef, $erepman ],
        latex        => [ undef, $elatex ],
        chm_viewer   => [ undef, $echm_viewer ],
        docsoutpath  => [ undef, $edocsoutpath ],
        docsbasepath => [ undef, $edocsbasepath ],
    };

    # Required fields: fld_name => [#, Label]
    $self->{rq_controls} = {
        repofile => [ 0,  '  Report file' ],
        title    => [ 1,  '  Title' ],
    };

    return;
}

sub on_load_screen {
    my $self = shift;
    $self->load_config();
}

sub load_config {
    my $self = shift;
    my $data = Tpda3::Utils->read_yaml( $self->cfg->cfmainyml );

    #- External apps section in main.yml
    foreach my $field ( qw{repman latex chm_viewer} ) {
        my $value = $data->{externalapps}{$field}{exe_path};
        $self->update_field( $field, $value, 'file' );
    }

    #- Runtime section in main.yml
    my ($docspath, $value);
    foreach my $field ( qw{docspath docsoutpath docsbasepath} ) {
        if ($field eq 'docspath') {
            if ( exists $data->{runtime}{$field} ) {
                say "'docspath' is deprecated, using 'docsoutpath' instead";
                $docspath = $data->{runtime}{$field};
                next;
            }
        }
        if ($field eq 'docsoutpath') {
            $value = $data->{runtime}{$field} || $docspath;
        }
        if ($field eq 'docsbasepath') {
            $value = $data->{runtime}{$field};
        }
        $self->update_field( $field, $value, 'path' );
    }
    return;
}

sub update_value {
    my ($self, $field, $type, $strict) = @_;

    $self->_set_status('');     # clear status

    my $sub_name = "dialog_$type";
    my $path = $self->$sub_name($field);
    return unless $path;

    $self->update_field($field, $path, $type);

    # Check if file name match the desired one
    if ( $type eq 'file' ) {
        if ($strict) {
            my ( $vol, $dir, $file ) = File::Spec->splitpath($path);
            my $name = $self->{$field};
            $self->_set_status(
                "Wrong file '$file', expecting '$name'!", 'red' )
                unless $name eq $file;
        }
        else {
            $self->_set_status( "No file!", 'red' ) unless $path and -x $path;
        }
    }
    return;
}

sub dialog_file {
    my ($self, $field) = @_;
    my $initialdir = $self->get_init_dir($field);
    my $path = $self->{view}->dialog_file($initialdir);
    return unless $path;
    $self->_set_status( 'Error, file not found', 'red' ) unless -f $path;
    return $path;
}

sub dialog_path {
    my ($self, $field) = @_;
    my $initialdir = $self->get_init_dir($field);
    my $path = $self->{view}->dialog_path($initialdir);
    unless ( $path and -d $path ) {
        $self->_set_status( 'Error, path not found', 'red' );
    }
    return $path;
}

sub read_e {
    my ( $self, $field ) = @_;
    return $self->{view}->control_read_e( $field, $self->{controls}{$field} );
}

sub write_e {
    my ( $self, $field, $value, $color ) = @_;
    $self->{view}->control_write_e( $field, $self->{controls}{$field}, $value );
    $self->{controls}{$field}[1]->configure( -fg => $color );
}

sub update_field {
    my ($self, $field, $value, $type) = @_;
    return unless $field and $value;
    my $color
        = $type eq 'path'
        ? ( -d $value ? 'darkgreen' : 'darkred' )
        : ( -f $value ? 'darkgreen' : 'darkred' );
    $self->write_e($field, $value, $color);
    return;
}

sub save_config {
    my $self = shift;

    $self->_set_status('');    # clear
    $self->backup_config;

    my $data = Tpda3::Utils->read_yaml( $self->cfg->cfmainyml );

    #- External apps section in main.yml
    foreach my $field ( qw{repman latex chm_viewer} ) {
        my $value = $self->read_e($field);
        print "field = $field, value = $value\n";
        $data->{externalapps}{$field}{exe_path} = $value;
    }

    #- Runtime section in main.yml
    foreach my $field ( qw{docsoutpath docsbasepath} ) {
        my $value = $self->read_e($field);
        print "field = $field, value = $value\n";
        $data->{runtime}{$field} = $value;
    }

    if ( my $deleted = delete $data->{runtime}{docspath} ) {
        say "removed deprecated docspath: $deleted";
    }

    Tpda3::Utils->write_yaml( $self->cfg->cfmainyml, $data );
    $self->_set_status('Configuration updated.');

    return;
}

sub backup_config {
    my $self = shift;
    my $yml_file = $self->cfg->cfmainyml;
    my $ext = (-f "$yml_file.orig") ? 'old' : 'orig';
    my $bak_file = "$yml_file.$ext";
    copy( $yml_file, $bak_file )
        or die "can't copy $yml_file to $bak_file: $!";
    return;
}

sub get_init_dir {
    my ($self, $field) = @_;
    my $path = $self->{controls}{$field}[1]->get();
    return ( File::Spec->splitpath($path) )[1] if $path;
    return $self->{initial_dir};
}

=head2 _set_status

Show a status message.

=cut

sub _set_status {
    my ( $self, $text, $color ) = @_;
    my $sb_label = $self->{_sb}{'ms'};
    return unless ( $sb_label and $sb_label->isa('Tk::Label') );
    $sb_label->configure( -text       => $text )  if defined $text;
    $sb_label->configure( -foreground => $color ) if defined $color;
    return;
}

1;

=head1 SYNOPSIS

    require Tpda3::Tools::Configs;

    my $scr = Tpda3::Tools::Configs->new;

    $scr->run_screen($args);

=head2 run_screen

The screen layout.

=head2 report_file

Add report file.

=cut
