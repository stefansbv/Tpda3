package Tpda3::Wx::Grid::DataTable;

# ABSTRACT: Grid data table implementation

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {
        datacols => [],
        datarows => [],
        selected => [],
    };

    bless $self, $class;

    return $self;
}

#-- Cols

sub set_col_attribs {
    my ($self, $col, $col_attr_ref) = @_;

    $self->{datacols}[$col] = $col_attr_ref;

    return;
}

sub get_col_attrib {
    my ($self, $col, $attr) = @_;

    return $self->{datacols}[$col]{$attr};
}

sub get_col_num {
    my $self = shift;

    return scalar( @{ $self->get_col_data } );
}

sub get_col_data {
    my $self = shift;

    return $self->{datacols};
}

#-- Rows

sub set_row_value {
    my ($self, $row, $col, $value) = @_;

    $self->{datarows}[$row][$col] = $value;

    return;
}

sub get_row_value {
    my ($self, $row, $col) = @_;

    return $self->{datarows}[$row][$col];
}

sub get_row_data {
    my $self = shift;

    return $self->{datarows};
}

sub get_row_num {
    my $self = shift;

    return scalar( @{ $self->get_row_data } );
}

#-- Sels

sub set_selection {
    my ($self, $rows_aref) = @_;

    $self->{selection} = $rows_aref;

    return;
}

sub get_selection {
    my ($self) = @_;

    return $self->{selection};
}

1;

=head1 ACKNOWLEDGMENTS

Inspired from the CP::Wx::Grid::Table module Copyright (c) 2012 Mark
Dootson and the DBGridTable package example from
http://wiki.wxperl.nl/Wx::GridTableBase.

Thank you!

=cut
