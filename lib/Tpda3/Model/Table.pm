package Tpda3::Model::Table;

use Mouse;
use namespace::autoclean;
use Mouse::Util::TypeConstraints;

require Tpda3::Model::Table::Record;

=encoding utf8

=head1 NAME

Tpda3::Model::Table::Record

=head1 VERSION

Version 0.89

=cut

our $VERSION = 0.89;

=head1 SYNOPSIS

=head1 METHODS

=cut

subtype 'TableRecordObject', as 'ArrayRef[Tpda3::Model::Table::Record]';

coerce 'TableRecordObject', from 'ArrayRef', via {
    [   map { Tpda3::Model::Table::Record->new( name => $_, value => undef ) }
            @{$_}
    ];
};

has 'table' => (
    is      => 'ro',
    isa     => 'Str',
);

has 'view' => (
    is      => 'ro',
    isa     => 'Str',
);

has '_keys' => (
    is       => 'ro',
    isa      => 'TableRecordObject',
    traits   => ['Array'],
    init_arg => 'keys',
    required => 1,
    lazy     => 1,
    coerce   => 1,
    default  => sub { [] },
    handles  => {
        get_key     => 'get',
        all_keys    => 'elements',
        map_keys    => 'map',
        find_key    => 'first',
        count_keys  => 'count',
    },
);

=head2 find_index_for

Return index for L<name>.

=cut

sub find_index_for {
    my ($self, $name) = @_;
    my $key = $self->find_key( sub { $_->name eq $name } );

    die "No key found for '$name'" unless ref $key;

    return $key;
}

=head2 update_field

Update field.

=cut

sub update_field {
    my ($self, $name, $new_value) = @_;

    die "Wrong parameters for 'update_field'" unless $name;

    $self->find_index_for($name)->value($new_value);
    return $new_value;
}

=head2 update_index

Update the index.

=cut

sub update_index {
    my ( $self, $index, $new_value ) = @_;

    die "Wrong parameters for 'update_key_index'" unless defined $index;

    my $key = $self->get_key($index);
    die "No key found with index '$index" unless ref $key;
    return $key->value($new_value);
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

1;    # End of Tpda3::Model::Table
