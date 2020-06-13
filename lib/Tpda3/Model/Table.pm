package Tpda3::Model::Table;

# ABSTRACT: Database table meta data

use Moo;
use MooX::HandlesVia;
use Tpda3::Types qw(
    ArrayRef
    Maybe
    Str
    Tpda3Record
);
use Tpda3::Model::Table::Record;
use namespace::autoclean;
use Data::Dump qw/dump/;

has 'table' => (
    is  => 'ro',
    isa => Str,
);

has 'view' => (
    is  => 'ro',
    isa => Str,
);

has 'page' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

# record or table (TM)
has 'display' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has '_keys' => (
    is          => 'ro',
    handles_via => 'Array',
    init_arg    => 'keys',
    required    => 1,
    lazy        => 1,
    default     => sub { [] },
    coerce      => sub {
        my $keys = shift;
        return [   map {
                Tpda3::Model::Table::Record->new(
                    name  => $_,
                    value => undef
                )
            } @{$keys}
        ];
    },
    isa     => ArrayRef[Tpda3Record],
    handles => {
        get_key    => 'get',
        all_keys   => 'elements',
        map_keys   => 'map',
        find_key   => 'first',
        count_keys => 'count',
    },
);

has 'fields' => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

has 'fields_rw' => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

has 'order' => (
    is       => 'ro',
    isa      => Str|ArrayRef,
    required => 0,
);

has 'updstyle' => (
    is       => 'ro',
    isa      => Str,
    required => 0,
);

#---

has 'pkcol' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $field = $self->get_key(0);
        if ( $field and ref $field ) {
            return $field->name;
        }
        return;
    },
);

has 'fkcol' => (
    is      => 'ro',
    isa     => Maybe[Str],
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $field = $self->get_key(1);
        if ( $field and ref $field ) {
            return $field->name;
        }
        return;
    },
);

sub find_index_for {
    my ($self, $name) = @_;
    my $key = $self->find_key( sub { $_->name eq $name } );
    die "No key found for '$name'" unless ref $key;
    return $key;
}

sub update_key_field {
    my ($self, $name, $new_value) = @_;
    die "Wrong parameters for 'update_key_field'" unless $name;
    $self->find_index_for($name)->value($new_value);
    return $new_value;
}

sub update_key_index {
    my ( $self, $index, $new_value ) = @_;
    die "Wrong parameters for 'update_key_index'" unless defined $index;
    my $key = $self->get_key($index);
    die "No key found with index '$index" unless ref $key;
    return $key->value($new_value);
}

sub build_sql_params_main {
    my ( $self, $sql ) = @_;
    print "# build_sql_params_main: for $sql\n";
    my $meta = {};
    $meta->{table} = $sql eq 'query' ? $self->view : $self->table;
    $meta->{columns} = $self->fields if $sql ne 'delete';
    $meta->{pkcol}   = $self->pkcol  if $sql eq 'insert';
    foreach my $key ( $self->all_keys ) {
        $meta->{where}{ $key->name } = $key->value;
    }
    return $meta;
}

sub build_sql_params_deps {
    my ( $self, $sql ) = @_;
    print "# build_sql_params_deps: for $sql\n";
    my $meta = {};
    $meta->{table} = $sql eq 'query' ? $self->view : $self->table;
    $meta->{colslist} = $self->fields if $sql ne 'delete';
    $meta->{pkcol}    = $self->pkcol;
    $meta->{fkcol}    = $self->fkcol;
    $meta->{order}    = $self->order;
    $meta->{updstyle} = $self->updstyle;
    print "page = ", $self->page, "\n";
    my @keys = $self->all_keys;
    pop @keys if $self->display eq 'table';
    foreach my $key (@keys) {
        $meta->{where}{ $key->name } = $key->value;
    }
    return $meta;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 SYNOPSIS

    my $table  = Tpda3::Model::Table->new(
        keys   => [ 'key_field1', 'key_field2' ],
        table  => 'table_name',
        view   => 'view_name',
    );

    # Elsewhere
    my $table_name = $table->table;

    my $table_view = $table->view;

    $table->update_key_field( 'key_field1', 101 );

=head2 find_index_for

Return index for L<name>.

=head2 update_key_field

Update the key field value.

=head2 update_key_index

Update the key when we know the index.

=cut
