package Tpda3::Db::Connection;

use strict;
use warnings;

use Tpda3::Config;

=head1 NAME

Tpda3::Db::Connection - Connect to different databases.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Connect to a database.

    use Tpda3::Db::Connection;

    my $dbh = Tpda3::Db::Connection->new();

=head1 METHODS

=head2 new

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub new {
    my $class = shift;

    my $self = bless {}, $class;

    $self->_connect();

    return $self;
}

=head2 _connect

Connect method, uses I<Tpda3::Config> module for configuration.

=cut

sub _connect {
    my $self = shift;

    my $log = get_logger();

    my $inst = Tpda3::Config->instance;
    my $conf = $inst->connection;

    my $cfgn = $inst->cfgname;
    $conf->{$cfgn}{user} = $inst->user;    # add user and pass to options
    if ( !$conf->{$cfgn}{user} ) {
        $conf->{$cfgn}{user} = $self->read_username();
    }
    $conf->{$cfgn}{pass} = $inst->pass;
    if ( !$conf->{$cfgn}{pass} ) {
        $conf->{$cfgn}{pass} = $self->read_password();
    }

    my $driver = $conf->{$cfgn}{driver};
    my $db;

  SWITCH: for ( $driver ) {
        /^$/ && do warn "No driver name?\n";
        /firebird/i && do {
            require Tpda3::Db::Connection::Firebird;
            $db = Tpda3::Db::Connection::Firebird->new();
            last SWITCH;
        };
        /postgresql/i && do {
            require Tpda3::Db::Connection::Postgresql;
            $db = Tpda3::Db::Connection::Postgresql->new();
            last SWITCH;
        };
        /mysql/i && do {
            require Tpda3::Db::Connection::Mysql;
            $db = Tpda3::Db::Connection::MySql->new();
            last SWITCH;
        };
        # Default
        warn "Database $driver not supported!\n";
        return;
    }

    $self->{dbc} = $db;
    $self->{dbh} = $db->db_connect( $conf->{$cfgn} );
}

=head2 read_username

Read and return user name from command line

=cut

sub read_username {
    my $self = shift;

    warn 'read_username not implemented';
}

=head2 read_password

Read and return password from command line

=cut

sub read_password {
    my $self = shift;

    warn 'read_password not implemented';
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1; # End of Tpda3::Db::Connection
