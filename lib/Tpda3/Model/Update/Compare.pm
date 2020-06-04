package Tpda3::Model::Update::Compare;

# ABSTRACT: Update

use Moo;
use MooX::HandlesVia;
use Tpda3::Types qw(
    Int
    Bool
    Str
    ArrayRef
    HashRef
    ListCompare
);
use Data::Compare;
use List::Compare;
use namespace::autoclean;

has 'debug' => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 },
);

has 'fk_col' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'db_data' => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

has 'tm_data' => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

#---

has 'db_fk_data' => (
    is       => 'ro',
    isa      => ArrayRef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->aoh_column_extract( $self->db_data, $self->fk_col );
    },
);

has 'db_data_hoh' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->aoh_to_hoh( $self->db_data, $self->fk_col );
    },
    handles => { get_db_data => 'get', },
);

has 'tm_fk_data' => (
    is       => 'ro',
    isa      => ArrayRef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->aoh_column_extract( $self->tm_data, $self->fk_col );
    },
);

has 'tm_data_hoh' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->aoh_to_hoh( $self->tm_data, $self->fk_col );
    },
    handles => { get_tm_data => 'get', },
);

has '_lc' => (
    is      => 'ro',
    isa     => ListCompare,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return List::Compare->new( $self->tm_fk_data, $self->db_fk_data );
    },
);

has 'to_insert' => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @to_insert = $self->_lc->get_unique;
        return \@to_insert;
    },
);

has 'to_delete' => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @to_delete = $self->_lc->get_complement;
        return \@to_delete;
    },
);

has '_to_update' => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub {
        my $self      = shift;
        my @to_update = $self->_lc->get_intersection;
        return \@to_update;
    },
);

has 'to_update' => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @to_update;
        foreach my $id ( @{ $self->_to_update } ) {
            my $tm_data = $self->get_tm_data($id);
            my $db_data = $self->get_db_data($id);
            my $dc = Data::Compare->new( $tm_data, $db_data );
            if ( !$dc->Cmp ) {
                push @to_update, $id;
            }
        }
        return \@to_update;
    },
);

sub aoh_column_extract {
    my ( $self, $aoh, $column ) = @_;
    my @col;
    foreach my $rec ( @{$aoh} ) {
        my $key = $rec->{$column};
        push @col, $key;
    }
    return \@col;
}

sub aoh_to_hoh {
    my ( $self, $aoh, $column ) = @_;
    my %hoh;
    foreach my $rec ( @{$aoh} ) {
        my $key = $rec->{$column};
        $hoh{$key} = $rec;
    }
    return \%hoh;
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 ATTRIBUTES

=head3 attr1

=head2 INSTANCE METHODS

=head2 aoh_column_extract

Extract and return a column array reference from an AoH data
structure.

=cut
