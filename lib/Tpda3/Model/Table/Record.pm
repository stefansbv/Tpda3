package Tpda3::Model::Table::Record;

use Mouse;
use namespace::autoclean;

has 'name'  => ( is  => 'ro', isa => 'Str' );
has 'value' => ( is  => 'rw', isa => 'Maybe[Int]' );

sub get_href {
    my $self = shift;
    return { $self->name => $self->value };
}

__PACKAGE__->meta->make_immutable;

1;
