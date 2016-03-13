package DBIEngineTest;
#
# Adapted from Sqitch by theory.
#
# Changed to to use only ASCII because of:
# Wide character in print at lib/site_perl/5.14.4/Test/Builder.pm line 1826.
# when is_deeply reports failure
#
use 5.010;
use strict;
use warnings;
use utf8;
use Try::Tiny;
use Test::Most;
use Test::MockModule;
use Path::Class 0.33 qw(file dir);
use Locale::TextDomain qw(Tpda3);

# use Tpda3::Config;

# Just die on warnings.
use Carp; BEGIN { $SIG{__WARN__} = \&Carp::confess }

sub run {
    my ( $self, %p ) = @_;

    my $class           = $p{class};
    #my $mock_transfer   = Test::MockModule->new('Tpda3');

    can_ok $class, qw(
        get_info
        table_exists
    );

    subtest 'live database' => sub {

        ok my $target = Tpda3::Target->new(
            @{ $p{target_params} || [] },
        ), 'new target';
        isa_ok $target, 'Tpda3::Target', 'target';

        ok my $engine = $class->new(
            target   => $target,
            @{ $p{engine_params} || [] },
        ), 'new engine';
        if (my $code = $p{skip_unless}) {
            try {
                $code->( $engine ) || die 'NO';
            } catch {
                plan skip_all => sprintf(
                    'Unable to live-test %s engine: %s',
                    $class->name,
                    eval { $_->message } || $_
                );
            };
        }

        ok $engine, 'Engine instantiated';

        throws_ok { $engine->dbh->do('INSERT blah INTO __bar_____') }
            'Tpda3::X',
            'Database error should be converted to Tpda3 exception';
        is $@->ident, $class->key, 'Ident should be the engine';
        ok $@->message, 'The message should be from the translation';


        #######################################################################
        # Test the database connection, if appropriate.
        if ( my $code = $p{test_dbh} ) {
            $code->( $engine->dbh );
        }


        #######################################################################

        # Test begin_work() and finish_work().
        can_ok $engine, qw(begin_work finish_work);
        my $mock_dbh
            = Test::MockModule->new( ref $engine->dbh, no_auto => 1 );
        my $txn;
        $mock_dbh->mock( begin_work => sub { $txn = 1 } );
        $mock_dbh->mock( commit     => sub { $txn = 0 } );
        $mock_dbh->mock( rollback   => sub { $txn = -1 } );
        my @do;
        $mock_dbh->mock(
            do => sub {
                shift;
                @do = @_;
            }
        );
        ok $engine->begin_work, 'Begin work';
        is $txn, 1, 'Should have started a transaction';
        ok $engine->finish_work, 'Finish work';
        is $txn, 0, 'Should have committed a transaction';
        ok $engine->begin_work, 'Begin work again';
        is $txn, 1, 'Should have started another transaction';
        ok $engine->rollback_work, 'Rollback work';
        is $txn, -1, 'Should have rolled back a transaction';
        $mock_dbh->unmock('do');


        ######################################################################
        if ($class eq 'Tpda3::Engine::pg') {
            # Test someting specific for Pg
        }


        ######################################################################
        # Test get_info

        my @fields_info = (
            [ 'field_01', 'char(1)' ],
            [ 'field_02', 'date' ],
            [ 'field_03', 'integer' ],
            [ 'field_04', 'numeric(9,3)' ],
            [ 'field_05', 'smallint' ],
            [ 'field_06', 'varchar(10)' ],
        );

        my $fields_list = join " \n , ", map { join ' ', @{$_} } @fields_info;
        my $table_info  = 'test_info';

        my $ddl = qq{CREATE TABLE $table_info ( \n   $fields_list \n);};

        ok $engine->dbh->do($ddl), "create '$table_info' table";

        ok my $info = $engine->get_info($table_info), 'get info for table';
        foreach my $rec (@fields_info) {
            my ($name, $type) = @{$rec};
            $type =~ s{\(.*\)}{}gmx;       # just the type
            $type =~ s{\s+precision}{}gmx; # just 'double'
            $type =~ s{bigint}{int64}gmx;  # made with 'bigint' but is 'int64'
            is $info->{$name}{type}, $type, "type for field '$name' is '$type'";
        }


        ######################################################################

        ######################################################################
        # All done.
        done_testing;
    };
}

1;
