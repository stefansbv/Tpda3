package Tpda3::Wx::Grid;

use strict;
use warnings;
use Carp;

use Data::Printer;

use Wx qw(wxSUNKEN_BORDER wxALIGN_LEFT wxALIGN_RIGHT wxALIGN_CENTRE
    wxFONTFAMILY_DEFAULT wxFONTSTYLE_NORMAL wxFONTWEIGHT_NORMAL
    wxFONTWEIGHT_LIGHT wxFONTWEIGHT_BOLD);
use Wx::Event qw(EVT_GRID_CELL_LEFT_CLICK EVT_GRID_CELL_RIGHT_CLICK
    EVT_GRID_CELL_LEFT_DCLICK EVT_GRID_CELL_RIGHT_DCLICK
    EVT_GRID_LABEL_LEFT_CLICK EVT_GRID_LABEL_RIGHT_CLICK
    EVT_GRID_LABEL_LEFT_DCLICK EVT_GRID_LABEL_RIGHT_DCLICK
    EVT_GRID_ROW_SIZE EVT_GRID_COL_SIZE EVT_GRID_RANGE_SELECT
    EVT_GRID_CELL_CHANGING EVT_GRID_SELECT_CELL);

use base qw(Wx::Grid);

use Tpda3::Wx::Grid::Table;
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

Version 0.67

=cut

our $VERSION = 0.67;

=head1 SYNOPSIS

    use Tpda3::Wx::Grid;
    ...

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $parent, $id, $pos, $size, $style, $columns ) = @_;

    $style = wxSUNKEN_BORDER;

    my $self = $class->SUPER::new(
        $parent,
        $id   || -1,
        $pos  || [ -1, -1 ],
        $size || [ -1, -1 ],
        #( $style || 0 ),
    );

    $self->SetRowLabelSize(0);
    $self->DisableDragRowSize();
    $self->AutoSize();

    $self->SetColLabelAlignment(wxALIGN_CENTRE, wxALIGN_CENTRE);
    $self->SetDefaultCellAlignment(wxALIGN_LEFT, wxALIGN_CENTRE);

    #-- Transforma data

    my $table = {};

    my $columns_sorted = Tpda3::Utils->sort_hash_by_id($columns);
    foreach my $col ( @{$columns_sorted} ) {
        my $rec = {
            id    => $columns->{$col}{id},
            label => $columns->{$col}{label},
            type  => $self->get_type( $columns->{$col}{datatype} ),
            width => $columns->{$col}{displ_width},
        };

        push @{ $table->{datacols} }, $rec;
    }

    $table->{datarows} = [
        # [ undef, undef, undef, undef, undef, 0 ],
        # [ 1, 'S50_1341',  '1930 Buick Marquette Phaeton', 29, 37.97, 0 ],
        # [ 2, 'S700_1691', 'American Airlines: B767-300',  48, 81.29, 0 ],
        # [ 3, 'S700_3167', 'F/A 18 Hornet 1/72',           38, 70.40, 0 ],
    ];

    # my $table = {
    #     datacols => [
    #         { id => 0, label => 'Art',      type => 'int_id', width => 5 },
    #         { id => 1, label => 'Code',     type => 'string', width => 15 },
    #         { id => 2, label => 'Product',  type => 'string', width => 36 },
    #         { id => 3, label => 'Quantity', type => 'double', width => 12 },
    #         { id => 4, label => 'Price',    type => 'double', width => 12 },
    #         { id => 5, label => 'Value',    type => 'double', width => 12 },
    #     ],
    #     datarows => [
    #         [ 1, 'S50_1341',  '1930 Buick Marquette Phaeton', 29, 37.97, 0 ],
    #         [ 2, 'S700_1691', 'American Airlines: B767-300',  48, 81.29, 0 ],
    #         [ 3, 'S700_3167', 'F/A 18 Hornet 1/72',           38, 70.40, 0 ],
    #     ]
    # };

    $self->{grid} = Tpda3::Wx::Grid::Table->new($table, $self);

    $self->SetTable($self->{grid}, 1);

    # $self->SetMargins(25, 25); ???
    my $label_font
        = Wx::Font->new( 8, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL,
        wxFONTWEIGHT_NORMAL );
    $self->SetLabelFont($label_font);
    $self->SetColLabelSize(20);              # height
    #$self->SetSelectionMode(Wx::wxGridSelectRows);

    # Set column width
    my $char_width = $self->GetCharWidth();
    foreach my $col ( @{ $table->{datacols} } ) {
        $self->SetColSize( $col->{id}, $char_width * $col->{width} );
    }

    # No visible change with this :(
    # $self->BeginBatch();
    # We can specify the some cells will store numeric values rather
    # than strings. Here we set grid column 5 to hold floating point
    # values displayed with width of 6 and precision of 2
    # $self->SetColFormatNumber(0);
    $self->SetColFormatFloat(3, -1, 2);
    # $self->SetColFormatFloat(4, 6, 2);
    # $self->SetColFormatFloat(5, 6, 2);
    # $self->EndBatch();

    # foreach my $pos (0..1) {
    #     $self->{grid}->InsertRows($pos, 1);
    #     my @data = ( $pos+1, 'S50_1341', '1930 Buick Marquette Phaeton', 29, 37.97, 0 );
    #     for (my $col = 0; $col <= $#data; $col++) {
    #         print "$col: $data[$col]\n";
    #         $self->{grid}->SetValue($pos, $col, $data[$col]);
    #     }
    # }

    return $self;
}

