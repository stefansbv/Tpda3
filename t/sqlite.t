#!perl -w
##
use strict;
use warnings;
use 5.010;
use Test::More;
use Path::Class;
use Try::Tiny;
use Test::Exception;
use File::Spec::Functions;
use File::Temp 'tempdir';
use lib 't/lib';
use DBIEngineTest;
use Locale::TextDomain 1.20 qw(Tpda3);
use Tpda3::Target;

my $CLASS;
my $user;
my $pass;
my $tmpdir;
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

    $tmpdir = File::Spec->tmpdir();
}

my $target = Tpda3::Target->new(
    uri => 'db:sqlite:foo.db',
);
isa_ok my $sqlite = $CLASS->new( target => $target ),
    $CLASS;

is $sqlite->uri->dbname, file('foo.db'), 'dbname should be filled in';

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

my $tmp_dir = Path::Class::dir( tempdir CLEANUP => 1 );
my $db_name = $tmp_dir->file('sqitch.db');
my $alt_db  = $db_name->dir->file('sqitchtest.db');

DBIEngineTest->run(
    class         => $CLASS,
    engine_params => [options => {
        top_dir => Path::Class::dir(qw(t engine))->stringify,
        engine  => 'sqlite',
    }],
    target_params => [ uri => URI->new("db:sqlite:$db_name") ],
    skip_unless    => sub {
        my $self = shift;

        # Should have the database handle
        $self->dbh;

        # Make sure we have a supported version.
        my $version = $self->dbh->{sqlite_version};
        my @v = split /[.]/ => $version;
        die "SQLite >= 3.7.11 required; DBD::SQLite built with $version\n"
            unless $v[0] > 3 || ($v[0] == 3 && ($v[1] > 7 || ($v[1] == 7 && $v[2] >= 11)));
    },
    engine_err_regex  => qr/^near "blah": syntax error/,
    init_error        =>  __x(
        'Sqitch database {database} already initialized',
        database => $alt_db,
    ),
    test_dbh => sub {
        my $dbh = shift;
        # Make sure foreign key constraints are enforced.
        ok $dbh->selectcol_arrayref('PRAGMA foreign_keys')->[0],
            'The foreign_keys pragma should be enabled';
    },
);

done_testing;
