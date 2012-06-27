package Tpda3::Tk::Tools::QSelect;

use strict;
use warnings;
use utf8;

use Tk::widgets qw(DateEntry JComboBox Table Checkbox); #

use base q{Tpda3::Tk::Screen};

use POSIX qw (strftime);
use File::Spec;

use Tpda3::Utils;
use Tpda3::Config;

=head1 NAME

Tpda3::Tk::App::Fpimm::QSelect screen.

=head1 VERSION

Version 0.55

=cut

our $VERSION = 0.55;

=head1 SYNOPSIS

    require Tpda3::App::Fpimm::QSelect;

    my $scr = Tpda3::App::Fpimm::QSelect->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 _init



=cut

sub _init {
    my ($self, ) = @_;

    $self->{cfg} = Tpda3::Config->instance();
    $self->{scr} = Tpda3::Config::Screen->new('firme');

    $self->{columns} = {};
    $self->{widgets} = [];

    return;
}

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $nb, $scrcfg ) = @_;

    $self->_init($scrcfg);

    my $rec_page  = $nb->page_widget('rec');
    my $det_page  = $nb->page_widget('det');
    $self->{view} = $nb->toplevel;
    $self->{bg}   = $self->{view}->cget('-background');

    my $locale_data  = $self->{cfg}->localize->{search};
    my $opt_contains = $locale_data->{opt_contains};
    my $opt_starts   = $locale_data->{opt_starts};
    my $opt_ends     = $locale_data->{opt_ends};

    # For DateEntry day names
    my @daynames = ();
    foreach ( 0 .. 6 ) {
        push @daynames, strftime( "%a", 0, 0, 0, 1, 1, 1, $_ );
    }

    #-  Frame TOP

    my $top = $rec_page->Frame()->pack(
        -side   => 'top',
        -fill   => 'both',
        -expand => 0,
    );

    #-- LabFrame top - left

    my $frm_tl = $top->LabFrame(
        -foreground => 'blue',
        -label      => 'Criterii',
        -labelside  => 'acrosstop'
        )->pack(
        -side   => 'left',
        -expand => 0,
        -fill   => 'both',
        );

    my $f1d = 90;              # distance from left

    $self->{columns} = $self->{scr}->main_table_columns;

    # Screen table columns metadata
    # TODO: sort field labels
    my @columns;
    my $idx = 0;
    foreach my $field ( keys %{ $self->{columns} } ) {
        $columns[$idx] = [ $field, $self->{columns}{$field}{label} ];
        $idx++;
    }

    my $rows_idx = $#columns;

    $self->{table} = $frm_tl->Table(
        -columns    => 6,
        -rows       => 6,
        #-fixedrows  => 1,
        -scrollbars => 'oe',
        -relief     => 'raised',
        -background => 'white'
    );

    #-- Fill table

    foreach my $r ( 0 .. $rows_idx ) {

        my $no = $r + 1;

        # Label - row number
        my $crt_label = $self->{table}->Label(
            -text   => $no,
            -width  => 2,
            -relief => 'raised'
        );

        # Label - field label
        my $fld_label = $self->{table}->Label(
            -text   => $columns[$r][1],
            -width  => 15,
            -relief => 'sunken',
            -anchor => 'w',
            -bg     => 'white',
        );

        # Negate - checkbox
        my $v_negate = 0;
        my $cbx_negate = $self->{table}->Checkbox(
            -variable => \$v_negate,
            -relief   => 'raised',
        );

        #
        my $selected;
        my $searchopt = $self->{table}->JComboBox(
            -entrywidth   => 10,
            -textvariable => \$selected,
            -choices      => [
                { -name => $opt_contains, -value => 'C', -selected => 1 },
                { -name => $opt_starts,   -value => 'S', },
                { -name => $opt_ends,     -value => 'E', },
                { -name => '=',           -value => '==', },
                { -name => '>',           -value => '>', },
                { -name => '>=',          -value => '>=', },
                { -name => '<',           -value => '<', },
                { -name => '<=',          -value => '<=', },
            ],
        );

        my $qry_entry = $self->{table}->Entry(
            -width    => 20,
            -relief   => 'sunken',
            -bg       => 'white',
            -validate => 'key',

            #-validatecommand=>sub{ $_[1] =~m/\d\d/} ,
            #-invalidcommand=>sub{$mw->bell}
        );

        # Enable - checkbox (read only the enabled entries)
        my $v_enable = 0;
        my $cbx_enable = $self->{table}->Checkbox(
            -variable => \$v_enable,
            -relief => 'raised',
        );

        $self->{table}->put( $r, 1, $crt_label );
        $self->{table}->put( $r, 2, $fld_label );
        $self->{table}->put( $r, 3, $cbx_negate );
        $self->{table}->put( $r, 4, $searchopt );
        $self->{table}->put( $r, 5, $qry_entry );
        $self->{table}->put( $r, 6, $cbx_enable );

        $self->{widgets}[$r] = [ $columns[$r][0], \$v_negate, \$v_enable ];
    }

    $self->{table}->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    #-- LabFrame top - right

    my $frm_tr = $top->LabFrame(
        -foreground => 'blue',
        -label      => 'Select',
        -labelside  => 'acrosstop',
        )->pack(
        -side   => 'left',
        -expand => 1,
        -fill   => 'both',
        );

    my $addB = $frm_tr->Button(
        -text => 'Query',
        -command => sub { $self->execute_query($scrcfg) },
    )->pack(-side => 'right', -padx => 12);

    #--- Details
    #-
    #

    #- Frame middle

    my $frm_m = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Records',
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

    # Entry objects: var_asoc, var_obiect
    # Other configurations in '.conf'
    $self->{controls} = {};

    #- TableMatrix objects; just one for now :)

    $self->{tm_controls} = {
        rec => {
            tm1 => \$xtable,
        },
    };

    # Prepare screen configuration data for tables
    # foreach my $tm_ds ( keys %{ $self->{tm_controls}{rec} } ) {
    #     $validation->init_cfgdata( 'deptable', $tm_ds );
    # }

    return;
}

