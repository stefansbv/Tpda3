package Tpda3::Model::Table;

use Mouse;
use namespace::autoclean;
use Mouse::Util::TypeConstraints;

use Tpda3::Model::Table::Record;

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

sub find_index_for {
    my ($self, $name) = @_;
    my $key = $self->find_key( sub { $_->name eq $name } );

    die "No key found for '$name'" unless ref $key;

    return $key;
}

sub update_field {
    my ($self, $name, $new_value) = @_;

    die "Wrong parameters for 'update_field'" unless $name;

    $self->find_index_for($name)->value($new_value);
    return $new_value;
}

sub update_index {
    my ( $self, $index, $new_value ) = @_;

    die "Wrong parameters for 'update_key_index'" unless defined $index;

    my $key = $self->get_key($index);
    die "No key found with index '$index" unless ref $key;
    return $key->value($new_value);
}

__PACKAGE__->meta->make_immutable;

1;
