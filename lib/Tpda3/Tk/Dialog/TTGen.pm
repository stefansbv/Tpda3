package Tpda3::Tk::Dialog::TTGen;

use strict;
use warnings;
use utf8;

use IO::File;
use File::Spec::Functions;
use Log::Log4perl qw(get_logger :levels);
use Locale::TextDomain 1.20 qw(Tpda3);
use Try::Tiny;
use Hash::Merge qw(merge);
use Tk;

require Tpda3::Config;
require Tpda3::Tk::TB;
require Tpda3::Tk::TM;
require Tpda3::Utils;
require Tpda3::Lookup;
require Tpda3::Db;
require Tpda3::Exceptions;

use base q{Tpda3::Tk::Screen};

=encoding utf8

=head1 NAME

Tpda3::Tk::Dialog::TTGen - Dialog for generating documentes from templates.

=head1 VERSION

Version 0.89

=cut

our $VERSION = 0.89;

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::TTGen;

    my $fd = Tpda3::Tk::Dialog::TTGen->new;

    $fd->search($self);

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    $self->{tb4}  = {};       # ToolBar
    $self->{tlw}  = {};       # TopLevel
    $self->{tmx}  = undef;    # TableMatrix
    $self->{_rl}  = undef;    # template titles list
    $self->{_cfg} = Tpda3::Config->instance();
    $self->{_db}  = Tpda3::Db->instance;
    $self->{_log} = get_logger();

    return $self;
}

=head2 dbc

Return the connection object handler.

=cut

sub dbc {
    my $self = shift;
    return $self->{_db}->dbc;
}

=head2 dbh

Return the database object handler.

=cut

sub dbh {
    my $self = shift;
    return $self->{_db}->dbh;
}

=head2 _cfg

Return configuration instance object.

=cut

sub _cfg {
    my $self = shift;
    return $self->{_cfg};
}

=head2 _log

Return the log object.

=cut

sub _log {
    my $self = shift;
    return $self->{_log};
}

=head2 scrcfg

Return the screen configuration object.

=cut

sub scrcfg {
    my $self = shift;
    return $self->{scrcfg};
}

=head2 model

Return the model object.

=cut

sub model {
    my $self = shift;
    return $self->{model};
}

=head2 view

Return the view object.

=cut

sub view {
    my $self = shift;
    return $self->{view};
}

=head2 run_screen

Define and show search dialog.

=cut

