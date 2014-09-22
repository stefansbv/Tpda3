package Tpda3::Wx::Grid::Table;

# ABSTRACT: Grid table implementation

use strict;
use warnings;
use Carp;

use Wx::Grid;
use Wx qw(wxALIGN_LEFT wxALIGN_CENTRE wxALIGN_RIGHT
          wxALIGN_TOP wxALIGN_CENTRE wxALIGN_BOTTOM
          wxGRIDTABLE_NOTIFY_ROWS_INSERTED wxGRIDTABLE_NOTIFY_ROWS_DELETED);

use base qw(Wx::PlGridTable);

my %default = (
    integer => 0,
    string  => q{},
    double  => 0.00,
);

sub new {
    my ( $class, $gdt, $grid ) = @_;

    my $self = $class->SUPER::new();

    $self->{view} = $grid;
    $self->{gdt}  = $gdt;

    return $self;
}

sub GetView {
    my $self = shift;

    return $self->{view};
}

sub GetNumberRows {
    my $self = shift;

    return $self->{gdt}->get_row_num;
}

sub GetNumberCols {
    my $self = shift;

    return $self->{gdt}->get_col_num;
}

sub IsEmptyCell {
    my ( $self, $row, $col ) = @_;

    return ( defined( $self->{gdt}->get_row_value($row, $col) ) )
        ? 0
        : 1;
}

sub GetValue {
    my ( $self, $row, $col ) = @_;

    my $result = undef;
    eval {
        $result = $self->{gdt}->get_row_value($row, $col)
            if  $row < $self->GetNumberRows
            and $col < $self->GetNumberCols
            and defined $self->{gdt}->get_row_value($row, $col);
    };
    croak "Exception in Grid::Table::GetValue: $@" if $@;
    my $type = $self->GetTypeName(0, $col);
    $result = $default{$type} unless defined $result;

    return $result;
}

sub get_data_all {
    my $self = shift;

    return $self->{gdt}->get_row_data;
}

sub SetValue {
    my ( $self, $row, $col, $value ) = @_;

    croak "row overflow" if $row > $self->GetNumberRows;
    croak "col overflow" if $col > $self->GetNumberCols;

    my $type = $self->GetTypeName(0, $col);
    $value = $default{$type} unless defined $value;

    print "M: $row, $col, [$value]\n";
    $self->{gdt}->set_row_value($row, $col, $value);

    return;
}

sub GetTypeName {
    my($self, $row, $col) = @_;
    return  $self->{gdt}->get_col_attrib($col,'type');
}

sub CanGetValueAs {
    my($self, $row, $col) = @_;
    return  $self->{gdt}->get_col_attrib($col,'type');
}

sub CanSetValueAs {
    my($self, $row, $col) = @_;
    return  $self->{gdt}->get_col_attrib($col,'type');
}

sub GetValueAsLong { shift->GetValue( @_ ); }

sub GetValueAsDouble { shift->GetValue( @_ ); }

sub GetValueAsBool { shift->GetValue( @_ ); }

sub SetValueAsLong { shift->SetValue( @_ ); }

sub SetValueAsDouble { shift->SetValue( @_ ); }

sub SetValueAsBool { shift->SetValue( @_ ); }

###

sub InsertRows {
    my ( $self, $pos, $rows ) = @_;
    return 0;
}

sub AppendRows {
    my ( $self, $pos, $rows ) = @_;

    $rows = 1 unless defined $rows && $rows >= 0;

    return 0 if $rows == 0;

    # Notify the Grid about the insert
    eval {
        if ( my $grid = $self->GetView() ) {
            my $msg
                = Wx::GridTableMessage->new( $self,
                wxGRIDTABLE_NOTIFY_ROWS_INSERTED,
                $pos, $rows );
            $grid->ProcessTableMessage($msg);
        }
        else {
            croak "No Grid!\n";
        }
    };
    if ($@) {
        croak "Grid::Table::AppendRows Exception: $@";
        return 0;
    }

    return 1;
}

