package Tpda3::Tk::Tools::TemplDet;

# ABSTRACT: Templates meta data editing details screen

use strict;
use warnings;
use utf8;

use Tk::widgets qw(DateEntry);
use POSIX qw (strftime);
use File::Spec::Functions;
use List::Compare;
use List::MoreUtils qw(any);
#use Locale::TextDomain 1.20 qw(Tpda3); # has problems on page change

use base q{Tpda3::Tk::Screen};

use Tpda3::Generator;

sub _init {
    my ($self) = @_;

    $self->{_cfg} = Tpda3::Config->instance;
    $self->{_sc}  = $self->{scrcfg}->dep_table_has_selectorcol('tm2');

    return;
}

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

sub model {
    my $self = shift;
    return $self->{model};
}

sub run_screen {
    my ( $self, $nb ) = @_;

    $self->_init();

    my $rec_page   = $nb->page_widget('rec');
    my $det_page   = $nb->page_widget('det');
    $self->{view}  = $nb->toplevel;
    $self->{model} = $self->{view}{_model};
    $self->{bg}    = $self->{view}->cget('-background');

    my $validation
        = Tpda3::Tk::Validation->new( $self->{scrcfg}, $self->{view} );

    my $date_format = $self->{scrcfg}->app_dateformat();

    # For DateEntry day names
    my @daynames = ();
    foreach ( 0..6 ) {
        push @daynames, strftime( "%a", 0, 0, 0, 1, 1, 1, $_ );
    }

    #-  Top frame

    my $frm_top = $det_page->LabFrame(
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
        -padbottom => 5,
    );
    $ett_file->bind(
        '<KeyPress-Return>' => sub {
            $self->template_file();
        }
    );

    #-- Middle frame

    my $frm_mid = $det_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Statistics',
        -labelside  => 'acrosstop',
    )->pack(
        -expand => 0,
        -fill   => 'both',
        -ipady  => 5,
    );

    #-- Required

    $frm_mid->Label(
        -text   => 'Required',
        -anchor => 'w',
    )->grid(
        -row    => 0,
        -column => 0,
        -sticky => 'e',
        -padx   => 3,
    );

    $self->{req_fields_no} = $frm_mid->Label(
        -text   => '0',
        -width  => 3,
        -relief => 'ridge',
        -anchor => 'e',
        -fg     => 'blue',
    )->grid(
        -row    => 0,
        -column => 1,
    );

    $frm_mid->Label(
        -text   => 'of',
    )->Tk::grid(
        -row    => 0,
        -column => 2,
        -ipadx  => 3,
    );

    $self->{tot_fields_no} = $frm_mid->Label(
        -text   => '0',
        -width  => 3,
        -relief => 'ridge',
        -anchor => 'e',
        -fg     => 'blue',
    )->grid(
        -row    => 0,
        -column => 3,
    );

    #---
    #- Tabel (TM)
    #---

    my $frm_t = $det_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Template variables',
        -labelside  => 'acrosstop'
    )->pack(
        -expand => 1,
        -fill   => 'both'
    );

    #-- Toolbar
    $self->make_toolbar_for_table('tm2', $frm_t);

    #- TableMatrix

    my $header = $self->{scrcfg}->dep_table_header_info('tm2');
    my $xtvar = {};

    my $xtable = $frm_t->Scrolled(
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
        -bg             => 'white',
        -scrollbars     => 'osw',
        -vcmd           => sub { $self->update_statistics() },
    );
    $xtable->pack( -expand => 1, -fill => 'both' );

    # Tags
    $xtable->tagConfigure( 'ro_center_del', -fg => 'red', );
    $xtable->tagConfigure( 'ro_center_new', -fg => 'orange', );
    $xtable->tagConfigure( 'ro_center_rec', -fg => 'green', );

    $xtable->init($frm_t, $header);
    $xtable->clear_all;

    #--  begin TableMatrix objects

    $self->{tm_controls} = { tm2 => \$xtable };

    # Prepare screen configuration data for tables
    foreach my $tm_ds ( keys %{ $self->{tm_controls} } ) {
        $validation->init_cfgdata( 'deptable', $tm_ds );
    }

    # This makes TableMatrix expand
    $xtable->update;

    #--  end Table Matrix

    # Entry objects: var_asoc, var_obiect
    # Other configurations in '.conf'
    $self->{controls} = {
        id_tt   => [ undef, $eid_tt ],
        tt_file => [ undef, $ett_file ],
    };

    $self->{tmx} = $self->get_tm_controls('tm2');

    return;
}

sub update_labels {
    my ($self, $name, $value) = @_;
    $self->{$name}->configure(-text => $value) if defined $value;
    return;
}

sub update_statistics {
    my $self = shift;

    my $req_fields_no = $self->{tmx}->count_is_checked($self->{_sc});
    my $tot_fields_no = $self->{tmx}->get_row_count();

    $self->update_labels( 'req_fields_no', $req_fields_no);
    $self->update_labels( 'tot_fields_no', $tot_fields_no);

    return;
}

