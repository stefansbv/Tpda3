package Tpda3::Model::Table::Record;

# ABSTRACT: Database table meta data record ( name => value )

use Mouse;


has 'name'  => ( is  => 'ro', isa => 'Str' );
has 'value' => ( is  => 'rw', isa => 'Maybe[Str]' );


sub get_href {
    my $self = shift;
    return { $self->name => $self->value };
}

__PACKAGE__->meta->make_immutable;

no Mouse;

=head1 SYNOPSIS

    my $rec = Tpda3::Model::Table::Record->new( name => 'key1', value => 100 );

=head2 get_href

Return a hash reference: { name => value }.

=cut
