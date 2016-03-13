package Tpda3::Role::Utils;

# ABSTRACT: Role for utility functions

use 5.0100;
use utf8;
use Moose::Role;

sub sort_hash_by_pos {
    my ( $self, $attribs ) = @_;

    #-- Sort by pos
    #- Keep only key and pos for sorting
    my %temp = map { $_ => $attribs->{$_}{pos} } keys %{$attribs};

    #- Sort with  ST
    my @attribs = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map { [ $_ => $temp{$_} ] }
        keys %temp;

    return wantarray ? @attribs : \@attribs;
}

sub trim {
    my ( $self, @text ) = @_;
    for (@text) {
        s/^\s+//;
        s/\s+$//;
    }
    return wantarray ? @text : "@text";
}

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Name

Tpda3::Role::Utils - A role for some utility functions

=head1 Synopsis

  package Tpda3::...
  with 'Tpda3::Role::Utils';

=head1 Description

This role encapsulates common functions.

=head1 Interface

=head2 Class Methods

=head2 sort_hash_by_pos

Use ST to sort hash by value (pos), returns an array or an array
reference of the sorted items.

=head2 trim

Trim strings or arrays.

=head1 Author

Ștefan Suciu <stefan@s2i2.ro>

=cut
