package Tpda3::Db::Connection::Sqlite;

# ABSTRACT: Connect to a SQLite database

use strict;
use warnings;

use DBI;
use Log::Log4perl qw(get_logger :levels);
use Regexp::Common;
use Try::Tiny;

require Tpda3::Exceptions;
require Tpda3::Utils;

sub new {
    my ($class, $model) = @_;
    my $self = {};
    $self->{model} = $model;
    bless $self, $class;
    return $self;
}

sub driver {
    return 'SQLite';
}

sub db_connect {
    my ( $self, $conf ) = @_;

    my $log = get_logger();

    my ($dbname, $driver) = @{$conf}{qw(dbname driver)};

    my $dbfile = Tpda3::Utils->get_sqlitedb_filename($dbname);

    $log->trace("Database driver is: $driver");
    $log->trace("Parameters:");
    $log->trace(" > Database = ", $dbfile ? $dbfile : '?', "\n");

    my $dsn = qq{dbi:SQLite:dbname=$dbfile};

    $self->{_dbh} = DBI->connect(
        $dsn, undef, undef,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 1,
            PrintError       => 0,
            LongReadLen      => 524288,
            HandleError      => sub { $self->handle_error() },
            sqlite_unicode   => 1,
        }
    );

    return $self->{_dbh};
}

sub handle_error {
    my $self = shift;

    if ( defined $self->{_dbh} and $self->{_dbh}->isa('DBI::db') ) {
        my $errorstr = $self->{_dbh}->errstr;
        Exception::Db::SQL->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }
    else {
        my $errorstr = DBI->errstr;
        Exception::Db::Connect->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }

    return;
}

sub parse_error {
    my ($self, $si) = @_;

    my $log = get_logger();

    $log->error("EE: $si");

    my $message_type =
         $si eq q{}                                        ? "nomessage"
       : $si =~ m/prepare failed: no such table: (\w+)/smi ? "relnotfound:$1"
       : $si =~ m/prepare failed: near ($RE{quoted}):/smi  ? "notsuported:$1"
       : $si =~ m/not connected/smi                        ? "notconn"
       : $si =~ m/(.*) may not be NULL/smi                 ? "errnull:$1"
       :                                                     "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        nomessage   => "weird#Error without message!",
        notsuported => "fatal#Syntax not supported: $name!",
        relnotfound => "fatal#Relation $name not found",
        unknown     => "fatal#Database error",
        notconn     => "error#Not connected",
        errnull     => "error#$name may not be NULL",
    };

    my $message;
    if (exists $translations->{$type} ) {
        $message = $translations->{$type}
    }
    else {
        $log->error('EE: Translation error for: $si!');
    }

    return $message;
}

sub table_info_short {
    my ( $self, $table ) = @_;

    my $h_ref = $self->{_dbh}
        ->selectall_hashref( "PRAGMA table_info($table)", 'cid' );

    my $flds_ref = {};
    foreach my $cid ( sort keys %{$h_ref} ) {
        my $name       = $h_ref->{$cid}{name};
        my $dflt_value = $h_ref->{$cid}{dflt_value};
        my $notnull    = $h_ref->{$cid}{notnull};
        # my $pk       = $h_ref->{$cid}{pk}; is part of PK ? index : undef
        my $data_type  = $h_ref->{$cid}{type};

        # Parse type;
        my ($type, $precision, $scale);
        if ( $data_type =~ m{
               (\w+)                           # data type
               (?:\((\d+)(?:,(\d+))?\))?       # optional (precision[,scale])
             }x
         ) {
            $type      = $1;
            $precision = $2;
            $scale     = $3;
        }

        my $info = {
            pos         => $cid,
            name        => $name,
            type        => $type,
            is_nullable => $notnull ? 0 : 1,
            defa        => $dflt_value,
            length      => $precision,
            prec        => $precision,
            scale       => $scale,
        };
        $flds_ref->{$cid} = $info;
    }

    return $flds_ref;
}

sub table_exists {
    my ( $self, $table ) = @_;

    my $log = get_logger();
    $log->info("Checking if $table table exists");

    my $sql = qq( SELECT COUNT(name)
                FROM sqlite_master
                WHERE type = 'table'
                    AND name = '$table';
    );

    $log->trace("SQL= $sql");

    my $val_ret;
    try {
        ($val_ret) = $self->{_dbh}->selectrow_array($sql);
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $val_ret;
}

sub table_keys {
    my ( $self, $table ) = @_;

    my @names = $self->{_dbh}->primary_key(undef, undef, $table);

    return \@names;
}

sub table_list {
    my $self = shift;

    my $log = get_logger();

    my $sql = qq( SELECT name
                FROM sqlite_master
                WHERE type = 'table';
    );

    my $table_list;
    try {
        $table_list = $self->{_dbh}->selectcol_arrayref($sql);
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $table_list;
}

sub has_feature_returning { 0 }

1;

=head1 SYNOPSIS

    use Tpda3::Db::Connection::Sqlite;

    my $db = Tpda3::Db::Connection::Sqlite->new();

    $db->db_connect($connection);

=head2 new

Constructor method.

=head2 db_connect

Connect to database

=head2 handle_error

Log errors.

=head2 parse_error

Parse a database error message, and translate it for the user.

=head2 table_info_short

Table info 'short'.

=head2 table_exists

Check if table exists in the database.

=head2 table_keys

Get the primary key field names of the table.

=head2 table_list

Return list of tables from the database.

=head2 has_feature_returning

Returns no for SQlite, meaning that is has not the INSERT... RETURNING
feature.

=cut
