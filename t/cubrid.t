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
use lib 't/lib';
use DBIEngineTest;

use Tpda3::Target;

my $CLASS;
my $user;
my $pass;
my $tmpdir;
my $have_cubrid_driver = 1; # assume DBD::Cubrid is installed and so is Cubrid
my $live_testing   = 0;

# Is DBD::Cubrid realy installed?
try { require DBD::Cubrid; } catch { $have_cubrid_driver = 0; };

BEGIN {
    $CLASS = 'Tpda3::Engine::cubrid';
    require_ok $CLASS or die;
    $ENV{TPDA3_CONFIG}        = 'nonexistent.conf';
    $ENV{TPDA3_SYSTEM_CONFIG} = 'nonexistent.user';
    $ENV{TPDA3_USER_CONFIG}   = 'nonexistent.sys';
}

my $target = Tpda3::Target->new(
    uri => 'db:cubrid:foo',
);
isa_ok my $pg = $CLASS->new( target => $target ),
    $CLASS;

is $pg->uri->dbname, file('foo'), 'dbname should be filled in';

##############################################################################
# Can we do live tests?

my $dbh;
END {
    return unless $dbh;
    $dbh->{Driver}->visit_child_handles(sub {
        my $h = shift;
        $h->disconnect if $h->{Type} eq 'db' && $h->{Active} && $h ne $dbh;
    });

    $dbh->do('DROP DATABASE __tpda3test__') if $dbh->{Active};
}

my $err = try {
    $pg->use_driver;
    $dbh = DBI->connect('dbi:cubrid:dbname=template1', 'dba', '', {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
    });
    $dbh->do($_) for (
        'CREATE DATABASE __tpda3test__',
    );
    undef;
}
catch {
    eval { $_->message } || $_;
};

my $uri = 'db:cubrid://@localhost/__tpda3test__';
DBIEngineTest->run(
    class           => $CLASS,
    target_params   => [ uri => $uri ],
    skip_unless     => sub {
        my $self = shift;
        die $err if $err;
        1;
    },
    engine_err_regex => qr/^ERROR:  /,
    test_dbh         => sub {
        my $dbh = shift;

        # Check the session configuration...
    },
);

done_testing;
