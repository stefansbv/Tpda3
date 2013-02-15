package Tpda3::Wx::Grid;

use strict;
use warnings;

use Wx   qw(wxSUNKEN_BORDER);
use base qw(Wx::Grid);
use Wx::Event qw(EVT_GRID_CELL_LEFT_CLICK EVT_GRID_CELL_RIGHT_CLICK
    EVT_GRID_CELL_LEFT_DCLICK EVT_GRID_CELL_RIGHT_DCLICK
    EVT_GRID_LABEL_LEFT_CLICK EVT_GRID_LABEL_RIGHT_CLICK
    EVT_GRID_LABEL_LEFT_DCLICK EVT_GRID_LABEL_RIGHT_DCLICK
    EVT_GRID_ROW_SIZE EVT_GRID_COL_SIZE EVT_GRID_RANGE_SELECT
    EVT_GRID_CELL_CHANGE EVT_GRID_SELECT_CELL);

use Tpda3::Wx::Grid::Table;

=head1 NAME

Tpda3::Wx::Grid - A subclass of Wx::Grid.

=head1 VERSION

Version 0.63

=cut

our $VERSION = 0.63;

=head1 SYNOPSIS

    use Tpda3::Wx::Grid;
    ...

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $parent, $id, $pos, $size, $style ) = @_;

    $style = wxSUNKEN_BORDER;

    my $self = $class->SUPER::new(
        $parent, $id || -1,
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

    my $table = {
        datacols => [
            { id => 0, label => 'Art',      type => 'int_id', width => 5 },
            { id => 1, label => 'Code',     type => 'string', width => 15 },
            { id => 2, label => 'Product',  type => 'string', width => 36 },
            { id => 3, label => 'Quantity', type => 'double', width => 12 },
            { id => 4, label => 'Price',    type => 'double', width => 12 },
            { id => 5, label => 'Value',    type => 'double', width => 12 },
        ],
        datarows => [
            [ 1, 'S50_1341',  '1930 Buick Marquette Phaeton', 29, 37.97, 0 ],
            [ 2, 'S700_1691', 'American Airlines: B767-300',  48, 81.29, 0 ],
            [ 3, 'S700_3167', 'F/A 18 Hornet 1/72',           38, 70.40, 0 ],
        ]
    };

    my $dt = Tpda3::Wx::Grid::Table->new($table, 1);

    $self->SetTable($dt);

    # Nu mere!
    #$self->BeginBatch();
    # $self->SetSelectionMode(wxGrid::wxGridSelectRows);
    # $self->SetDefaultColSize(50);
    # $self->SetDefaultRowSize(50);
    # $self->SetColLabelSize(25);
    # $self->SetRowLabelSize(0);
    # $self->SetColSize(0, 75);
    #$self->ForceRefresh();
    #$self->SetColMinimalWidth(0,5);
    #$self->SetColSize(1,5);
    #$self->AutoSizeRows(1);
    # foreach my $col ( @{ $table->{datacols} } ) {
    #     print " $col->{id}, $col->{width}\n";
    #     $self->SetColSize( $col->{id}, $col->{width} );
    # }
    # We can specify the some cells will store numeric values rather
    # than strings. Here we set grid column 5 to hold floating point
    # values displayed with width of 6 and precision of 2
    # $self->SetColFormatFloat(5, 6, 2);
    #$self->EndBatch();

    return $self;
}

1;
