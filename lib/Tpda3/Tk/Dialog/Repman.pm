package Tpda3::Tk::Dialog::Repman;

# ABSTRACT: Dialog for preview and print of Report Manager reports

use 5.010;
use strict;
use warnings;
use utf8;

use IO::File;
use Try::Tiny;
use File::Spec::Functions;
use IPC::System::Simple 1.17 qw(capture);
use Locale::TextDomain 1.20 qw(Tpda3);

require Tpda3::Config;
require Tpda3::Tk::TB;
require Tpda3::Tk::TM;
require Tpda3::Utils;
require Tpda3::Lookup;
require Tpda3::Tk::Dialog::Message;

use Tk::widgets qw(Table);

use base q{Tpda3::Tk::Screen};

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    $self->{tb4} = {};       # ToolBar
    $self->{tlw} = {};       # TopLevel
    $self->{tmx} = undef;    # TableMatrix
    $self->{_rl} = undef;    # report titles list
    $self->{_rd} = undef;    # report details
    $self->{cfg} = Tpda3::Config->instance();

    $self->{params} = [];

    return $self;
}

sub run_screen {
    my ( $self, $view ) = @_;

    $self->{tlw} = $view->Toplevel();
    $self->{tlw}->title('Preview and print reports');
    # $self->{tlw}->geometry('478x560');

    $self->{view}  = $view;
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

    foreach my $name (qw {tb4pr tb4qt}) {
        $self->{tb4}->make_toolbar_button( $name, $attribs->{$name} );
    }

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
        -fill   => 'both',
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
        -state              => 'disabled',
    );
    $eid_rep->form(
        -top  => [ %0, 0  ],
        -left => [ %0, $f1d ],
    );

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
        -state              => 'disabled',
    );
    $erepofile->form(
        -top  => [ '&', $lrepofile, 0 ],
        -left => [ %0,  $f1d ],
    );

    my $frm_para = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'Criterii',
        -labelside  => 'acrosstop'
    )->pack(
        -side   => 'top',
        -expand => 0,
        -fill   => 'both',
    );

    #-- Header

    # $frm_para->Label(
    #     -text => 'Name' 
    # )->grid(
    #     -row    => 0,
    #     -column => 1,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );
    # $frm_para->Label(
    #     -text => 'Search' 
    # )->grid(
    #     -row    => 0,
    #     -column => 2,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );
    # $frm_para->Label(
    #     -text => 'Value' 
    # )->grid(
    #     -row    => 0,
    #     -column => 3,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );

    
    # #-- Parameter 1

    # #-- label
    # my $lparameter1 = $frm_para->Label(
    #     -text => '# 1' 
    # )->grid(
    #     -row    => 1,
    #     -column => 0,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );

    # #-- hint
    # my $eparahnt1 = $frm_para->Entry(
    #     -width => 15,
    # )->grid(
    #     -row    => 1,
    #     -column => 1,
    #     -sticky => 'e',
    #     -padx   => 3,
    # );

    # #-- den
    # my $eparaden1 = $frm_para->Entry(
    #     -width              => 15,
    #     -disabledbackground => $bg,
    #     -disabledforeground => 'black',
    #     -state              => 'disabled',
    # )->grid(
    #     -row    => 1,
    #     -column => 2,
    #     -sticky => 'e',
    #     -padx   => 3,
    # );

    # #-- value
    # my $eparaval1 = $frm_para->Entry(
    #     -width => 15,
    # )->grid(
    #     -row    => 1,
    #     -column => 3,
    #     -sticky => 'e',
    #     -padx   => 3,
    # );

    # #-- button
    # $self->{b_dlg1} = $frm_para->Button(
    #     -image   => 'edit16',
    #     -command => [\&update_value, $self, $view, 1],
    # )->grid(
    #     -row    => 1,
    #     -column => 4,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );

    # #-- Parameter 2

    # #-- label
    # my $lparameter2 = $frm_para->Label(
    #     -text => '# 2',
    # )->grid(
    #     -row    => 2,
    #     -column => 0,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );

    # #-- hint
    # my $eparahnt2 = $frm_para->Entry(
    #     -width => 15,
    # )->grid(
    #     -row    => 2,
    #     -column => 1,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );

    # #-- den
    # my $eparaden2 = $frm_para->Entry(
    #     -width              => 15,
    #     -disabledbackground => $bg,
    #     -disabledforeground => 'black',
    #     -state              => 'disabled',
    # )->grid(
    #     -row    => 2,
    #     -column => 2,
    #     -sticky => 'e',
    #     -padx   => 3,
    # );

    # #-- value
    # my $eparaval2 = $frm_para->Entry(
    #     -width => 15,
    # )->grid(
    #     -row    => 2,
    #     -column => 3,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );

    # #-- button
    # $self->{b_dlg2} = $frm_para->Button(
    #     -image   => 'edit16',
    #     -command => [\&update_value, $self, $view, 2],
    # )->grid(
    #     -row    => 2,
    #     -column => 4,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );

    # #-- Parameter 3

    # #-- label
    # my $lparameter3 = $frm_para->Label(
    #     -text => '# 3',
    # )->grid(
    #     -row    => 3,
    #     -column => 0,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );

    # #-- hint
    # my $eparahnt3 = $frm_para->Entry(
    #     -width => 15,
    # )->grid(
    #     -row    => 3,
    #     -column => 1,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );

    # #-- den
    # my $eparaden3 = $frm_para->Entry(
    #     -width              => 15,
    #     -disabledbackground => $bg,
    #     -disabledforeground => 'black',
    #     -state              => 'disabled',
    # )->grid(
    #     -row    => 3,
    #     -column => 2,
    #     -sticky => 'e',
    #     -padx   => 3,
    # );

    # #-- value
    # my $eparaval3 = $frm_para->Entry(
    #     -width => 15,
    # )->grid(
    #     -row    => 3,
    #     -column => 3,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );
    
    # #-- button
    # $self->{b_dlg3} = $frm_para->Button(
    #     -image   => 'edit16',
    #     -command => [\&update_value, $self, $view, 3],
    # )->grid(
    #     -row    => 3,
    #     -column => 4,
    #     -sticky => 'n',
    #     -padx   => 3,
    # );

    ###

    # Get list of fields
    # my $resource_file = $self->{cfg}->resource_path_for( 'impozit.yml', 'res' );
    # my $cols_ordered  = $self->{cfg}->config_data_from($resource_file);
    # $self->{columns}  = $self->{scrcfg}->maintable('columns');

    # label hint den value button
    
    $self->{columns} = {
        para1 => {
            bgcolor     => "white",
            ctrltype    => "e",
            datatype    => "integer",
            displ_width => 10,
            findtype    => "full",
            label       => "Hint 1",
            numscale    => 0,
            readwrite   => "rw",
            state       => "disabled",
            valid_width => 10,
        },
        para2 => {
            bgcolor     => "white",
            ctrltype    => "e",
            datatype    => "integer",
            displ_width => 10,
            findtype    => "full",
            label       => "Hint 2",
            numscale    => 0,
            readwrite   => "rw",
            state       => "disabled",
            valid_width => 10,
        },
        para3 => {
            bgcolor     => "white",
            ctrltype    => "e",
            datatype    => "integer",
            displ_width => 10,
            findtype    => "full",
            label       => "Hint 3",
            numscale    => 0,
            readwrite   => "rw",
            state       => "disabled",
            valid_width => 10,
        },
        para4 => {
            bgcolor     => "white",
            ctrltype    => "e",
            datatype    => "integer",
            displ_width => 10,
            findtype    => "full",
            label       => "Hint 4",
            numscale    => 0,
            readwrite   => "rw",
            state       => "disabled",
            valid_width => 10,
        },
        para5 => {
            bgcolor     => "white",
            ctrltype    => "e",
            datatype    => "integer",
            displ_width => 10,
            findtype    => "full",
            label       => "Hint 5",
            numscale    => 0,
            readwrite   => "rw",
            state       => "disabled",
            valid_width => 10,
        },
    };
    
    # Screen table columns metadata
    my @columns;
    my $idx = 0;

    foreach my $field ( @{ [qw{para1 para2 para3 para4 para5}] } ) {
        my $findtype = $self->{columns}{$field}{findtype};
        $columns[$idx] = [
            $field,
            $self->{columns}{$field}{label},
            $self->{columns}{$field}{datatype},
            $findtype,
        ];
        $idx++;
    }

    my $rows_idx = $#columns;

    $self->{table} = $frm_para->Table(
        -columns    => 5,
        -rows       => 3,
        #-fixedrows  => 1,
        -scrollbars => 'oe',
        -relief     => 'raised',
        -background => 'white'
    );

    #-- Fill table

    foreach my $r ( 0 .. $rows_idx ) {
        my $findtype = $columns[$r][3];
        my $no = $r + 1;

        # Label - row number
        my $crt_label = $self->{table}->Label(
            -text   => $no,
            -width  => 3,
            -relief => 'flat',
        );

        # Label - field label
        my $fld_label = $self->{table}->Label(
            -text   => $columns[$r][1],
            -width  => 20,
            -relief => 'sunken',
            -anchor => 'w',
            -bg     => 'white',
        );

        # Negate - checkbox
        my $v_negate = 0;
        my $cbx_negate = $self->{table}->Checkbutton(
            -text => 'nu',
            -indicatoron => 0,
            -selectcolor => 'pink',
            -state       => 'normal',
            -variable    => \$v_negate,
            -relief      => 'raised',
        );

        #- ComboBox choices

        my $selected;
        my $searchopt = $self->{table}->JComboBox(
            -entrywidth   => 14,
            -textvariable => \$selected,
        );

        my $qry_entry = $self->{table}->Entry(
            -width    => 15,
            -relief   => 'sunken',
            -bg       => 'white',
            -validate => 'all',
            -vcmd     => sub {
                $self->validate_criteria( @_ );
            },
        );

        #- Callback to clear the Entry
        $searchopt->configure(
            -browsecmd => sub {
                my ( $self, $search_ctrl, $sele ) = @_;
                $qry_entry->delete( 0, 'end' ) if $sele eq 'is null';
            },
        );

        $self->{table}->put( $r, 1, $crt_label );
        $self->{table}->put( $r, 2, $fld_label );
        $self->{table}->put( $r, 3, $cbx_negate );
        $self->{table}->put( $r, 4, $searchopt );
        $self->{table}->put( $r, 5, $qry_entry );

        $self->{widgets}[$r] = [ $columns[$r][0], \$v_negate, \$selected ];
    }

    $self->{table}->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    ###
    
    #---  Frame Bottom - Description

    my $frm_bottom = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'Description',
        -labelside  => 'acrosstop',
    );
    $frm_bottom->pack(
        -expand => 0,
        -fill   => 'both',
     );

    #- Detalii

    my $my_font = $eid_rep->cget('-font');

    my $tdescr = $frm_bottom->Scrolled(
        'Text',
        -width      => 40,
        -height     => 2,
        -wrap       => 'word',
        -scrollbars => 'e',
        -background => 'white',
        -font       => $my_font,
        -state      => 'disabled',
    );
    $tdescr->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    # Entry objects
    $self->{controls} = {
        repofile => [ undef, $erepofile ],
        id_rep   => [ undef, $eid_rep   ],
        descr    => [ undef, $tdescr    ],
        # parahnt1 => [ undef, $eparahnt1 ],
        # paraden1 => [ undef, $eparaden1 ],
        # paraval1 => [ undef, $eparaval1 ],
        # parahnt2 => [ undef, $eparahnt2 ],
        # paraden2 => [ undef, $eparaden2 ],
        # paraval2 => [ undef, $eparaval2 ],
        # parahnt3 => [ undef, $eparahnt3 ],
        # paraden3 => [ undef, $eparaden3 ],
        # paraval3 => [ undef, $eparaval3 ],
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

sub validate_criteria {
    my ( $self, $char, $ch, $cur, $idx, $act ) = @_;
    return 1;
}

sub select_idx {
    my ($self, $sel) = @_;
    my $idx = $sel -1 ;
    $self->{tmx}->set_selected($sel);
    $self->load_report_details();
    return;
}

sub dlg_exit {
    my $self = shift;
    $self->{tlw}->destroy;
    return;
}

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
    $args->{colslist} = [
        qw(
          id_rep
          id_art
          hint
          tablename
          resultfield
          paramname
          searchfield
          headerlist
        )
    ];
    $args->{where} = { id_rep => $id_rep };
    $args->{order} = 'id_art';

    $self->{_rdd} = $self->{model}->table_batch_query($args);

    # Make paramname same as resultfield if paramname is not defined
    my $cnt = scalar @{ $self->{_rdd} };
    if ( $cnt > 0 ) {
        my $maxi = $cnt - 1;
        foreach my $i ( 0 .. $maxi ) {
            $self->{_rdd}[$i]{paramname} = $self->{_rdd}[$i]{resultfield}
              unless $self->{_rdd}[$i]{paramname};
        }
    }

    my $eobj = $self->get_controls();

    #- Write report detail data to controls

    #-- main fields

    foreach my $field ( keys %{$eobj} ) {
        my $value = $self->{_rd}->[0]{$field};
        # print "# $field = $value\n";
        if ( $field eq 'descr' ) {
            $self->write_t( $field, $value,  );
        }
        else {
            $self->write_e( $field, $value );
        }
    }

    #-- parameters

    $self->{params} = [];
    foreach my $i ( 1 .. 3 ) {
        # my $field = "parahnt$i";
        # my $v_fld = "paraval$i";
        # my $idx = $i - 1;
        # my $value = $self->{_rdd}[$idx]{hint};
        # $eobj->{$field}[1]->delete( 0, 'end' );
        # if (defined $value) {
        #     $eobj->{$field}[1]->insert( 0, $value );
        #     push @{ $self->{params} }, $value;
        #     $eobj->{$field}[1]->configure( '-bg' => 'lightblue' );
        #     $eobj->{$v_fld}[1]->configure( '-bg' => 'white' );
        # }

        # # Disable the buttons if there is no table config
        # my $state = $self->{_rdd}[$idx]{tablename} ? 'normal' : 'disabled';
        # $self->{"b_dlg${i}"}->configure( -state => $state );
    }

    return;
}

