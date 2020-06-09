package Tpda3::Model::Meta::Main;

# ABSTRACT: Meta data model for the main table

use Moo;
use MooX::HandlesVia;
use Tpda3::Types qw(
    HashRef
    Str
);

has '_main_meta' => (
    is          => 'ro',
    handles_via => 'Hash',
    init_arg    => 'metadata',
    required    => 1,
    lazy        => 1,
    default     => sub { {} },
    handles     => {
        main_meta     => 'keys',
        get_main_meta => 'get',
    },
);

has 'table' => (
    is      => 'ro',
    isa     => Str,
    default => sub {
        my $self = shift;
        return $self->get_main_meta('table');
    },
);

has 'where' => (
    is      => 'ro',
    isa     => HashRef,
    default => sub {
        my $self = shift;
        return $self->get_main_meta('where');
    },
);


__PACKAGE__->meta->make_immutable;

__END__

=encoding utf8

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 OPTIONS

=head2 ATTRIBUTES

=head2 INSTANCE METHODS

=cut
