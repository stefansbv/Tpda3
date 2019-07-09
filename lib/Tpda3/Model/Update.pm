package Tpda3::Model::Update;

# ABSTRACT: Update

use 5.010;
use Mouse;

use Data::Dump;

has 'debug' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

has 'table' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'fk_col' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'where' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'compare' => (
    is       => 'ro',
    isa      => 'Tpda3::Model::Update::Compare',
    required => 1,
);

sub fkcol_where {
    my ( $self, $id ) = @_;
    die "Model::Update where: the \$id parameter is missing" unless defined $id;
    my $where = $self->where;
    my $fkcol = $self->fk_col;
    $where->{$fkcol} = $id;
    return $where;
}


__PACKAGE__->meta->make_immutable;

no Mouse;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 ATTRIBUTES

=head3 attr1

=head2 INSTANCE METHODS

=head3 meth1

=cut
