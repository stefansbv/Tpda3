package Tpda3::Model::Meta::Main;

# ABSTRACT: Meta data for the main table

use Mouse;
use Mouse::Util::TypeConstraints;

has '_main_meta' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    init_arg => 'metadata',
    required => 1,
    lazy     => 1,
    default  => sub { {} },
    handles  => {
        main_meta     => 'keys',
        get_main_meta => 'get',
    },
);

has 'table' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        return $self->get_main_meta('table');
    },
);

has 'where' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        my $self = shift;
        return $self->get_main_meta('where');
    },
);


__PACKAGE__->meta->make_immutable;

no Mouse;

=head1 SYNOPSIS

=cut
