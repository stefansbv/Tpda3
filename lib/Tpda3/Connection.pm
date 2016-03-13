package Tpda3::Connection;

# ABSTRACT: Make URI from connection file

use 5.010001;
use Mouse;
use Try::Tiny;
use URI::db;

use Tpda3::Config;

has 'config' => (
    is      => 'ro',
    isa     => 'Tpda3::Config',
    lazy    => 1,
    default => sub {
        return Tpda3::Config->instance;
    },
);

has 'connection' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->config->connection;
    },
);

has 'uri' => (
    is       => 'rw',
    isa      => 'Str',
);

has 'driver' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->uri_db->engine;
    },
);

has 'host' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->uri_db->host;
    },
);

has 'dbname' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->uri_db->dbname;
    },
);

has 'port' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->uri_db->port;
    },
);

has 'user' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->uri_db->user;
    },
);

has 'role' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);

has 'uri_db' => (
    is      => 'ro',
    isa     => 'URI::db',
    lazy    => 1,
    builder => '_build_uri',
);

sub _build_uri {
    my $self = shift;
    my $conn = $self->connection;
    my $uri  = URI::db->new;
    $uri->engine( $conn->{driver} );
    $uri->dbname( $conn->{dbname} );
    $uri->host( $conn->{host} ) if $conn->{host};
    $uri->port( $conn->{port} ) if $conn->{port};
    $uri->user( $conn->{user} ) if $conn->{user};

    # Workaround to add a role param
    if ( my $role = $conn->{role} ) {
        my $str = $uri->as_string;
        $uri = URI::db->new("$str?ib_role=$role");
        $self->role($role);
    }
    $self->uri( $uri->as_string );
    return $uri;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis


=head1 Description


=head1 Interface

=head2 Attributes

=item3 config

=item3 connection

=item3 uri

=item3 host

=item3 dbname

=item3 port

=item3 user

=item3 role

=head2 Instance Methods

=cut
