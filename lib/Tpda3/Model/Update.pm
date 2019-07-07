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

has 'meta_main' => (
    is       => 'ro',
    isa      => 'Tpda3::Model::Meta::Main',
    required => 1,
);

has 'meta_dep' => (
    is       => 'ro',
    isa      => 'Tpda3::Model::Meta::Dep',
    required => 1,
);

has 'compare' => (
    is       => 'ro',
    isa      => 'Tpda3::Model::Update::Compare',
    required => 1,
);

sub where_for_insert {
    my ($self, $id) = @_;
    die "insert_where: the \$id parameter is missing" unless defined $id;
    my $where = $self->meta_dep->where;
    my $fkcol = $self->meta_dep->fkcol;
    say "table = ", $self->meta_main->table;
    say "   fk = $fkcol";
    $where->{$fkcol} = $id;
    dd $where;
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
