package Tpda3::Db;

# ABSTRACT: Database operations module

use strict;
use warnings;

use Scalar::Util qw(blessed);

require Tpda3::Db::Connection;

use base qw(Class::Singleton);


sub _new_instance {
    my ($class, $model) = @_;

    my $conn = Tpda3::Db::Connection->new($model);

    return bless { conn => $conn }, $class;
}


sub db_connect {
    my ($self, $model) = @_;
    my $conn = Tpda3::Db::Connection->new($model);
    $self->{conn} = $conn;
    return $self;
}


sub dbh {
    my $self = shift;
    return $self->{conn}{dbh};
}


sub dbc {
    my $self = shift;
    return $self->{conn}{dbc};
}


sub DESTROY {
    my $self = shift;

    if ( blessed $self->{conn}{dbh} and $self->{conn}{dbh}->isa('DBI::db') ) {
        $self->{conn}{dbh}->disconnect;
    }

    return;
}

1;

=head1 SYNOPSIS

Create a new connection instance only once and use it many times.

    use Tpda3::Db;

    my $dbi = Tpda3::Db->instance($args); # first time init

    my $dbi = Tpda3::Db->instance();      # later, in other modules

    my $dbh = $dbi->dbh;

=head2 _new_instance

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=head2 db_connect

Connect when there already is an instance.

=head2 dbh

Return database handle.

=head2 dbc

Module instance

=head2 DESTROY

Destroy method.

=head1 ACKNOWLEDGEMENTS

Inspired from PerlMonks node [id://609543] by GrandFather.

=cut
