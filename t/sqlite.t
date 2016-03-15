#!perl -w
##
use strict;
use warnings;
use 5.010;
use Test::More;
use Path::Tiny;
use File::Temp 'tempdir';
use Try::Tiny;
use Test::Exception;
use Locale::TextDomain 1.20 qw(Tpda3);
use Tpda3::Target;
use lib 't/lib';
use DBIEngineTest;

my $CLASS;
my $have_sqlite_driver = 1; # assume DBD::SQLite is installed and so is SQLite
my $live_testing       = 0;

# Is DBD::SQLite realy installed?
try { require DBD::SQLite; } catch { $have_sqlite_driver = 0; };

BEGIN {
    $CLASS = 'Tpda3::Engine::sqlite';
    require_ok $CLASS or die;
    $ENV{TPDA3_CONFIG}        = 'nonexistent.conf';
    $ENV{TPDA3_SYSTEM_CONFIG} = 'nonexistent.user';
    $ENV{TPDA3_USER_CONFIG}   = 'nonexistent.sys';
}

my $target = Tpda3::Target->new(
    uri => 'db:sqlite:foo.db',
);
isa_ok my $sqlite = $CLASS->new( target => $target ),
    $CLASS;

is $sqlite->uri->dbname, path('foo.db'), 'dbname should be filled in';

##############################################################################
# Can we do live tests?

END {
    my %drivers = DBI->installed_drivers;
    for my $driver (values %drivers) {
        $driver->visit_child_handles(sub {
            my $h = shift;
            $h->disconnect if $h->{Type} eq 'db' && $h->{Active};
        });
    }
}

my $tmp_dir = path( tempdir CLEANUP => 1 );
my $db_path = path( $tmp_dir, 'tpda3test.db' );
my $uri = "db:sqlite:$db_path";
DBIEngineTest->run(
    class         => $CLASS,
    target_params => [ uri => $uri ],
    skip_unless   => sub {
        my $self = shift;

        # Should have the database handle
        $self->dbh;
    },
    engine_err_regex  => qr/^near "blah": syntax error/,
    test_dbh => sub {
        my $dbh = shift;
        # Make sure foreign key constraints are enforced.
        ok $dbh->selectcol_arrayref('PRAGMA foreign_keys')->[0],
            'The foreign_keys pragma should be enabled';
    },
);

done_testing;
