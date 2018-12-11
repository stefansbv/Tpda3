package Tpda3::Tk::Tools::Templates;

# ABSTRACT: Templates meta data editing screen

use strict;
use warnings;
use utf8;

use Tk::widgets qw(JFileDialog);

use base q{Tpda3::Tk::Screen};

use POSIX qw (strftime);
use File::Spec::Functions;
use File::ShareDir qw(dist_dir);

use Tpda3::Tk::TM;
use Tpda3::Tk::Text;
require Tpda3::Config;
require Tpda3::Utils;

sub run_screen {
    my ( $self, $nb ) = @_;

    my $rec_page  = $nb->page_widget('rec');
    my $det_page  = $nb->page_widget('det');
    $self->{view} = $nb->toplevel;
    $self->{bg}   = $self->{view}->cget('-background');

    my $validation
        = Tpda3::Tk::Validation->new( $self->{scrcfg}, $self->{view} );

    # For DateEntry day names
    my @daynames = ();
    foreach ( 0 .. 6 ) {
        push @daynames, strftime( "%a", 0, 0, 0, 1, 1, 1, $_ );
    }

    #- Top Frame

    my $frm_top = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Template',
        -labelside  => 'acrosstop'
    )->pack(
        -expand => 0,
        -fill   => 'x',
    );

    my $f1d = 110;              # distance from left

    #- id_tt (id_tt)

    my $lid_tt = $frm_top->Label( -text => 'ID', );
    $lid_tt->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 5,
    );

    my $eid_tt = $frm_top->MEntry(
        -width              => 10,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eid_tt->form(
        -top  => [ '&', $lid_tt, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- tt_file (tt_file)

    my $ltt_file = $frm_top->Label( -text => 'File', );
    $ltt_file->form(
        -top     => [ $lid_tt, 8 ],
        -left    => [ %0,      5 ],
    );

    my $ett_file = $frm_top->MEntry(
        -width              => 50,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $ett_file->form(
        -top  => [ '&', $ltt_file, 0 ],
        -left => [ %0,  $f1d ],
    );
    $ett_file->bind(
        '<KeyPress-Return>' => sub {
            $self->template_file();
        }
    );

    #- title (title)

    my $ltitle = $frm_top->Label( -text => 'Title', );
    $ltitle->form(
        -top     => [ $ltt_file, 8 ],
        -left    => [ %0,        5 ],
    );

    my $etitle = $frm_top->MEntry(
        -width              => 50,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $etitle->form(
        -top       => [ '&', $ltitle, 0 ],
        -left      => [ %0,  $f1d ],
        -padbottom => 5,
    );

    my $my_font = $eid_tt->cget('-font');    # font

    #--- Datasources

    my $frm_ds = $rec_page->LabFrame(
        -label      => 'Datasources',
        -labelside  => 'acrosstop',
        -foreground => 'blue',
    );
    $frm_ds->pack(
        -expand => 0,
        -fill   => 'x',
    );

    #-- table_name

    my $ltable_name = $frm_ds->Label( -text => 'Table' );
    $ltable_name->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 5 ],
    );
    my $etable_name = $frm_ds->MEntry(
        -width              => 20,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $etable_name->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, $f1d ],
    );

    #-+ view_name

    my $lview_name = $frm_ds->Label( -text => 'View' );
    $lview_name->form(
        -top     => [ '&', $ltable_name, 0 ],
        -left    => [ $etable_name, 20 ],
    );
    my $eview_name = $frm_ds->MEntry(
        -width              => 20,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eview_name->form(
        -top     => [ '&', $lview_name, 0 ],
        -left    => [ $lview_name, 15 ],
    );

    #-- common_data

    my $lcommon_data = $frm_ds->Label( -text => 'Common data' );
    $lcommon_data->form(
        -top  => [ $ltable_name, 8 ],
        -left => [ %0, 5 ],
    );
    my $ecommon_data = $frm_ds->MEntry(
        -width              => 50,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $ecommon_data->form(
        -top       => [ '&', $lcommon_data, 0 ],
        -left      => [ %0,  $f1d ],
        -padbottom => 5,
    );

    #-- Frame bottom

    my $txt_frame = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Description',
        -labelside  => 'acrosstop',
    )->pack(
        -expand => 0,
        -fill   => 'both',
    );

    my $tdescr =  $txt_frame->Scrolled(
        'Text',
        -width      => 10,
        -height     => 3,
        -wrap       => 'word',
        -scrollbars => 'e',
        -font       => $my_font
    )->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    #--- Details
    #-
    #

    #- Frame middle

    my $frm_m = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Specific data',
        -labelside  => 'acrosstop'
    )->pack(
        -expand => 1,
        -fill   => 'both',
    );

    #-- Toolbar
    $self->make_toolbar_for_table('tm1', $frm_m);

    #- TableMatrix

    my $header = $self->{scrcfg}->dep_table_header_info('tm1');
    my $xtvar = {};

    my $xtable = $frm_m->Scrolled(
        'TM',
        -rows           => 6,
        -cols           => 1,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -validate       => 1,
        -variable       => $xtvar,
        -selectmode     => 'single',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -colstretchmode => 'unset',
        -bg             => 'white',
        -scrollbars     => 'osw',
    );
    $xtable->pack( -expand => 1, -fill => 'both' );

    $xtable->init($frm_m, $header);

    $self->{tm_controls} = { tm1 => \$xtable };

    # Prepare screen configuration data for tables
    foreach my $tm_ds ( keys %{ $self->{tm_controls} } ) {
        $validation->init_cfgdata($tm_ds);
    }

    # Entry objects: var_asoc, var_obiect
    # Other configurations in '.conf'
    $self->{controls} = {
        id_tt       => [ undef, $eid_tt ],
        tt_file     => [ undef, $ett_file ],
        title       => [ undef, $etitle ],
        table_name  => [ undef, $etable_name ],
        view_name   => [ undef, $eview_name ],
        common_data => [ undef, $ecommon_data ],
        descr       => [ undef, $tdescr ],
    };

    # Required fields: fld_name => [#, Label]
    $self->{rq_controls} = {
        tt_file    => [ 0, '  Template file' ],
        title      => [ 1, '  Title' ],
        table_name => [ 2, '  Table name' ],
        view_name  => [ 3, '  View name (or the table name again)' ],
    };

    return;
}

sub template_file {
    my $self = shift;

    my $cfg = Tpda3::Config->instance();
    my $initdir = catdir( $cfg->configdir, 'tex', 'model' );

    my $file_dlg = $self->{view}->JFileDialog(
        -Title       => 'Alegeti fisierul',
        -Create      => 0,
        -Path        => $initdir,
        -FPat        => '*.tt',
        -ShowAll     => 0,
        -DisableFPat => 1,
        -Chdir       => 0,
    );

    my $path = $file_dlg->Show(-Horiz => 1);

    return unless $path;

    my ( $vol, $dir, $file ) = File::Spec->splitpath($path);

    eval {
        my $state = $self->{controls}{tt_file}[1]->cget('-state');
        $self->{controls}{tt_file}[1]->configure( -state => 'normal' );
        $self->{controls}{tt_file}[1]->delete( 0, 'end' );
        $self->{controls}{tt_file}[1]->insert( 0, $file );
        $self->{controls}{tt_file}[1]->xview('end');
        $self->{controls}{tt_file}[1]->configure( -state => $state );
    };

    return;
}

1;

=head1 SYNOPSIS

    require Tpda3::Tools::Templates;

    my $scr = Tpda3::Tools::Templates->new;

    $scr->run_screen($args);

=head2 run_screen

The screen layout

=head2 template_file

Add template file.

=cut
