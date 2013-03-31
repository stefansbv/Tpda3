package Tpda3::Wx::Grid;

use strict;
use warnings;

use Wx   qw(wxSUNKEN_BORDER);
use Wx::Event qw(EVT_GRID_CELL_LEFT_CLICK EVT_GRID_CELL_RIGHT_CLICK
    EVT_GRID_CELL_LEFT_DCLICK EVT_GRID_CELL_RIGHT_DCLICK
    EVT_GRID_LABEL_LEFT_CLICK EVT_GRID_LABEL_RIGHT_CLICK
    EVT_GRID_LABEL_LEFT_DCLICK EVT_GRID_LABEL_RIGHT_DCLICK
    EVT_GRID_ROW_SIZE EVT_GRID_COL_SIZE EVT_GRID_RANGE_SELECT
    EVT_GRID_CELL_CHANGE EVT_GRID_SELECT_CELL);

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

Version 0.65

=cut

our $VERSION = 0.65;

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
        ( $style || 0 ),
    );

    $self->SetRowLabelSize(0);
    $self->DisableDragRowSize();
    $self->AutoSize();

    # $self->SetRowLabelAlignment(wxALIGN_RIGHT, wxALIGN_CENTRE);
    # $self->SetColLabelAlignment(wxALIGN_LEFT,  wxALIGN_CENTRE);
    # $self->SetDefaultCellAlignment(wxALIGN_LEFT,  wxALIGN_CENTRE);

    # $table->{datacols}->[0]{type}  = 'string';
    # $table->{datacols}->[0]{label} = 'Art';
    # ...
    # $table->{datarows}->[0][0] = 'r1al1';
    # ...

    #-- Transforma data

    use Data::Printer;

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

    my $dt = Tpda3::Wx::Grid::Table->new($table, $self);

    $self->SetTable($dt, 1);

    $self->SetColLabelSize(20);              # height

    # Set column width
    my $char_width = $self->GetCharWidth() - 1;
    foreach my $col ( @{ $table->{datacols} } ) {
        $self->SetColSize( $col->{id}, $char_width * $col->{width} );
    }

    # Nu mere!?
    #$self->BeginBatch();
    #$self->SetSelectionMode(wxGrid::wxGridSelectRows);
    #$self->ForceRefresh();

    # We can specify the some cells will store numeric values rather
    # than strings. Here we set grid column 5 to hold floating point
    # values displayed with width of 6 and precision of 2
    #$self->SetColFormatFloat(4, 6, 2);
    #$self->SetColFormatFloat(5, 6, 2);
    #$self->EndBatch();

    foreach my $pos (0..1) {
        $dt->InsertRows($pos, 1);
        my @data = ( $pos+1, 'S50_1341', '1930 Buick Marquette Phaeton', 29, 37.97, 0 );
        for (my $col = 0; $col <= $#data; $col++) {
            print "$col: $data[$col]\n";
            $dt->SetValue($pos, $col, $data[$col]);
        }
    }

    # $self->ForceRefresh();

    my $r =  $dt->GetNumberRows();
    print " R1: $r\n";

    my $val = $dt->GetValue(1,1);
    print "val (1,1) is  $val\n";
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

    # use Data::Printer; p $self->{columns};
    # $self->set_tags();

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

1;
