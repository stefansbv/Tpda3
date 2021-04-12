package Tpda3::Tk::Dialog::Repman;

# ABSTRACT: Dialog for preview and print of Report Manager reports

use 5.010;
use strict;
use warnings;
use utf8;

use IO::File;
use Try::Tiny;
use Scalar::Util qw(blessed);
use File::Spec::Functions;
use IPC::System::Simple 1.30 qw(capture);
use Locale::TextDomain 1.20 qw(Tpda3);

use Tpda3::Config;
use Tpda3::Tk::TB;
use Tpda3::Tk::TM;
use Tpda3::Utils;
use Tpda3::Lookup;
use Tpda3::Tk::Dialog::Message;

use Tk::widgets qw(Table); # Tk::Table

use base q{Tpda3::Tk::Screen};

use Data::Dump qw/dump/;
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
    $self->{tlw}->geometry('480x580');

    $self->{view}  = $view;
    $self->{model} = $view->{_model};

    my $f1d = 60;              # distance from left

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
        -label      => 'Report',
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
        -text => 'File',
    );
    $lid_rep->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );
    #--
    my $eid_rep = $frm_middle->Entry(
        -width => 5,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
        -state              => 'disabled',
    );
    $eid_rep->form(
        -top  => [ %0, 0  ],
        -left => [ %0, $f1d ],
    );

    my $erepofile = $frm_middle->Entry(
        -width              => 50,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
        -state              => 'disabled',
    );
    $erepofile->form(
        -top  => [ '&', $lid_rep, 0 ],
        -left => [ $eid_rep,  5 ],
    );

    my $frm_para = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'Parametrii',
        -labelside  => 'acrosstop'
    )->pack(
        -side   => 'top',
        -expand => 0,
        -fill   => 'both',
    );

    ###

    $self->{columns} = {
        1 => { ctrltype => "l", purpose => "count" },
        2 => { ctrltype => "e", purpose => "hint" },
        3 => { ctrltype => "b", purpose => "select" },
        4 => { ctrltype => "e", purpose => "paraname" },
        5 => { ctrltype => "e", purpose => "paravalue" },
    };

    $self->{table} = $frm_para->Table(
        -columns    => 5,
        -rows       => 3,
        #-fixedrows  => 1,
        -scrollbars => 'oe',
        -relief     => 'raised',
        -background => 'white'
    );

    #-- Fill table

    foreach my $r ( 0 .. 4 ) {
        my $no = $r + 1;

        # Label - row number - [count]
        my $crt_label = $self->{table}->Label(
            -text   => $no,
            -width  => 3,
            -relief => 'flat',
        );

        # Label - [hint]
        my $hint_label = $self->{table}->Entry(
            -width  => 21,
            -relief => 'sunken',
            -bg     => 'white',
            -disabledbackground => $bg,
            -disabledforeground => 'black',
        );

        # Button - [select]
        my $b_search = $self->{table}->Button(
            -image   => 'navforward16',
            -state   => 'normal',
            -relief  => 'raised',
            -command => [ \&update_value, $self, $view, $r ],
        );

        # Entry - [paraname]
        my $entry_search = $self->{table}->Entry(
            -width    => 16,
            -relief   => 'sunken',
            -bg       => 'white',
            -disabledbackground => $bg,
            -disabledforeground => 'black',
        );

        # Entry - [paravalue]
        my $qry_entry = $self->{table}->Entry(
            -width    => 16,
            -relief   => 'sunken',
            -bg       => 'white',
            -disabledbackground => $bg,
            -disabledforeground => 'black',
        );

        $self->{table}->put( $r, 1, $crt_label );
        $self->{table}->put( $r, 2, $hint_label );
        $self->{table}->put( $r, 3, $b_search );
        $self->{table}->put( $r, 4, $entry_search );
        $self->{table}->put( $r, 5, $qry_entry );
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

sub table_read {
    my $self = shift;
    my $rows = $self->{table}->totalRows;
    my @result;
    for ( my $ri = 0 ; $ri < $rows ; $ri++ ) {
        my $field = $self->table_entry_read($ri, 4); # fixed cols
        my $value = $self->table_entry_read($ri, 5);
        push @result, [ $field, $value ] if $value;
    }
    return \@result;
}

sub get_table_widget {
    my ( $self, $row, $col ) = @_;
    my $widget = $self->{table}->get( $row, $col );
    my $w_type = $self->{columns}{$col}{ctrltype};
    return ( $widget, $w_type );
}

sub table_entry_read {
    my ( $self, $row, $col ) = @_;
    my ($widget, $w_type) = $self->get_table_widget( $row, $col );
    my $meth = "control_read_${w_type}";
    unless ( $self->can($meth) ) {
        die "table_entry_read: method '$meth' not implemented";
    }
    return $self->$meth($widget);
}

sub table_entry_write {
    my ( $self, $row, $col, $value, $status, $fg, $bg ) = @_;
    my ($widget, $w_type) = $self->get_table_widget( $row, $col );
    my $meth = "control_write_${w_type}";
    if ( $self->can($meth) ) {
        $self->$meth( $widget, $value, $fg, $bg, $status );
    }
    else {
        die "table_entry_write: method '$meth' not implemented";
    }
    return $value;
}

sub table_entry_status {
    my ( $self, $row, $col, $status ) = @_;
    my ($widget, $w_type) = $self->get_table_widget( $row, $col );
    $widget->configure( -state => $status );
    return $status;
}

sub select_idx {
    my ($self, $sel) = @_;
    my $idx = $sel -1;
    $self->{tmx}->set_selected($sel);
    $self->reset_params;
    $self->load_report_details;
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
        if ( $field eq 'descr' ) {
            $self->write_t( $field, $value,  );
        }
        else {
            $self->write_e( $field, $value );
        }
    }

    #-- parameters
    my @params = @{ $self->{_rdd} };
    my $bg = $self->{tlw}->cget('-background');
    
    # Fill params in table
    my $rows = $self->{table}->totalRows;
    for ( my $ri = 0 ; $ri < $rows ; $ri++ ) {
        my $hint  = $params[$ri]{hint};
        my $pname = $params[$ri]{paramname};
        if ( defined $hint and defined $pname ) {
            push @{ $self->{params} }, [ $hint, $pname ];
            $self->table_entry_write( $ri, 2, $hint, 'readonly' );
            $self->table_entry_status( $ri, 3, 'normal' );
            $self->table_entry_write( $ri, 4, $pname, 'readonly' );
            $self->table_entry_write( $ri, 5, '', 'normal' );
        }
        else {
            $self->table_entry_write( $ri, 2, '', 'disabled', undef, $bg );
            $self->table_entry_write( $ri, 4, '', 'disabled' );
            $self->table_entry_write( $ri, 5, '', 'disabled' );
            $self->table_entry_status( $ri, 3, 'disabled' );
        }
    }
    return;
}

