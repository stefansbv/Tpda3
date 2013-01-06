package Tpda3::Wx::Grid;

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

use Tpda3::Wx::GridTable;

=head1 NAME

Tpda3::Wx::Grid - A subclass of Wx::Grid.

=head1 VERSION

Version 0.62

=cut

our $VERSION = 0.62;

=head1 SYNOPSIS

    use Tpda3::Wx::Grid;
    ...

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $parent, $id, $pos, $size, $style ) = @_;

    my $self = $class->SUPER::new(
        $parent, $id || -1,
        $pos  || [ -1, -1 ],
        $size || [ -1, -1 ],
        ( $style || 0 )
    );

    my $datatable
        = Tpda3::Wx::GridTable->new( { fields => [qw(col1 col2 col3)] } );

    $self->SetTable($datatable);

    return $self;
}

1;
