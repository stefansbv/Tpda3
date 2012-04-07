package Tpda3::Wx::Table;

use strict;
use warnings;

use Wx qw(wxRED wxBLUE wxGREEN);
use base qw(Wx::Grid);
use Wx::Event qw(EVT_GRID_CELL_LEFT_CLICK EVT_GRID_CELL_RIGHT_CLICK
    EVT_GRID_CELL_LEFT_DCLICK EVT_GRID_CELL_RIGHT_DCLICK
    EVT_GRID_LABEL_LEFT_CLICK EVT_GRID_LABEL_RIGHT_CLICK
    EVT_GRID_LABEL_LEFT_DCLICK EVT_GRID_LABEL_RIGHT_DCLICK
    EVT_GRID_ROW_SIZE EVT_GRID_COL_SIZE EVT_GRID_RANGE_SELECT
    EVT_GRID_CELL_CHANGE EVT_GRID_SELECT_CELL);

=head1 NAME

Tpda3::Wx::Table - A subclass of Wx::Grid.

=head1 VERSION

Version 0.49

=cut

our $VERSION = 0.49;

=head1 SYNOPSIS

    use Tpda3::Wx::Table;
    ...

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $parent, $id, $pos, $size, $style ) = @_;

    my $self = $class->SUPER::new(
        $parent,
        $id || -1,
        # $pos  || [ -1, -1 ],
        # $size || [ -1, -1 ],
        # ( $style || 0 )
    );

    $self->CreateGrid( 7, 3 );

    my $attr1 = Wx::GridCellAttr->new;
    $attr1->SetBackgroundColour( wxRED );
    my $attr2 = Wx::GridCellAttr->new;
    $attr2->SetTextColour( wxGREEN );

    $self->SetColAttr( 2, $attr1 );
    $self->SetRowAttr( 3, $attr2 );

    $self->SetCellValue( 1, 1, "First" );
    $self->SetCellValue( 2, 2, "Second" );
    $self->SetCellValue( 3, 3, "Third" );
    $self->SetCellValue( 3, 1, "I'm green" );
    $self->SetCellValue( 5, 1, "I will overflow because the cells to my right are empty.");
    $self->SetCellValue( 6, 1, "I can stop overflow on an individual cell basis..");
    $self->SetCellOverflow(6,1,0);

    return $self;
}

sub show_selections {
    my $self = shift;

    my @cells = $self->GetSelectedCells;
}

sub tags { [ 'controls/grid'  => 'wxGrid' ] }
sub add_to_tags { 'controls/grid' }
sub title { 'Simple' }


1;
