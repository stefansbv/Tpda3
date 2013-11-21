package Tpda3::Model::Table::Key::Value;

use Mouse;

has 'name' => (
    is  => 'rw',
    isa => 'Str'
);

has 'value' => (
    is  => 'rw',
    isa => 'Maybe[Int]'
);

sub get_href {
    my $self = shift;
    return { $self->name => $self->value };
}

__PACKAGE__->meta->make_immutable;
no Mouse;

1;
