package Tpda3::Wx::GridTable;

use strict;
use warnings;
use Carp;

use Wx;
use Wx::Grid;
use Wx qw(wxGRIDTABLE_NOTIFY_ROWS_INSERTED wxGRIDTABLE_NOTIFY_ROWS_DELETED);

use base qw(Wx::PlGridTable);

=head1 NAME

Tpda3::Wx::GridTable

=head1 VERSION

Version 0.55

=cut

our $VERSION = 0.55;

=head1 SYNOPSIS

=head1 DESCRIPTION

wxGridTableBase

Documentation from gridtablebase.h:

The almost abstract base class for grid tables.

A grid table is responsible for storing the grid data and, indirectly,
grid cell attributes. The data can be stored in the way most
convenient for the application but has to be provided in string form
to wxGrid. It is also possible to provide cells values in other
formats if appropriate, e.g. as numbers.

This base class is not quite abstract as it implements a trivial
strategy for storing the attributes by forwarding it to
wxGridCellAttrProvider and also provides stubs for some other
functions. However it does have a number of pure virtual methods which
must be implemented in the derived classes.

=cut

sub new {
   my ($class, $args) = @_;

   my $self = $class->SUPER::new();

   $self->{cols}    = scalar @{ $args->{fields} };
   $self->{coldata} = [];
   $self->{rows}    = 0;

   return $self;
}

=head2 GetNumberRows

Must be overridden to return the number of rows in the table.

=cut

sub GetNumbeerRows {
    my $self = shift;

    return $self->{rows};
}

=head2 GetNumberCols

Must be overridden to return the number of columns in the table.

=cut

sub GetNumberCols {
    my $self = shift;

    return $self->{cols};
}

=head2 IsEmptyCell

May be overridden to implement testing for empty cells.

=cut

sub IsEmptyCell {
    my ($self, $row, $col) = @_;

    return defined $self->GetValue($row, $col) ? 1 : 0;
}

=head2 GetValue

Must be overridden to implement accessing the table values as text.

=cut

sub GetValue {
    my ( $self, $row, $col ) = @_;

    my $result = undef;
    eval {
        $result = $self->{array}->[$row][$col]->GetValue
            if ( $row < $self->GetNumberRows
            && $col < $self->GetNumberCols
            && defined $self->{array}->[$row][$col] );
        $result = '' unless defined $result;
    };
    carp "Exception in DBGridTable::GetValue: $@" if $@;

    return $result;
}

=head2 SetValue

Must be overridden to implement setting the table values as text.

=cut

sub SetValue {
    my ( $self, $row, $col, $value ) = @_;

    croak "Array out of bounds"
        unless $row < $self->GetNumberRows && $col < $self->GetNumberCols;
    $self->{array}->[$row][$col]->SetValue($value);

    return;
}

=head1 Table Structure Modifiers

Notice that none of these functions are pure virtual as they don't
have to be implemented if the table structure is never modified after
creation, i.e. neither rows nor columns are never added or deleted but
that you do need to implement them if they are called, i.e. if your
code either calls them directly or uses the matching wxGrid methods,
as by default they simply do nothing which is definitely
inappropriate.

Clear the table contents.

sub Clear {

}

Insert additional rows into the table.

sub InsertRows {
    my ($pos, $numRows);
    return;
}

Append additional rows at the end of the table.

sub AppendRows {
    my (numRows);
    return;
}

Delete rows from the table.

sub DeleteRows {
    my ($pos, $numRows);
    return;
}

Exactly the same as InsertRows() but for columns.

sub InsertCols {
    my ($pos, $numCols);
}

Exactly the same as AppendRows() but for columns.

sub AppendCols {
    my ($numCols);
    return;
}

Exactly the same as DeleteRows() but for columns.

sub DeleteCols {
    my ($pos, $numCols);
}

=head1 Table Row and Column Labels

=head2 GetRowLabelValue

Return the label of the specified row.

=cut

sub GetRowLabelValue {
    my $row = shift;

    return;
}

=head2 GetColLabelValue

Return the label of the specified column.

=cut

sub GetColLabelValue {
    my $col = shift;

    return;
}

=head2 SetRowLabelValue

Set the given label for the specified row.

The default version does nothing, i.e. the label is not stored. You
must override this method in your derived class if you wish
wxGrid::SetRowLabelValue() to work.

=cut

sub SetRowLabelValue {
    my ($row, $label) = @_;

    return;
}

=head2 SetColLabelValue

Set the given label for the specified col.

The default version does nothing, i.e. the label is not stored. You
must override this method in your derived class if you wish
wxGrid::SetRowLabelValue() to work.

=cut

sub SetColLabelValue {
    my ($col, $label) = @_;

    return;
}

=head1 Attributes Management

By default the attributes management is delegated to
wxGridCellAttrProvider class. You may override the methods in this
section to handle the attributes directly if, for example, they can be
computed from the cell values.

Associate this attributes provider with the table.
SetAttrProvider(wxGridCellAttrProvider *attrProvider);

Returns the attribute provider currently being used.
GetAttrProvider

Return the attribute for the given cell.
GetAttr(int row, int col, wxGridCellAttr::wxAttrKind kind)

Set attribute of the specified cell.
SetAttr(wxGridCellAttr* attr, int row, int col);

Set attribute of the specified row.
SetRowAttr(wxGridCellAttr *attr, int row);

Set attribute of the specified column.
SetColAttr(wxGridCellAttr *attr, int col);

Returns true if this table supports attributes or false otherwise.
CanHaveAttributes();

=cut

1;
