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
require Tpda3::Generator;
require Tpda3::Exceptions;

use base q{Tpda3::Tk::Screen};

=head1 NAME

Tpda3::Tk::Dialog::TTGen - Dialog for generating documentes from templates.

=head1 VERSION

Version 0.80

=cut

our $VERSION = 0.80;

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
    $self->{_log} = get_logger();

    return $self;
}

=head2 dbc

Return the Connection module handler.

=cut

sub dbc {
    my $self = shift;
    my $db = Tpda3::Db->instance;
    return $db->dbc;
}

sub dbh {
    my $self = shift;
    my $db = Tpda3::Db->instance;
    return $db->dbh;
}

sub _cfg {
    my $self = shift;
    return $self->{_cfg};
}

sub _log {
    my $self = shift;
    return $self->{_log};
}

sub scrcfg {
    my $self = shift;
    return $self->{scrcfg};
}

sub model {
    my $self = shift;
    return $self->{model};
}

=head2 run_screen

Define and show search dialog.

=cut

sub run_screen {
    my ( $self, $view ) = @_;

    $self->{tlw} = $view->Toplevel();
    $self->{tlw}->title('Generate documents');
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
            'tooltip' => 'Generate document',
            'icon'    => 'fileprint16',
            'sep'     => 'none',
            'help'    => 'Generate document',
            'method'  => sub { $self->preview_template(); },
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
        -width   => 10,
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
        -width   => 10,
        -justify => 'right',
    );
    $erange_to->form(
        -top  => [ '&', $lrange, 0 ],
        -left => [ $lrange_ft,   3 ],
    );

    #-- button
    my $add1val = $frm_middle->Button(
        -image   => 'edit16',
        -command => [\&batch_generate_doc, $self, $view],
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
L<templates_det> table.

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

    my $eobj = $self->get_controls();

    #- Write template detail data to controls

    #-- main fields

    foreach my $field ( keys %{$eobj} ) {
        my $start_idx = $field eq 'descr' ? "1.0" : 0; # 'descr' is Text
        my $value = $self->{_rd}->[0]{$field};
        $eobj->{$field}[1]->delete( $start_idx, 'end' );
        $eobj->{$field}[1]->insert( $start_idx, $value ) if $value;
    }

    return;
}

sub batch_generate_doc {
    my ($self, $view) = @_;

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
    my $id         = $self->{controls}{id_tt}[1]->get;
    my $range_from = $self->{controls}{range_from}[1]->get || 1;
    my $range_to   = $self->{controls}{range_to}[1]->get   || 3;

    # Get datasources
    my $args = {};
    $args->{table}    = $self->scrcfg->maintable('name'); # == templates
    $args->{colslist} = [qw{table_name view_name common_data}];
    $args->{where}    = { id_tt => $id };
    $args->{order}    = 'id_tt';
    my $datasources = $self->model->table_batch_query($args);
    my $table_name  = $datasources->[0]{table_name};
    my $view_name   = $datasources->[0]{view_name};
    my $common      = $datasources->[0]{common_data};

    # Table info - view
    my $table_info = $self->dbc->table_info_short($view_name);
    my $keys       = $self->dbc->table_keys($table_name);
    my @fields;
    foreach my $k ( sort { $a <=> $b } keys %{$table_info} ) {
        my $name = $table_info->{$k}{name};
        my $info = $table_info->{$k};
        push @fields, $name;
    }
    my $key0 = $keys->[0];                   # only the first!

    # Record data
    $args = {};
    $args->{table}    = $view_name;
    $args->{colslist} = \@fields;
    $args->{order}    = $key0;
    $args->{where}    = {
        $key0 => { -between => [ $range_from, $range_to ] } };
    my $recs_aref     = $self->model->table_batch_query($args);

    # Common data
    $args = {};
    $args->{table}    = $common;
    $args->{colslist} = [qw{var_name var_value}];
    $args->{order}    = undef;
    $args->{where}    = undef;
    my $common_aref   = $self->model->table_batch_query($args);
    my %common = map { $_->{var_name} => $_->{var_value} } @{$common_aref};

    # Specific data
    $args = {};
    $args->{table}    = 'templates_det';
    $args->{colslist} = [qw{var_name var_value}];
    $args->{where}    = { id_tt => $id };
    $args->{order}    = 'id_tt';
    my $specif_aref   = $self->model->table_batch_query($args);
    my %specific = map { $_->{var_name} => $_->{var_value} } @{$specif_aref};

    # Premerge
    my $other = Hash::Merge->new->merge(
        \%common,
        \%specific,
    );

    # Generate
    foreach my $rec ( @{$recs_aref} ) {
        my $record = Hash::Merge->new->merge(
            $rec,
            $other,
        );
        $self->generate_doc( $model_file, $record, $record->{$key0} );
    }
}

sub generate_doc {
    my ($self, $model_file, $record, $sufix) = @_;

    my $out_path = $self->_cfg->resource_path_for(undef, 'tex', 'output');
    unless ( -d $out_path ) {
        $self->_log->error('Generator: Output path not found');
        return;
    }

    my $gen = Tpda3::Generator->new();

    #-- Generate LaTeX document from template

    my $tex_file;
    my $tex_context = __ 'Failed to generate PDF';
    try {
        $tex_file = $gen->tex_from_template( $record, $model_file, $out_path );
    }
    catch {
        $self->io_exception($_, $tex_context);
    };

    unless ( $tex_file and ( -f $tex_file ) ) {
        $self->_log->error($tex_context);
        return;
    }

    #-- Generate PDF from LaTeX

    my $pdf_file;
    my $pdf_context = __ 'Failed to generate PDF';
    try {
        $pdf_file = $gen->pdf_from_latex($tex_file, undef, $sufix);
    }
    catch {
        $self->io_exception( $_, $pdf_context );
    };

    # Check output
    unless ( $pdf_file and -f $pdf_file ) {
        $self->_log->error($pdf_context);
        return;
    }

    return;
}

# use one in controller
sub io_exception {
    my ($self, $exc, $context) = @_;

    my ($message, $details);

    if ( my $e = Exception::Base->catch($exc) ) {
        if ( $e->isa('Exception::IO::PathNotFound') ) {
            $message = $context;
            $details = $e->message .' '. $e->pathname;
        }
        elsif ( $e->isa('Exception::IO::FileNotFound') ) {
            $message = $context;
            $details = $e->message .' '. $e->filename;
        }
        else {
            $self->_log->error( $e->message );
            $e->throw;    # rethrow the exception
        }

        $self->_log->error("$message: $details");
    }

    return;
}

1;
