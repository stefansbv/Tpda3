package Tpda3::Model::Meta::Dep;

# ABSTRACT:  Meta data for a dependent table

use Mouse;
use Mouse::Util::TypeConstraints;

has '_dep_meta' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    init_arg => 'metadata',
    required => 1,
    lazy     => 1,
    default  => sub { {} },
    handles  => {
        dep_meta     => 'keys',
        get_dep_meta => 'get',
    },
);

has 'table' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('table');
    },
);

has 'where' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('where');
    },
);

has 'colslist' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('colslist');
    },
);

has 'fkcol' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('fkcol');
    },
);

has 'order' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('order');
    },
);

has 'pkcol' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('pkcol');
    },
);

has 'updstyle' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('updstyle');
    },
);


__PACKAGE__->meta->make_immutable;

no Mouse;

=head1 SYNOPSIS

=cut