sub write_e {
    my ($self, $field, $value) = @_;
    $self->{view}->control_write_e(
        $field, $self->{controls}{$field}, $value );
    return;
}

sub write_t {
    my ($self, $field, $value) = @_;
    $self->{view}->control_write_t(
        $field, $self->{controls}{$field}, $value );
    return;
}

sub preview_report {
    my $self = shift;

    # Get report filename
    my $report_file = $self->{_rd}[0]{repofile};

    my $params = $self->get_parameters;
    if ( scalar @{ $self->{params} } > 0 and not $params ) {
        my $msg = __ "Input a valid interval, please";
        my $lst = join ', ', @{ $self->{params} };
        my $det = __x( "Input the required parameters for {list}",
                       list => $lst );
        my $dlg = Tpda3::Tk::Dialog::Message->new( $self->{tlw} );
        $dlg->message_dialog( $msg, $det, 'info', 'ok' );
        return;
    }

    my $report_path = catfile( $self->{cfg}->configdir, 'rep', $report_file );
    unless ( -f $report_path ) {
        print "Report file not found: $report_path\n";
        my $msg = __ "Configuration error";
        my $det = __x( "Report file not found: {file}", file => $report_path );
        my $dlg = Tpda3::Tk::Dialog::Message->new( $self->{tlw} );
        $dlg->message_dialog( $msg, $det, 'error', 'ok' );
        return;
    }

    # Metaviewxp param for pages:  -from 1 -to 1

    my $cmd = $self->{cfg}->cfextapps->{repman}{exe_path};

    my @args = ('-preview');
    push @args, $params if $params;
    push @args, $report_path;

    my $output = q{};
    try {
        # Not capture($cmd, @args)!, always use the shell:
        $output = capture("$cmd @args");
    }
    catch {
        print "EE: '$cmd @args': $_\n";
    }
    finally {
        print "II: >$output<\n";
    };

    return;
}