sub DeleteRows {
    my ( $self, $pos, $rows ) = @_;

    $rows = 1 unless defined $rows && $rows >= 0;

    return 0 if $rows == 0;

    print " DeleteRows: pos=$pos rows=$rows\n";

    my $data = $self->get_data_all;
    splice @{$data}, $pos, $rows;            # why does this work ???

    eval {
        if ( my $grid = $self->GetView() ) {
            my $msg
                = Wx::GridTableMessage->new( $self,
                wxGRIDTABLE_NOTIFY_ROWS_DELETED,
                $pos, $rows );
            $grid->ProcessTableMessage($msg);
        }
        else {
            croak "No Grid!\n";
        }
    };
    if ($@) {
        croak "Grid::Table::DeleteRows Exception: $@";
        return 0;
    }

    return 1;
}

sub GetRowLabelValue {
    my ($self, $row) = @_;

    return "r$row";
}

sub GetColLabelValue {
    my ($self, $col) = @_;

    return  $self->{gdt}->get_col_attrib($col,'label');
}

sub SetRowLabelValue {
    my ($self, $row, $label) = @_;

    return;
}

sub SetColLabelValue {
    my ($self, $col, $label) = @_;

    return;
}

sub GetAttr {
    my ( $self, $row, $col, $kind ) = @_;

    my $attr_tag = $self->{gdt}->get_col_attrib( $col, 'tag' );

    my $cell_attr = Wx::GridCellAttr->new;

    $cell_attr->SetOverflow(0);

    # Text alignment
    $cell_attr->SetAlignment( wxALIGN_LEFT, wxALIGN_TOP )
        if $attr_tag =~ m{left$}i;
    $cell_attr->SetAlignment( wxALIGN_CENTRE, wxALIGN_TOP )
        if $attr_tag =~ m{center$}i;
    $cell_attr->SetAlignment( wxALIGN_RIGHT, wxALIGN_TOP )
        if $attr_tag =~ m{right$}i;

    # Read only cell
    $cell_attr->SetReadOnly(1) if $attr_tag =~ m{^ro}i;

    # Search dialog binding
    $cell_attr->SetBackgroundColour( Wx::Colour->new('PALE GREEN') )
        if $attr_tag =~ m{^find}i;

    return $cell_attr;
}

1;

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

=head2 GetView

Overridden to return the grid, otherwise GetView returns undef.

=head2 GetNumberRows

Overridden to return the number of rows in the table.

=head2 GetNumberCols

Overridden to return the number of columns in the table.

=head2 IsEmptyCell

Overridden to implement testing for empty cells.

=head2 GetValue

Overridden to implement accessing the table values as text.

=head2 SetValue

Overridden to implement setting the table values as text.

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

=head2 InsertRows

Insert additional rows into the table.

=head2 AppendRows

Append additional rows at the end of the table.

=head2 DeleteRows

Delete rows from the table.

=head2 InsertCols

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

=head2 GetColLabelValue

Return the label of the specified column.

=head2 SetRowLabelValue

Set the given label for the specified row.

The default version does nothing, i.e. the label is not stored. You
must override this method in your derived class if you wish
wxGrid::SetRowLabelValue() to work.

=head2 SetColLabelValue

Set the given label for the specified col.

The default version does nothing, i.e. the label is not stored. You
must override this method in your derived class if you wish
wxGrid::SetRowLabelValue() to work.

=head2 GetAttr

Returns a new attribute object every time is called.

TODO: Not efficient, alternatives?

=head1 ACKNOWLEDGMENTS

Based on the CP::Wx::Grid::Table module Copyright (c) 2012 Mark
Dootson and the DBGridTable package example from
http://wiki.wxperl.nl/Wx::GridTableBase.

Also the Grid_MegaExample.py from
git://github.com/freephys/wxPython-In-Action.git, was a source of
inspiration.

Thank you!

=cut
