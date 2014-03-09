package Tpda3::Db::Connection;

use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use Scalar::Util qw(blessed);
use Try::Tiny;
use DBI;

require Tpda3::Exceptions;
require Tpda3::Config;

=head1 NAME

Tpda3::Db::Connection - Connect to different databases.

=head1 VERSION

Version 0.70

=cut

our $VERSION = 0.70;

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
    my ($class, $model) = @_;

    my $self = bless {}, $class;

    $self->_connect($model);

    return $self;
}

=head2 _connect

Connect method, uses I<Tpda3::Config> module for configuration.

=cut

sub _connect {
    my ($self, $model) = @_;

    my $log = get_logger();

    my $inst = Tpda3::Config->instance;
    my $conf = $inst->connection;

    $conf->{user} = $inst->user;    # add user and pass to
    $conf->{pass} = $inst->pass;    #  connection options

    my $driver = $conf->{driver};
    my $db;
    $log->trace("Database driver is $driver");

SWITCH: for ($driver) {
        /^$/x && do warn "No driver name?\n";
        /cubrid/xi && do {
            require Tpda3::Db::Connection::Cubrid;
            $db = Tpda3::Db::Connection::Cubrid->new($model);
            last SWITCH;
        };
        /firebird/xi && do {
            require Tpda3::Db::Connection::Firebird;
            $db = Tpda3::Db::Connection::Firebird->new($model);
            last SWITCH;
        };
        /pg|postgresql/xi && do {
            require Tpda3::Db::Connection::Postgresql;
            $db = Tpda3::Db::Connection::Postgresql->new($model);
            last SWITCH;
        };
        /sqlite/xi && do {
            require Tpda3::Db::Connection::Sqlite;
            $db = Tpda3::Db::Connection::Sqlite->new($model);
            last SWITCH;
        };
        /odbcfb/xi && do {
            require Tpda3::Db::Connection::OdbcFb;
            $db = Tpda3::Db::Connection::OdbcFb->new($model);
            last SWITCH;
        };

        # Default
        warn "Database $driver not supported!\n";
        return;
    }

    $self->{dbc} = $db;

    try {
        $self->{dbh} = $db->db_connect($conf);
        if (blessed $model) {
            $model->get_connection_observable->set(1);
            $model->_print('info#Connected');
        }
    }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::Db::Connect') ) {
                $e->throw;      # rethrow the exception
            }
            else {
                print 'DBError: ', $e->can('logmsg') ? $e->logmsg : $_
                    if $inst->verbose;
                Exception::Db::Connect->throw(
                    logmsg  => "error#$_",
                    usermsg => 'error#Database error',
                );
            }
        }
    };

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Suciu.

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

1;    # End of Tpda3::Db::Connection
