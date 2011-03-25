package Tpda3::Db::Connection::Sqlite;

use strict;
use warnings;

use Try::Tiny;
use Log::Log4perl qw(get_logger);

use DBI;

=head1 NAME

Tpda3::Db::Connection::Sqlite - Connect to a SQLite database.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Tpda3::Db::Connection::Sqlite;

    my $db = Tpda3::Db::Connection::Sqlite->new();

    $db->db_connect($connection);

=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

=head2 db_connect

Connect to database

=cut

sub db_connect {
    my ($self, $conf) = @_;

    my $log = get_logger();

    $log->info("Database driver is: $conf->{driver}");
    $log->trace("Parameters:");
    $log->trace("  => Database = $conf->{dbname}\n");

    try {
        $self->{_dbh} = DBI->connect(
            "dbi:SQLite:"
              . $conf->{dbname},
            q{},
            q{},
        );
    }
    catch {
        $log->fatal("Transaction aborted: $_")
            or print STDERR "$_\n";
    };

    ## Date format ISO

    # UTF-8 support
    $self->{_dbh}{sqlite_unicode} = 1;

    $log->info("Connected to '$conf->{dbname}'");

    return $self->{_dbh};
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of Tpda3::Db::Connection::Sqlite
