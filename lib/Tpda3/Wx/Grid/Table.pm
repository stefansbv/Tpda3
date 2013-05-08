package Tpda3::Wx::Grid::Table;

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

=head1 NAME

Tpda3::Wx::GridTable

=head1 VERSION

Version 0.67

=cut

our $VERSION = 0.67;

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
    my ( $class, $gdt, $grid ) = @_;

    my $self = $class->SUPER::new();

    $self->{view} = $grid;
    $self->{gdt}  = $gdt;

    return $self;
}

=head2 GetView

Overridden to return the grid? Otherwise GetView returns undef.

=cut

sub GetView {
    my $self = shift;

    return $self->{view};
}

=head2 GetNumberRows

Overridden to return the number of rows in the table.

=cut

sub GetNumberRows {
    my $self = shift;

    my $rowcount = $self->{gdt}->get_row_num;
    print "rowcount: $rowcount\n";

    return $rowcount;
}

=head2 GetNumberCols

Overridden to return the number of columns in the table.

=cut

sub GetNumberCols {
    my $self = shift;

    my $colcount = $self->{gdt}->get_col_num;
    print "colcount $colcount\n";

    return $colcount;
}

=head2 IsEmptyCell

Overridden to implement testing for empty cells.

=cut

sub IsEmptyCell {
    my ( $self, $row, $col ) = @_;

    return ( defined( $self->{gdt}->get_row_value($row, $col) ) )
        ? 0
        : 1;
}

=head2 GetValue

Overridden to implement accessing the table values as text.

=cut

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

=head2 SetValue

Overridden to implement setting the table values as text.

=cut

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

=cut

sub InsertRows {
    my ( $self, $pos, $rows ) = @_;
    return 0;
}

=head2 AppendRows

Append additional rows at the end of the table.

=cut

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

=head2 DeleteRows

Delete rows from the table.

=cut

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

=cut

sub GetRowLabelValue {
    my ($self, $row) = @_;

    return "r$row";
}

=head2 GetColLabelValue

Return the label of the specified column.

=cut

sub GetColLabelValue {
    my ($self, $col) = @_;

    return  $self->{gdt}->get_col_attrib($col,'label');
}

=head2 SetRowLabelValue

Set the given label for the specified row.

The default version does nothing, i.e. the label is not stored. You
must override this method in your derived class if you wish
wxGrid::SetRowLabelValue() to work.

=cut

sub SetRowLabelValue {
    my ($self, $row, $label) = @_;

    return;
}

=head2 SetColLabelValue

Set the given label for the specified col.

The default version does nothing, i.e. the label is not stored. You
must override this method in your derived class if you wish
wxGrid::SetRowLabelValue() to work.

=cut

sub SetColLabelValue {
    my ($self, $col, $label) = @_;

    return;
}

sub GetAttr {
  my( $self, $row, $col, $kind ) = @_;

  my $cell_attr = Wx::GridCellAttr->new;

  # Text alignment
  if ($self->GetTypeName(0, $col) eq 'double' ) {
      $cell_attr->SetAlignment(wxALIGN_RIGHT, wxALIGN_TOP);
  }
  elsif ($self->GetTypeName(0, $col) eq 'int_id') {
      $cell_attr->SetAlignment(wxALIGN_CENTRE, wxALIGN_TOP);
  }

  $cell_attr->SetOverflow(0);

  return $cell_attr;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

Many!

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGMENTS

Based on the CP::Wx::Grid::Table module Copyright (c) 2012 Mark
Dootson and the DBGridTable package example from
http://wiki.wxperl.nl/Wx::GridTableBase.

Also the Grid_MegaExample.py from
<<<<<<< Updated upstream
git://github.com/freephys/wxPython-In-Action.git, is a good source of
=======
git://github.com/freephys/wxPython-In-Action.git, was a source of
>>>>>>> Stashed changes
inspiration.

Thank you!

=head1 LICENSE AND COPYRIGHT

Copyright:
  Mark Dootson  2012
  Stefan Suciu  2013

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::Grid::Table
