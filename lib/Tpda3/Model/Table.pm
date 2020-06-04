package Tpda3::Model::Table;

# ABSTRACT: Database table meta data

use Moo;
use MooX::HandlesVia;
use Tpda3::Types qw(
    ArrayRef
    Str
    Tpda3Record
);
use Tpda3::Model::Table::Record;
use namespace::autoclean;

# subtype 'TableRecordObject', as 'ArrayRef[Tpda3::Model::Table::Record]';
# coerce 'TableRecordObject', from 'ArrayRef', via {
#     [   map { Tpda3::Model::Table::Record->new( name => $_, value => undef ) }
#             @{$_}
#     ];
# };

has 'table' => (
    is  => 'ro',
    isa => Str,
);

has 'view' => (
    is  => 'ro',
    isa => Str,
);

has '_keys' => (
    is          => 'ro',
    handles_via => 'Array',
    init_arg    => 'keys',
    required    => 1,
    lazy        => 1,
    default     => sub { [] },
    coerce      => sub {
        my $keys = shift;
        return [   map {
                Tpda3::Model::Table::Record->new(
                    name  => $_,
                    value => undef
                )
            } @{$keys}
        ];
    },
    isa     => ArrayRef[Tpda3Record],
    handles => {
        get_key    => 'get',
        all_keys   => 'elements',
        map_keys   => 'map',
        find_key   => 'first',
        count_keys => 'count',
    },
);

sub find_index_for {
    my ($self, $name) = @_;
    my $key = $self->find_key( sub { $_->name eq $name } );

    die "No key found for '$name'" unless ref $key;

    return $key;
}

sub update_key_field {
    my ($self, $name, $new_value) = @_;

    die "Wrong parameters for 'update_key_field'" unless $name;

    $self->find_index_for($name)->value($new_value);
    return $new_value;
}

sub update_key_index {
    my ( $self, $index, $new_value ) = @_;

    die "Wrong parameters for 'update_key_index'" unless defined $index;

    my $key = $self->get_key($index);
    die "No key found with index '$index" unless ref $key;
    return $key->value($new_value);
}

__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS

    my $table  = Tpda3::Model::Table->new(
        keys   => [ 'key_field1', 'key_field2' ],
        table  => 'table_name',
        view   => 'view_name',
    );

    # Elsewhere
    my $table_name = $table->table;

    my $table_view = $table->view;

    $table->update_key_field( 'key_field1', 101 );

=head2 find_index_for

Return index for L<name>.

=head2 update_key_field

Update the key field value.

=head2 update_key_index

Update the key when we know the index.

=cut
