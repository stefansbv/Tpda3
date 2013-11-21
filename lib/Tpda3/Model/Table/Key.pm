package Tpda3::Model::Table::Key;

use Mouse;
use Mouse::Util::TypeConstraints;

use Tpda3::Model::Table::Key::Value;

subtype 'ArrayRefMTKV', as 'ArrayRef[Tpda3::Model::Table::Key::Value]';

coerce 'ArrayRefMTKV', from 'ArrayRef[HashRef]', via {
    [ map { Tpda3::Model::Table::Key::Value->new($_) } @{$_} ];
};

has _keys => (
    is       => 'ro',
    isa      => 'ArrayRefMTKV',
    traits   => ['Array'],
    required => 1,
    init_arg => 'keys',
    traits   => ['Array'],
    lazy     => 1,
    default  => sub { [] },
    handles  => {
        get_key     => 'get',
        all_keys    => 'elements',
        add_keys    => 'push',
        map_keys    => 'map',
        clear_keys  => 'clear',
        has_no_keys => 'is_empty',
    },
    coerce => 1,
);

sub update_key_index {
    my ( $self, $index, $new_value ) = @_;

    die "Wrong parameters for 'update_key_index'"
        unless ( defined($index) and defined($new_value) );

    my $key = $self->get_key($index);
    if ($key) {
        $key->value($new_value);
    }
    else {
        die "No key found with index '$index";
    }
    return;
}

__PACKAGE__->meta->make_immutable;
no Mouse;

1;