sub get_parameters {
    my $self = shift;

    my $eobj = $self->get_controls();

    my $params = q{};    # empty

    foreach my $i ( 1 .. 5 ) {
        my $field_def = "paradef$i";
        my $field_val = "paraval$i";

        my $def = $self->{_rd}[0]{$field_def} || q{};

        my $val = $eobj->{$field_val}[1]->get;
        if ( $val =~ /\S+/ ) {
            $val = Tpda3::Utils->trim($val);

            my $ii  = $i - 1;
            my $rdd = $self->{_rdd}[$ii];
            my $fld = uc $rdd->{paramname};

            $params .= "-param$fld=$val ";
        }
    }
    say "params=$params";
    return $params;
}

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
        # order   => $rdd->{resultfield},
        columns => [],
    };

    my @headerlist = split /,\s*/, $rdd->{headerlist};
    my @fields;
    push @fields, $searchfield, @headerlist, $resultfield;

    my @cols;
    foreach my $field (@fields) {
        my $rec = {};
        $rec->{$field} = {
            label       => $attr->{$field}{label},
            displ_width => $attr->{$field}{displ_width},
            datatype    => $attr->{$field}{datatype},
        };
        push @cols, $rec;
    }

    $para->{columns} = [@cols];    # add columns info to parameters

    my $dict   = Tpda3::Lookup->new;
    my $record = $dict->lookup( $view, $para );

    #- Update control value

    my $eobj = $self->get_controls();
    my $value_label = $record->{$searchfield};
    my $value_param = $record->{$resultfield};
    $self->write_e( "paraden$p_no", $value_label );
    $self->write_e( "paraval$p_no", $value_param );

    return;
}

sub update_labels {
    my ($self, $name, $value) = @_;
    $self->{$name}->configure(-text => $value) if defined $value;
    return;
}

1;

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Repman;

    my $fd = Tpda3::Tk::Dialog::Repman->new;

    $fd->search($self);

=head2 new

Constructor method.

=head2 run_screen

Define and show search dialog.

=head2 select_idx

Select the index and load its details.

=head2 dlg_exit

Quit Dialog.

=head2 load_report_list

Load report list from the L<reports> table.

=head2 load_report_details

On selected report, load the configuration details from the
L<reports_det> table.

=head2 preview_report

Preview the report using the Report manager utility L<printrep.bin> on
GNU/Linux L<printrepxp.exe> on Windows.  Fool path to this utilities
is set in the <main.yml> configuration file.

=head2 get_parameters

Build parameter list from screen entry values.

=head2 update_value

Callback to update the value of the paramater, using the I<Search>
dialog.

Info for the Search dialog table header is from L<res/search.conf>, in
the application's L<res> config dir.

=cut