sub write_e {
    my ($self, $field, $value) = @_;
    $self->{view}->control_write_e(
        $field, $self->{controls}{$field}, $value );
    return;
}

sub control_write_e {
    my ( $self, $control, $value, $fg, $bg, $state ) = @_;
    unless ( blessed $control and $control->isa('Tk::Entry') ) {
        warn qq(Widget for writing value'$value' not found\n);
        return;
    }
    $state //= $control->cget('-state');
    $value = q{} unless defined $value;    # empty
    $control->configure( -state => 'normal' );
    $control->delete( 0, 'end' );
    $control->insert( 0, $value ) if defined $value;
    $control->configure( -bg => $bg ) if $bg;
    $control->configure( -fg => $fg ) if $fg;
    $control->configure( -state => $state );
    return;
}

sub control_read_e {
    my ( $self, $control ) = @_;
    unless ( blessed $control and $control->isa('Tk::Entry') ) {
        warn qq(Widget for reading ... not found\n);
        return;
    }
    return $control->get;
}

sub control_write_l {
    my ( $self, $control, $value, $fg, $bg, $state ) = @_;
    unless ( blessed $control and $control->isa('Tk::Label') ) {
        warn qq(Widget for writing value'$value' not found\n);
        return;
    }
    $state //= $control->cget('-state');
    $value = q{} unless defined $value;    # empty
    $control->configure( -text => $value );
    $control->configure( -bg => $bg ) if $bg;
    $control->configure( -fg => $fg ) if $fg;
    $control->configure( -state => $state );
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

    my $params_str = $self->get_parameters;
    if ( scalar @{ $self->{params} } > 0 and not $params_str ) {
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
    push @args, $params_str if $params_str;
    push @args, $report_path;

    my $output = q{};
    try {
        # Not capture($cmd, @args)!, always use the shell: ( why?! :) )
        $output = capture("$cmd @args");
    }
    catch {
        print "EE: '$cmd @args': $_ $output\n";
    }
    finally {
        print "II: >$output<\n";
    };

    return;
}

sub get_parameters {
    my $self = shift;
    my $result = $self->table_read;
    my $params = q{};    # empty
    foreach my $r ( @{$result} ) {
        my $nam = uc $r->[0];
        my $val = $r->[1];
        if ( $val =~ /\S+/ ) {
            $val = Tpda3::Utils->trim($val);
            $params .= "-param$nam=$val ";
        }
    }
    say "params=$params";
    return $params;
}

sub update_value {
    my ($self, $view, $row) = @_;

    my $rd  = $self->{_rd}[$row];   # report details
    my $rdd = $self->{_rdd}[$row];

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

    my @fields = ($searchfield, $resultfield);
    if ( defined $rdd->{headerlist} ) {
        my @headerlist = split /,\s*/, $rdd->{headerlist};
        push @fields, @headerlist;
    }
    print "# fields:\n";
    dump @fields;

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

    #- Update control value in table

    my $eobj = $self->get_controls();
    my $value_param = $record->{$resultfield};
    $self->table_entry_write( $row, 5, $value_param, 'normal', );

    return;
}

sub update_labels {
    my ($self, $name, $value) = @_;
    $self->{$name}->configure(-text => $value) if defined $value;
    return;
}

sub reset_params {
    my $self = shift;
    my $rows = $self->{table}->totalRows;
    for ( my $ri = 0 ; $ri < $rows ; $ri++ ) {
        $self->table_entry_write( $ri, 4, '', 'disabled' );
        $self->table_entry_write( $ri, 5, '', 'disabled' );
    }
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
