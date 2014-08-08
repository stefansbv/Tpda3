package Tpda3::Db::Connection;

# ABSTRACT: Connect to different databases

use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use Scalar::Util qw(blessed);
use Try::Tiny;
use DBI;

require Tpda3::Exceptions;
require Tpda3::Config;

=head1 SYNOPSIS

    use Tpda3::Db::Connection;

    my $dbh = Tpda3::Db::Connection->new();

=head2 new

Constructor method.

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

1;