sub update_column_required {
    my $self = shift;

    my $rows_idx = $self->{tmx}->get_row_count();
    my $db_data  = $self->read_db_table;
    my %arts = map { $_->{id_art} => $_->{required} } @{$db_data};
    for my $r ( 1..$rows_idx ) {
            my $id_art = $self->{tmx}->cell_read( $r, 0 )->{id_art};
            $self->{tmx}->toggle_ckbutton( $r, $self->{_sc}, $arts{$id_art} );
    }

    return;
}

sub list_of_variables {
    my $self = shift;

    my $tt_file = $self->{controls}{tt_file}[1]->get;

    # Model file name
    my $model_file
        = catfile( $self->cfg->configdir, 'tex', 'model', $tt_file );
    unless ( -f $model_file ) {
        die "Template file not found: $model_file\n";
        return;
    }

    my $gen = Tpda3::Generator->new();
    my $fields_aref = $gen->extract_tt_fields($model_file);
    return $fields_aref;
}

sub on_record_loaded {
    my $self = shift;
    $self->update_column_required;
    $self->update_statistics;
    return;
}

sub read_db_table {
    my $self = shift;

    my $id_tt = $self->{controls}{id_tt}[1]->get;

    # From table
    my $args = {};
    $args->{table}    = 'templates_req';
    $args->{colslist} = [qw{id_art required}];
    $args->{where}    = {id_tt => $id_tt};
    $args->{order}    = 'var_name';
    my $db_data = $self->model->table_batch_query($args);

    return $db_data;
}

sub read_table_widget {
    my ($self, $with_sel_name) = @_;
    my ($data) = $self->{tmx}->data_read($with_sel_name);
    return $data;
}

sub get_data_diff {
    my $self = shift;

    my $tt_data = $self->list_of_variables;
    my $tw_data = $self->read_table_widget;
    my @tw_fields = map { $_->{var_name} } @{$tw_data};
    my $lc = List::Compare->new( $tt_data, \@tw_fields );
    my @to_insert = map { { var_name => $_ } } $lc->get_unique;
    my @to_delete = map { { var_name => $_ } } $lc->get_complement;

    return (\@to_delete, \@to_insert);
}

sub update_table_widget {
    my $self = shift;

    my ($to_delete, $to_insert ) = $self->get_data_diff();

    # To delete
    my $rows_idx = $self->{tmx}->get_row_count();
    for my $r ( 1..$rows_idx ) {
        my $field = $self->{tmx}->cell_read( $r, 1 )->{var_name};
        if ( any { $field eq $_->{var_name} } @{ $to_delete } ) {
            $self->set_row_status($r, 'del');
        }
    }

    # To insert
    foreach my $row ( @{$to_insert} ) {
        my $r = $self->{tmx}->add_row;
        $self->{tmx}->cell_write($r, 'var_name', $row->{var_name} );
        $self->set_row_status($r, 'new');
    }

    $self->update_statistics;

    return;
}

sub save_table_widget {
    my $self = shift;

    # Table metadata
    my $table = 'templates_req';
    my $id_tt = $self->{controls}{id_tt}[1]->get;

    # Add the id_tt field
    my $records = $self->read_table_widget('required');
    my (@to_updins, @to_delete);
    foreach my $rec ( @{$records} ) {
        $rec->{id_tt} = $id_tt;
        if ( $rec->{state} and $rec->{state} eq 'del' ) {
            push @to_delete, @$rec{qw(id_art)};
        }
        else {
            push @to_updins, $rec;
        }
    }

    # Delete
    my $where  = {
        id_tt  => $id_tt,
        id_art => { -in => \@to_delete },
    };
    $self->model->table_record_delete( $table, $where );

    # Update or Insert
    my @columns  = (qw{id_tt id_art var_name required});
    my @matching = (qw{var_name});
    $self->model->update_or_insert( $table, \@columns, \@matching,
        \@to_updins );

    return;
}

sub set_row_status {
    my ($self, $r, $cell_text) = @_;

    $self->{tmx}->cell_write($r, 'state', $cell_text);
    if ( $cell_text =~ m{succes|ignorat} ) {
        $self->{tmx}->toggle_ckbutton($r, $self->{_sc}, 0);
    }

    my $tag_name = 'ro_center_rec';
    $tag_name = 'ro_center_del' if $cell_text eq 'del';
    $tag_name = 'ro_center_new' if $cell_text eq 'new';

    $self->{tmx}->tagCell($tag_name, "$r,2");

    return;
}

1;

=head1 SYNOPSIS

    require Tpda3::Tk::Tools::TemplDet;

    my $scr = Tpda3::Tk::Tools::TemplDet->new;

    $scr->run_screen($args);

=head2 _init

Initializations.

=head2 cfg

Return configuration instance object.

=head2 model

Return model instance object.

=head2 run_screen

The screen layout.

=head2 update_labels

Update the labels text in the screen.

=head2 update_statistics

Update the statistics labels text in the screen.

=head2 update_column_required

Update column required.

=head2 list_of_variables

Return the list of variables from the TT template document.

=head2 on_record_loaded

Update on load event.

=head2 read_db_table

Return the table data.

=head2 read_table_widget

Fetch and return the TM widget data.  Include the L<selectorcol> as
L<$with_sel_name>.

=head2 get_data_diff

Diference between databse template file and table widget.

=head2 update_table_widget

Update the table widget.

=head2 save_table_widget

Save the data from the table widget.

=head2 set_row_status

Update the status field of the row.

=cut
