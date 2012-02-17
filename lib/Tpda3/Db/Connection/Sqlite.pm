package Tpda3::Db::Connection::Sqlite;

use strict;
use warnings;

use Regexp::Common;
use Log::Log4perl qw(get_logger);

use Try::Tiny;
use DBI;

=head1 NAME

Tpda3::Db::Connection::Sqlite - Connect to a SQLite database.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

    use Tpda3::Db::Connection::Sqlite;

    my $db = Tpda3::Db::Connection::Sqlite->new();

    $db->db_connect($connection);

=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my ($class, $model) = @_;

    my $self = {};

    $self->{model} = $model;

    bless $self, $class;

    return $self;
}

=head2 db_connect

Connect to database

=cut

sub db_connect {
    my ( $self, $conf ) = @_;

    my $log = get_logger();

    $log->trace("Database driver is: $conf->{driver}");
    $log->trace("Parameters:");
    $log->trace(" > Database = ",$conf->{dbname} ? $conf->{dbname} : '?', "\n");
    $log->trace(" > Host     = ",$conf->{host} ? $conf->{hosst} : '?', "\n");

    try {
        $self->{_dbh}
            = DBI->connect( "dbi:SQLite:" . $conf->{dbname}, q{}, q{}, );
    }
    catch {
        my $user_message = $self->parse_db_error($_);
        $self->{model}->exception_log($user_message);
    };

    ## Date format ISO

    # UTF-8 support
    $self->{_dbh}{sqlite_unicode} = 1;

    $log->info("Connected to '$conf->{dbname}'");

    return $self->{_dbh};
}

=head2 parse_db_error

Parse a database error message, and translate it for the user.

=cut

sub parse_db_error {
    my ($self, $si) = @_;

    print "\nSI: $si\n\n";

    my $message_type =
         $si eq q{}                                       ? "nomessage"
       : $si =~ m/prepare failed: near ($RE{quoted}):/smi  ? "notsuported:$1"
       :                                                    "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        nomessage   => "weird#Error without message!",
        notsuported => "fatal#Syntax not supported: $name!",
        unknown     => "fatal#Uncategorized database error",
    };

    my $message;
    if (exists $translations->{$type} ) {
        $message = $translations->{$type}
    }
    else {
        print "EE: Translation error!\n";
    }

    return $message;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1;    # End of Tpda3::Db::Connection::Sqlite
