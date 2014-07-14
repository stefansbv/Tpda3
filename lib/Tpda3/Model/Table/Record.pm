package Tpda3::Model::Table::Record;

use Mouse;
use namespace::autoclean;

=encoding utf8

=head1 NAME

Tpda3::Model::Table::Record

=head1 VERSION

Version 0.88

=cut

our $VERSION = 0.88;

=head1 SYNOPSIS

=head1 METHODS

=cut

has 'name'  => ( is  => 'ro', isa => 'Str' );
has 'value' => ( is  => 'rw', isa => 'Maybe[Str]' );

sub get_href {
    my $self = shift;
    return { $self->name => $self->value };
}

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Model::Table::Record
