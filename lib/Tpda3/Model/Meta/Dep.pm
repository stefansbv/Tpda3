package Tpda3::Model::Meta::Dep;

# ABSTRACT:  Meta data for a dependent table

use Moo;
use MooX::HandlesVia;
use Tpda3::Types qw(
    ArrayRef
    HashRef
    Str
);
use Tpda3::Utils;

has 'pk_key' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'pk_val' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'main_keys' => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

has '_metadata' => (
    is          => 'ro',
    handles_via => 'Hash',
    init_arg    => 'metadata',
    required    => 1,
    lazy        => 1,
    default     => sub { {} },
    handles     => {
        dep_meta     => 'keys',
        get_dep_meta => 'get',
    },
);

has 'table' => (
    is      => 'ro',
    isa     => Str,
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('table');
    },
);

has 'where' => (
    is      => 'ro',
    isa     => HashRef,
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('where');
    },
);

has 'colslist' => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('colslist');
    },
);

has 'fkcol' => (
    is      => 'ro',
    isa     => Str,
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('fkcol');
    },
);

has 'order' => (
    is      => 'ro',
    isa     => Str,
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('order');
    },
);

has 'pkcol' => (
    is      => 'ro',
    isa     => Str,
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('pkcol');
    },
);

has 'updstyle' => (
    is      => 'ro',
    isa     => Str,
    default => sub {
        my $self = shift;
        return $self->get_dep_meta('updstyle');
    },
);

# sub do_it {

#     my $metadata = {};

#     # for 'qry'
#     $metadata->{table} = $self->table_key($page, $tm)->view;
#     $metadata->{where}{$pk_key} = $pk_val;
#     foreach my $key (@main_keys) {
#         my $key_name = $key->name;
#         next if exists $metadata->{where}{$key_name}; # skip pk_key
#         my $key_val = $key->value;
#         $metadata->{where}{$key_name} = $key_val;
#     }
#     my $columns = $self->scrcfg->deptable_columns($tm);

#     $metadata->{pkcol}    = $pk_key;
#     $metadata->{fkcol}    = $self->table_key($page, $tm)->get_key(1)->name;
#     $metadata->{order}    = $self->scrcfg->deptable_orderby($tm);
#     $metadata->{colslist} = Tpda3::Utils->sort_hash_by_id($columns);
#     $metadata->{updstyle} = $self->scrcfg->deptable_updatestyle($tm);

#     return $metadata;
# }

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my @args  = @_;
    # use Data::Dump; dd @args;
    # $args[0]->{hints} = ds_to_hoh( $args[0]->{hints}, 'hint' )
    #     if exists $args[0]->{hints};
    return $class->$orig(@args);
};

__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS

=cut
