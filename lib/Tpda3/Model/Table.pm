package Tpda3::Model::Table;

use Mouse;
use Tpda3::Model::Table::Key;

has 'rec_main' => (
    is      => 'ro',
    isa     => 'Maybe[Tpda3::Model::Table::Key]',
    default => sub {
        return Tpda3::Model::Table::Key->new;
    },
);

__PACKAGE__->meta->make_immutable;
no Mouse;

1;
