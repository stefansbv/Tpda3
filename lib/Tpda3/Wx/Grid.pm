package Tpda3::Wx::Grid;

use strict;
use warnings;
use Carp;

use Wx qw(wxSUNKEN_BORDER wxALIGN_LEFT wxALIGN_RIGHT wxALIGN_CENTRE
    wxFONTFAMILY_DEFAULT wxFONTSTYLE_NORMAL wxFONTWEIGHT_NORMAL
    wxFONTWEIGHT_LIGHT wxFONTWEIGHT_BOLD WXK_RETURN
    wxGridSelectRows wxGridSelectColumns
    wxGREEN wxRED);

use Wx::Event qw(EVT_GRID_RANGE_SELECT EVT_KEY_DOWN);

use base qw(Wx::Grid);

use Tpda3::Wx::Grid::Table;
use Tpda3::Wx::Grid::DataTable;
require Tpda3::Utils;

my %translation_table = (
    integer      => 'integer',
    alpha        => 'string',
    alphanum     => 'string',
    alphanumplus => 'string',
    numeric      => 'double',
);

=head1 NAME

Tpda3::Wx::Grid - A subclass of Wx::Grid.

=head1 VERSION

Version 0.89

=cut

our $VERSION = 0.89;

=head1 SYNOPSIS

    use Tpda3::Wx::Grid;
    ...

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $parent, $columns ) = @_;

    my $self = $class->SUPER::new(
        $parent,
        -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxSUNKEN_BORDER,
    );

    $self->init_datatable($columns);

    $self->{table} = Tpda3::Wx::Grid::Table->new($self->{gdt}, $self);
    $self->SetTable($self->{table}, 1);

    $self->SetColLabelSize(20);    # height
    $self->SetRowLabelSize(0);     # comment for ver < 2.9 and use the
                                   # label to select rows
    $self->SetColLabelAlignment(wxALIGN_CENTRE, wxALIGN_CENTRE);
    $self->SetDefaultCellAlignment(wxALIGN_LEFT, wxALIGN_CENTRE);
    $self->DisableDragRowSize();
    $self->SetSelectionMode(wxGridSelectRows);

    my $label_font
        = Wx::Font->new( 8, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL,
        wxFONTWEIGHT_NORMAL );
    $self->SetLabelFont($label_font);

    # Set column width
    my $char_width = $self->GetCharWidth();
    my $cols_idx = $self->{gdt}->get_col_num - 1;
    foreach my $col ( 0..$cols_idx ) {
        my $id    = $self->{gdt}->get_col_attrib($col, 'id');
        my $width = $self->{gdt}->get_col_attrib($col, 'displ_width');
        $self->SetColSize( $id, $char_width * $width );
    }

    # One row at a time to be selected.  Should also deselect the
    # others but the last (not implemented).
    EVT_GRID_RANGE_SELECT $self, sub {
        my @sel = $_[0]->GetSelectedRows();
        my $sel = $sel[-1];                  # keep last selected
        $self->{gdt}->set_selection($sel) if defined $sel;
        $_[1]->Skip;
    };

    # Advance to the next cell to the right on ENTER
    EVT_KEY_DOWN $self, sub {
        $_[0]->on_key_down($_[1]);
    };

    return $self;
}

=head2 on_key_down

Adapted from:
https://github.com/wxWidgets/wxPython/blob/master/demo/GridEnterHandler.py

=cut

sub on_key_down {
    my ( $self, $evt ) = @_;

    if ( $evt->GetKeyCode() != WXK_RETURN ) {
        $evt->Skip();
        return;
    }

    if ( $evt->ControlDown() ) {    # the edit control needs this key
        $evt->Skip();
        return;
    }

    #$self->DisableCellEditControl(); ???

    my $success = $self->MoveCursorRight( $evt->ShiftDown() );
    unless ($success) {
        my $newRow = $self->GetGridCursorRow() + 1;
        print "New row $newRow\n";
        if ( $newRow < $self->get_num_rows() ) {
            $self->SetGridCursor( $newRow, 0 );
            $self->MakeCellVisible( $newRow, 0 );
        }
        else {
            print "Add row\n";
            # this would be a good place to add a new row if your app
            # needs to do that
        }
    }

    return;
}