=head2 execute_query

Execute query.

=cut

sub execute_query {
    my ($self, $scrcfg) = @_;

    my $para = $self->build_query($scrcfg);

    my ($records, $limit) = $self->{view}->tbl_find_query($para);

    my $tmx = $self->get_tm_controls('tm1');
    $tmx->clear_all();
    $tmx->fill($records);

    return;
}

=head2 build_query

Build query.

=cut

sub build_query {
    my ($self, $scrcfg) = @_;

    $self->table_entry_read();

    my $params = {};

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{ $self->{_scrdata} } ) ) {
        my $findtype = $self->{columns}{$field}{findtype};

        # Create a where clause like this:
        #  field1 IS NOT NULL and field2 IS NULL
        # for entry values equal to '%' or '!'
        $findtype = q{notnull} if defined $value and $value eq q{%};
        $findtype = q{isnull}  if !defined $value;

        $params->{where}{$field} = [ $value, $findtype ];
    }

    # Table data
    $params->{table} = $self->{scr}->main_table_view; # use view
    $params->{pkcol} = $self->{scr}->main_table_pkcol;

    return $params;
}

=head2 table_entry_read

Read user input data.

=cut

sub table_entry_read {
    my $self = shift;

    # my $col_idx = 5;
    my $rows = $self->{table}->totalRows;

    $self->{_scrdata} = {};                  # init

    for ( my $row_idx = 0; $row_idx < $rows; $row_idx++ ) {
        my $widgets = $self->{widgets}[$row_idx];

        my $field  = $widgets->[0];
        my $negate = ${ $widgets->[1] };
        my $enable = ${ $widgets->[2] };

        next unless $enable == 1;

        my $widget_entry = $self->{table}->get( $row_idx, 5 );
        my $value = $widget_entry->get;

        if ($value) {
            $self->{_scrdata}{$field} = $value;
        }
        else {

            # ctrl type is 'e'
            # Can't use numeric eq (==) here
            if ( $value =~ m{^0+$} ) {
                $self->{_scrdata}{$field} = $value;
            }
            else {
                $self->{_scrdata}{$field} = undef; # IS NULL
            }
        }
    }

    return;
}

=head1 AUTHOR

Ștefan Suciu, C<< <stefbv70 la gmail punct com> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Inspired by an answer on PerlMonks by zentara [id://969264].

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Ștefan Suciu

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::App::Fpimm::QSelect