sub get_type {
    my ($self, $type) = @_;

    return $translation_table{$type};
}

=head2 init

Write header on row 0 of TableMatrix.

=cut

sub init {
    my ( $self, $frame, $args ) = @_;

    # Screen configs
    foreach my $key (keys %{$args}) {
        $self->{$key} = $args->{$key};
    }

    # Other
    $self->{frame}  = $frame;
    $self->{tm_sel} = undef;    # selected row

    return;
}

=head2 set_tags

Define and set tags for the Table Matrix.

=cut

sub set_tags {
    my $self = shift;

    my $cols = scalar keys %{ $self->{columns} };

    # # TableMatrix header, Set Name, Align, Width
    # foreach my $field ( keys %{ $self->{columns} } ) {
    #     my $col = $self->{columns}{$field}{id};
    #     $self->tagCol( $self->{columns}{$field}{tag}, $col );
    #     $self->set( "0,$col", $self->{columns}{$field}{label} );

    #     # If colstretch = 'n' in screen config file, don't set width,
    #     # because of the -colstretchmode => 'unset' setting, col 'n'
    #     # will be of variable width
    #     next if $self->{colstretch} and $col == $self->{colstretch};

    #     my $width = $self->{columns}{$field}{displ_width};
    #     if ( $width and ( $width > 0 ) ) {
    #         $self->colWidth( $col, $width );
    #     }
    # }

    # # Add selector column
    # if ( $self->{selectorcol} ) {
    #     my $selecol = $self->{selectorcol};
    #     $self->insertCols( $selecol, 1 );
    #     $self->tagCol( 'ro_center', $selecol );
    #     $self->colWidth( $selecol, 3 );
    #     $self->set( "0,$selecol", 'Sel' );
    # }

    # $self->tagRow( 'title', 0 );
    # if ( $self->tagExists('expnd') ) {

    #     # Change the tag priority
    #     $self->tagRaise( 'expnd', 'title' );
    # }

    return;
}

sub get_num_rows {
    my $self = shift;
    return $self->{grid}->GetNumberRows;
}

sub clear_all {
    my $self = shift;

    my $rows = $self->{grid}->GetNumberRows;
    if ( $rows > 0 ) {
        warn "rows not deleted"
            unless $self->{grid}->DeleteRows( 0, $rows );
    }

    $self->ForceRefresh;

    return;
}

sub data_read {
    my $self = shift;

    # Have to change the structure of the data to be returned
    return; #$self->{grid}->get_data_all;
}

sub get_selected {
    my ($self, ) = @_;
    return;
}

sub set_selected {
    my ($self, ) = @_;
    return;
}

=head2 fill

Fill the Grid with data.

=cut

sub fill {
    my ( $self, $record_ref ) = @_;

    foreach my $row_record ( @{$record_ref} ) {
        $self->append_rows( $row_record );
    }

    return;
}

=head2 append_rows

Transform data from HoH to AoA and call GridTable->AppendRows.

=cut

sub append_rows {
    my ($self, $row_record) = @_;

    my $row = $self->get_num_rows;

    my @record;
    my $fields = Tpda3::Utils->sort_hash_by_id( $self->{columns} );
    foreach my $field ( @{$fields} ) {
        push @record, $row_record->{$field};
    }

    croak "row not appended"
        unless $self->{grid}->AppendRows( $row, 1, \@record );

    $self->ForceRefresh;

    return;
}

1;