sub init_datatable {
    my ($self, $columns) = @_;

    #-- Prepare column data

    $self->{gdt} = Tpda3::Wx::Grid::DataTable->new();

    my $table = {};

    my $columns_sorted = Tpda3::Utils->sort_hash_by_id($columns);

    my $col = 0;
    foreach my $field ( @{$columns_sorted} ) {
        my $col_attr_ref = {
            id          => $columns->{$field}{id},
            field       => $field,
            label       => $columns->{$field}{label},
            type        => $self->get_type( $columns->{$field}{datatype} ),
            displ_width => $columns->{$field}{displ_width},
            valid_width => $columns->{$field}{valid_width},
            numscale    => $columns->{$field}{numscale},
            readwrite   => $columns->{$field}{readwrite},
            tag         => $columns->{$field}{tag},
        };
        $self->{gdt}->set_col_attribs( $col, $col_attr_ref );
        $col++;
    }

    return;
}

sub get_type {
    my ($self, $type) = @_;

    return $translation_table{$type};
}

sub get_num_rows {
    my $self = shift;
    return $self->{table}->GetNumberRows;
}

sub get_num_cols {
    my $self = shift;
    return $self->{table}->GetNumberCols;
}

sub clear_all {
    my $self = shift;

    my $rows_no = $self->get_num_rows;

    return if $rows_no <= 0;

    foreach my $idx (reverse 1..$rows_no) {
        my $item = $idx - 1;
        $self->delete_row($item);
    }

    $self->ForceRefresh;

    return;
}

sub get_selected {
    my ( $self, ) = @_;
    return;
}

sub set_selected {
    my ( $self, ) = @_;
    return;
}

=head2 fill

Fill the Grid with data.

=cut

sub fill {
    my ( $self, $record_ref ) = @_;

    my $row = 0;
    foreach my $rec ( @{$record_ref} ) {
        my $col = 0;
        foreach my $col_ref ( @{ $self->{gdt}{datacols} } ) {
            my $field = $col_ref->{field};
            my $value = $rec->{$field};
            #print "$field: $value\n";
            $self->{gdt}->set_row_value( $row, $col, $value );
            $col++;
        }
        $self->{table}->AppendRows($row, 1);
        $row++;
    }

    return;
}

=head2 data_read

Read data from widget.

The C<selectorcol> functionality is not implemented.

=cut

sub data_read {
    my $self = shift;

    my $cols_no  = $self->get_num_cols;
    my $cols_idx = $cols_no - 1;

    # Read table data and create an AoH
    my @tabledata;

    my $data = $self->{gdt}->get_row_data;

    foreach my $row (@$data) {
        my $rowdata = {};
        for my $col ( 0 .. $cols_idx ) {
            my $cell_value = $row->[$col];
            my $col_name   = $self->{gdt}{datacols}[$col]{field};
            my $readwrite  = $self->{gdt}{datacols}[$col]{readwrite};

            next if $readwrite eq 'ro';    # skip ro cols

            $rowdata->{$col_name} = $cell_value;
        }

        push @tabledata, $rowdata;
    }

    return ( \@tabledata, undef ); # $sc
}

sub delete_row {
    my ($self, $item) = @_;

    return unless defined $item and $item >= 0;

    my $data = $self->{gdt}->get_row_data();
    splice @{$data}, $item, 1;
    $self->{table}->DeleteRows( $item, 1 );

    return 1;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

Many!

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGMENTS

=head1 LICENSE AND COPYRIGHT

Copyright Stefan Suciu, 2013-2014

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::Grid
