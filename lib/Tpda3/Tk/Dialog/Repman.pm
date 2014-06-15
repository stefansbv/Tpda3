package Tpda3::Tk::Dialog::Repman;

use strict;
use warnings;
use utf8;

use IO::File;
use File::Spec::Functions;

use Tk;

require Tpda3::Config;
require Tpda3::Tk::TB;
require Tpda3::Tk::TM;
require Tpda3::Utils;
require Tpda3::Lookup;

use base q{Tpda3::Tk::Screen};

=head1 NAME

Tpda3::Tk::Dialog::RepMan - Dialog for preview and print RepMan reports.

=head1 VERSION

Version 0.88

=cut

our $VERSION = 0.88;

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
    $self->{tmx} = undef;    # TableMatrix
    $self->{_rl} = undef;    # report titles list
    $self->{_rd} = undef;    # report details
    $self->{cfg} = Tpda3::Config->instance();

    return $self;
}

=head2 run_screen

Define and show search dialog.

=cut

sub run_screen {
    my ( $self, $view ) = @_;

    $self->{tlw} = $view->Toplevel();
    $self->{tlw}->title('Preview and print reports');
    $self->{tlw}->geometry('480x520');

    $self->{model} = $view->{_model};

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
    $self->{tmx} = $frm_top->Scrolled(
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
        -bg             => 'white',
        -scrollbars     => 'osw',
        -validate       => 1,
        -vcmd           => sub { $self->select_idx(@_) },
    );
    $self->{tmx}->pack(
        -expand => 1,
        -fill   => 'both',
    );

    #-  Frame middle - Entries

    my $frm_middle = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'Details',
        -labelside  => 'acrosstop'
    );
    $frm_middle->pack(
        -expand => 0,
        -fill   => 'x',
        -ipadx  => 3,
        -ipady  => 3,
    );

    #-- ID report (id_rep)

    my $lid_rep = $frm_middle->Label(
        -text => 'ID report',
    );
    $lid_rep->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );
    #--
    my $eid_rep = $frm_middle->Entry(
        -width => 12,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $eid_rep->form(
        -top  => [ %0, 0  ],
        -left => [ %0, $f1d ],
    );

    # #-+ id_user

    # my $eid_user = $frm_middle->Entry(
    #     -width => 12,
    # );
    # $eid_user->form(
    #     -top   => [ '&', $lid_rep, 0 ],
    #     -right => [ %100, -10 ],
    # );
    # my $lid_user = $frm_middle->Label(
    #     -text => 'User',
    # );
    # $lid_user->form(
    #     -top   => [ '&', $lid_rep, 0 ],
    #     -right => [ $eid_user, -15 ],
    #     -padleft => 5,
    # );

    #-- repofile

    my $lrepofile = $frm_middle->Label( -text => 'Report file', );
    $lrepofile->form(
        -top     => [ $lid_rep, 5 ],
        -left    => [ %0,       0 ],
        -padleft => 10,
    );

    my $erepofile = $frm_middle->Entry(
        -width              => 40,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $erepofile->form(
        -top  => [ '&', $lrepofile, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-- Parameter 1

    #-- label
    my $lparameter1 = $frm_middle->Label( -text => 'Parameter 1' );
    $lparameter1->form(
        -top     => [ $lrepofile, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );

    #-- hint
    my $eparahnt1 = $frm_middle->Entry(
        -width => 28,
    );
    $eparahnt1->form(
        -top  => [ '&', $lparameter1, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- value
    my $eparaval1 = $frm_middle->Entry( -width => 10, );
    $eparaval1->form(
        -top   => [ '&', $lparameter1, 0 ],
        -right => [ '&', $erepofile,   0 ],
    );

    #-- button
    my $add1val = $frm_middle->Button(
        -image   => 'edit16',
        -command => [\&update_value, $self, $view, 1],
    );
    $add1val->form(
        -top  => [ '&', $lparameter1, 0 ],
        -left => [ $eparaval1, 3 ],
    );

    #-- Parameter 2

    #-- label
    my $lparameter2 = $frm_middle->Label( -text => 'Parameter 2' );
    $lparameter2->form(
        -top     => [ $lparameter1, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );

    #-- hint
    my $eparahnt2 = $frm_middle->Entry(
        -width => 28,
    );
    $eparahnt2->form(
        -top  => [ '&', $lparameter2, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- value
    my $eparaval2 = $frm_middle->Entry( -width => 10, );
    $eparaval2->form(
        -top   => [ '&', $lparameter2, 0 ],
        -right => [ '&', $erepofile,   0 ],
    );

    #-- button
    my $add2val = $frm_middle->Button(
        -image   => 'edit16',
        -command => [\&update_value, $self, $view, 2],
    );
    $add2val->form(
        -top  => [ '&', $lparameter2, 0 ],
        -left => [ $eparaval2, 3 ],
    );

    #-- Parameter 3

    #-- label
    my $lparameter3 = $frm_middle->Label( -text => 'Parameter 3' );
    $lparameter3->form(
        -top     => [ $lparameter2, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );

    #-- hint
    my $eparahnt3 = $frm_middle->Entry(
        -width => 28,
    );
    $eparahnt3->form(
        -top  => [ '&', $lparameter3, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- value
    my $eparaval3 = $frm_middle->Entry( -width => 10, );
    $eparaval3->form(
        -top   => [ '&', $lparameter3, 0 ],
        -right => [ '&', $erepofile,   0 ],
    );

    #-- button
    my $add3val = $frm_middle->Button(
        -image   => 'edit16',
        -command => [\&update_value, $self, $view, 3],
    );
    $add3val->form(
        -top  => [ '&', $lparameter3, 0 ],
        -left => [ $eparaval3, 3 ],
    );

    #-  Frame Bottom - Description

    my $frm_bottom = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'Description',
        -labelside  => 'acrosstop',
    );
    $frm_bottom->pack(
        -expand => 1,
        -fill   => 'both',
     );

    #- Detalii

    my $tdescr = $frm_bottom->Scrolled(
        'Text',
        -width      => 40,
        -height     => 2,
        -wrap       => 'word',
        -scrollbars => 'e',
        -background => 'white',
    );
    $tdescr->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    my $fonttdes = $tdescr->cget('-font');

    # Entry objects
    $self->{controls} = {
        repofile => [ undef, $erepofile ],
        id_rep   => [ undef, $eid_rep   ],
        descr    => [ undef, $tdescr    ],
        parahnt1 => [ undef, $eparahnt1 ],
        paraval1 => [ undef, $eparaval1 ],
        parahnt2 => [ undef, $eparahnt2 ],
        paraval2 => [ undef, $eparaval2 ],
        parahnt3 => [ undef, $eparahnt3 ],
        paraval3 => [ undef, $eparaval3 ],
    };

    #-- TM header

    my $header = {
        colstretch    => 2,
        selectorcol   => 3,
        selectorstyle => 'radio',
        selectorcolor => 'darkgreen',
        columns       => {
            repno => {
                id          => 0,
                label       => '#',
                tag         => 'ro_center',
                displ_width => 3,
                valid_width => 5,
                numscale    => 0,
                readwrite   => 'ro',
                datatype    => 'integer',
            },
            id_rep => {
                id          => 1,
                label       => 'id',
                tag         => 'ro_center',
                displ_width => 3,
                valid_width => 5,
                numscale    => 0,
                readwrite   => 'ro',
                datatype    => 'integer',
            },
            title => {
                id          => 2,
                label       => 'Title',
                tag         => 'ro_left',
                displ_width => 10,
                valid_width => 10,
                numscale    => 0,
                readwrite   => 'ro',
                datatype    => 'alphanumplus',
            },
        },
    };

    $self->{tmx}->init( $frm_top, $header );
    $self->{tmx}->clear_all;
    $self->{tmx}->configure(-state => 'disabled');

    $self->load_report_list( $header->{selectorcol} );
    $self->load_report_details();

    return;
}

=head2 select_idx

Select the index and load its details.

=cut

sub select_idx {
    my ($self, $sel) = @_;

    my $idx = $sel -1 ;
    $self->{tmx}->set_selected($sel);
    $self->load_report_details();

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

=head2 load_report_list

Load report list from the L<reports> table.

=cut

sub load_report_list {
    my ($self, $sc) = @_;

    my $args = {};
    $args->{table}    = $self->{scrcfg}->maintable->{name}; # reports
    $args->{colslist} = [qw{id_rep title}]; #  id_user
    $args->{where}    = undef;
    $args->{order}    = 'title';

    my $reports_list = $self->{model}->table_batch_query($args);

    my $recno = 0;
    foreach my $rec ( @{$reports_list} ) {
        $recno++;
        my $titles = {
            repno  => $recno,
            id_rep => $rec->{id_rep},
            title  => $rec->{title},
        };

        push @{ $self->{_rl} }, $titles;
    }

    # Clear and fill
    $self->{tmx}->clear_all();
    $self->{tmx}->fill( $self->{_rl} );
    $self->{tmx}->tmatrix_make_selector($sc);

    return;
}

=head2 load_report_details

On selected report, load the configuration details from the
L<reports_det> table.

=cut

sub load_report_details {
    my $self = shift;

    my $selected_row = $self->{tmx}->get_selected;

    return unless $selected_row;

    my $idx    = $selected_row - 1;                 # index for array
    my $id_rep = $self->{_rl}[$idx]{id_rep};

    #- main table

    my $args = {};
    $args->{table}    = 'reports';
    $args->{colslist} = [qw{id_rep repofile title descr}];
    $args->{where}    = {id_rep => $id_rep};
    $args->{order}    = 'title';

    $self->{_rd} = $self->{model}->table_batch_query($args);

    #- dependent table

    $args = {};
    $args->{table} = $self->{scrcfg}->deptable->{tm1}{name};    # reports_det
    $args->{colslist}
        = [qw{id_rep id_art hint tablename resultfield searchfield headerlist }];
    $args->{where} = { id_rep => $id_rep };
    $args->{order} = 'id_art';

    $self->{_rdd} = $self->{model}->table_batch_query($args);

    my $eobj = $self->get_controls();

    #- Write report detail data to controls

    #-- main fields

    foreach my $field ( keys %{$eobj} ) {
        my $start_idx = $field eq 'descr' ? "1.0" : 0; # 'descr' is Text
        my $value = $self->{_rd}->[0]{$field};
        $eobj->{$field}[1]->delete( $start_idx, 'end' );
        $eobj->{$field}[1]->insert( $start_idx, $value ) if $value;
    }

    #-- parameters

    foreach my $i ( 1 .. 3 ) {
        my $field = "parahnt$i";
        my $idx = $i - 1;
        my $value = $self->{_rdd}[$idx]{hint};
        $eobj->{$field}[1]->delete( 0, 'end' );
        $eobj->{$field}[1]->insert( 0, $value ) if $value;
    }

    return;
}

=head2 preview_report

Preview the report using the Report manager utility L<printrep.bin> on
GNU/Linux L<printrepxp.exe> on Windows.  Fool path to this utilities
is set in the <main.yml> configuration file.

=cut

sub preview_report {
    my $self = shift;

    # Get report filename
    my $report_file = $self->{_rd}[0]{repofile};

    my $parameters = $self->get_parameters();
    print "Parameters: [ $parameters ]\n";

    my $report_path = catfile( $self->{cfg}->configdir, 'rep', $report_file );
    unless ( -f $report_path ) {
        print "Report file not found: $report_path\n";
        return;
    }
    print "Report file: $report_path\n";

    # Metaviewxp param for pages:  -from 1 -to 1

    my $report_exe  = $self->{cfg}->cfextapps->{repman}{exe_path};
    print "repman exe: $report_exe \n";

    my $cmd = qq{"$report_exe" -preview $parameters "$report_path"};
    print $cmd. "\n";
    if ( system $cmd ) {
        print "metaprintxp failed\n";
    }

    return;
}

=head2 get_parameters

Build parameter list from screen entry values.

=cut

sub get_parameters {
    my $self = shift;

    my $eobj = $self->get_controls();

    my $parameters = q{};    # empty

    foreach my $i ( 1 .. 3 ) {
        my $field_def = "paradef$i";
        my $field_val = "paraval$i";

        my $def = $self->{_rd}[0]{$field_def} || q{};

        my $val = $eobj->{$field_val}[1]->get;
        if ( $val =~ /\S+/ ) {
            $val = Tpda3::Utils->trim($val);

            my $ii  = $i - 1;
            my $rdd = $self->{_rdd}[$ii];
            my $fld = $rdd->{resultfield};

            $parameters .= "-param$fld=$val ";
        }
    }

    return $parameters;
}

=head2 update_value

Callback to update the value of the paramater, using the I<Search>
dialog.

Info for the Search dialog table header is from L<etc/search.conf>, in
the application's L<etc> config dir.

=cut

sub update_value {
    my ($self, $view, $p_no) = @_;

    my $ii  = $p_no - 1;
    my $rd  = $self->{_rd}[$ii];
    my $rdd = $self->{_rdd}[$ii];

    return if scalar keys %{$rdd} == 0;

    #- Compose the parameter for the 'Search' dialog

    my $table = $rdd->{tablename};

    my $resultfield = $rdd->{resultfield};
    my $searchfield = $rdd->{searchfield};

    # Info for the Search dialog table header from L<res/search.conf>,
    # in the application's L<res> config dir.
    my $res_file    = $self->{cfg}->resource_path_for( 'search.conf', 'res' );
    my $res_data_hr = $self->{cfg}->config_data_from($res_file);
    my $attr        = $res_data_hr->{columns};

    my $para = {
        table   => $table,
        search  => $rdd->{searchfield},
        columns => [],
    };

    my @headerlist = split /,\ */, $rdd->{headerlist};
    my @fields;
    push @fields, $searchfield, @headerlist, $resultfield;

    my @cols;
    foreach my $field (@fields) {
        my $rec = {};
        $rec->{$field} = {
            width    => $attr->{$field}{displ_width},
            label    => $attr->{$field}{label},
            datatype => $attr->{$field}{datatype},
        };
        push @cols, $rec;
    }

    $para->{columns} = [@cols];    # add columns info to parameters

    my $dict   = Tpda3::Lookup->new;
    my $record = $dict->lookup( $view, $para );

    #- Update control value

    my $eobj = $self->get_controls();
    my $field_name_hnt = "parahnt$p_no";
    my $field_name_val = "paraval$p_no";
    my $value_label = $record->{$searchfield};
    my $value_param = $record->{$resultfield};
    $eobj->{$field_name_hnt}[1]->delete( 0, 'end' );
    $eobj->{$field_name_hnt}[1]->insert( 0, $value_label ) if $value_label;
    $eobj->{$field_name_val}[1]->delete( 0, 'end' );
    $eobj->{$field_name_val}[1]->insert( 0, $value_param ) if $value_param;

    return;
}

1;