sub run_screen {
    my ( $self, $view ) = @_;

    $self->{tlw} = $view->Toplevel();
    $self->{tlw}->title('Generate documents');
    $self->{tlw}->geometry('480x520');

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

    $self->{tb4}->make_toolbar_button( 'tb4qt', $attribs->{$name} );

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

    #-- ID template (id_tt)

    my $lid_tt = $frm_middle->Label(
        -text => 'ID template',
    );
    $lid_tt->form(
        -top     => [ %0, 0  ],
        -left    => [ %0, 10 ],
    );
    #--
    my $eid_tt = $frm_middle->Entry(
        -width => 12,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $eid_tt->form(
        -top  => [ %0, 0  ],
        -left => [ %0, $f1d ],
    );

    #-- tt_file

    my $ltt_file = $frm_middle->Label( -text => 'Template file', );
    $ltt_file->form(
        -top     => [ $lid_tt, 5 ],
        -left    => [ %0,     10 ],
    );

    my $ett_file = $frm_middle->Entry(
        -width              => 40,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $ett_file->form(
        -top  => [ '&', $ltt_file, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-- Range

    #-- label
    my $lrange = $frm_middle->Label( -text => 'Range' );
    $lrange->form(
        -top     => [ $ltt_file, 8 ],
        -left    => [ %0, 10 ],
    );

    #-- range from
    my $erange_from = $frm_middle->Entry(
        -width   => 6,
        -justify => 'right',
    );
    $erange_from->form(
        -top  => [ '&', $lrange, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- label
    my $lrange_ft = $frm_middle->Label( -text => '-:-' );
    $lrange_ft->form(
        -top     => [ '&', $lrange, 0 ],
        -left    => [ $erange_from, 3 ],
    );

    #-- range to
    my $erange_to = $frm_middle->Entry(
        -width   => 6,
        -justify => 'right',
    );
    $erange_to->form(
        -top  => [ '&', $lrange, 0 ],
        -left => [ $lrange_ft,   3 ],
    );

    #-- button
    my $add1val = $frm_middle->Button(
        -image   => 'edit16',
        -command => [\&batch_generate_doc, $self],
    );
    $add1val->form(
        -top  => [ '&', $lrange, 0 ],
        -left => [ $erange_to, 5 ],
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
        id_tt      => [ undef, $eid_tt ],
        tt_file    => [ undef, $ett_file ],
        descr      => [ undef, $tdescr ],
        range_from => [ undef, $erange_from ],
        range_to   => [ undef, $erange_to ],
    };

    #-- TM header

    my $header = {
        colstretch    => 2,
        selectorcol   => 3,
        selectorstyle => 'radio',
        selectorcolor => 'darkgreen',
        columns       => {
            recno => {
                id          => 0,
                label       => '#',
                tag         => 'ro_center',
                displ_width => 3,
                valid_width => 5,
                numscale    => 0,
                readwrite   => 'ro',
                datatype    => 'integer',
            },
            id_tt => {
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

    $self->load_template_list( $header->{selectorcol} );
    $self->load_tt_details();

    return;
}

=head2 select_idx

Select the index and load its details.

=cut

sub select_idx {
    my ($self, $sel) = @_;
    my $idx = $sel -1 ;
    $self->{tmx}->set_selected($sel);
    $self->load_tt_details();
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

=head2 load_template_list

Load template list from the L<templates> table.

=cut

sub load_template_list {
    my ($self, $sc) = @_;

    my $args = {};
    $args->{table}    = $self->scrcfg->maintable('name'); # templates
    $args->{colslist} = [qw{id_tt title}];
    $args->{where}    = undef;
    $args->{order}    = 'title';

    my $templates_list = $self->model->table_batch_query($args);

    my $recno = 0;
    foreach my $rec ( @{$templates_list} ) {
        $recno++;
        my $titles = {
            recno => $recno,
            id_tt => $rec->{id_tt},
            title => $rec->{title},
        };

        push @{ $self->{_rl} }, $titles;
    }

    # Clear and fill
    $self->{tmx}->clear_all();
    $self->{tmx}->fill( $self->{_rl} );
    $self->{tmx}->tmatrix_make_selector($sc);

    return;
}

=head2 load_tt_details

On selected template, load the configuration details from the
L<templates_var> table.

=cut

sub load_tt_details {
    my $self = shift;

    my $selected_row = $self->{tmx}->get_selected;

    return unless $selected_row;

    my $idx   = $selected_row - 1;                 # index for array
    my $id_tt = $self->{_rl}[$idx]{id_tt};

    #- main table

    my $args = {};
    $args->{table}    = 'templates';
    $args->{colslist} = [qw{id_tt tt_file title descr}];
    $args->{where}    = {id_tt => $id_tt};
    $args->{order}    = 'title';

    $self->{_rd} = $self->model->table_batch_query($args);

    #- Write template detail data to controls

    foreach my $field ( qw{id_tt tt_file descr range_from range_to} ) {
        my $fld_cfg = $self->scrcfg()->maintable( 'columns', $field );
        my $state   = $fld_cfg->{state};
        my $bg      = $fld_cfg->{bgcolor};
        my $value   = $self->{_rd}->[0]{$field};
        if ( $field eq 'descr' ) {
            $self->view->control_write_t( $field, $self->{controls}{$field},
                $value );
        }
        else {
            $self->view->control_write_e( $field, $self->{controls}{$field},
                $value );
        }
        my $control = $self->get_controls($field);
        $self->view->configure_controls( $control->[1], $state, $bg, $fld_cfg );
    }

    return;
}

=head2 batch_generate_doc

Generate the documents in the ID range provided by the user.

=cut

sub batch_generate_doc {
    my $self = shift;

    # Get report filename
    my $tt_file = $self->{_rd}[0]{tt_file};

    # Model file name
    my $model_file
        = catfile( $self->_cfg->configdir, 'tex', 'model', $tt_file );
    unless ( -f $model_file ) {
        die "Template file not found: $model_file\n";
        return;
    }

    # Read screen
    my $id_tt      = $self->{controls}{id_tt}[1]->get;
    my $range_from = $self->{controls}{range_from}[1]->get;
    my $range_to   = $self->{controls}{range_to}[1]->get;

    unless (( $range_from and $range_to )
        and ( $range_from <= $range_to ) )
    {
        my $dlg     = Tpda3::Tk::Dialog::Message->new( $self->view );
        my $message = __ 'Range error';
        my $details = __ 'A valid range is required!';
        $dlg->message_dialog( $message, $details, 'info', 'close' );
        return;
    }

    my $datasources = $self->model->get_template_datasources($id_tt);
    my $table_name  = $datasources->{table_name};
    my $view_name   = $datasources->{view_name};

    # Record data
    my $fields = $self->model->table_columns($view_name);
    my $key0   = $self->model->table_keys($table_name)->[0];
    my $args   = {};
    $args->{table}    = $view_name;
    $args->{colslist} = $fields;
    $args->{order}    = $key0;
    $args->{where}    = {
        $key0 => { -between => [ $range_from, $range_to ] } };
    my $recs_aref     = $self->model->table_batch_query($args);

    # Data from other sources
    my $other_data = $self->model->other_data($tt_file);

    my $rec_no = scalar @{$recs_aref};
    if ($rec_no <= 0 ) {
        my $dlg     = Tpda3::Tk::Dialog::Message->new( $self->view );
        my $message = __ 'Range error';
        my $details = __ 'No records to proces, the table is empty!';
        $dlg->message_dialog( $message, $details, 'info', 'close' );
        return;
    }

    # Generate
    foreach my $record ( @{$recs_aref} ) {
        my $rec = Hash::Merge->new->merge(
            $record,
            $other_data,
        );
        $self->view->generate_doc( $model_file, $rec, $rec->{$key0} );
    }

    return;
}

1;
