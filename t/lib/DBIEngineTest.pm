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
use Log::Log4perl;
use Locale::TextDomain qw(Tpda3);

# Just die on warnings. Init logger.
use Carp; BEGIN {
    $SIG{__WARN__} = \&Carp::confess;
    Log::Log4perl->init('t/log.conf');
}

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
            'Exception::Db::SQL',
            'Database error should be converted to Tpda3 exception';
        ok $@->usermsg, 'The message should be from the translation';


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

        throws_ok { $engine->get_info() }
            qr/\QMissing required arguments: table/,
            'Should get an exception for missing table param';


        ######################################################################
        # Test table_keys

        my $ddl1 = <<'END_SQL';
        CREATE TABLE reports (
           id_rep       INTEGER NOT NULL
         , id_user      INTEGER
         , repofile     VARCHAR(150)
         , title        VARCHAR(50)
         , descr        VARCHAR(250)
         , CONSTRAINT pk_reports_id_rep PRIMARY KEY (id_rep)
        );
END_SQL

        my $ddl2 = <<'END_SQL';
        CREATE TABLE reports_det (
           id_rep       INTEGER      NOT NULL
         , id_art       INTEGER      NOT NULL
         , hint         VARCHAR(15)  NOT NULL
         , tablename    VARCHAR(25)  NOT NULL
         , searchfield  VARCHAR(25)  NOT NULL
         , resultfield  VARCHAR(25)  NOT NULL
         , headerlist   VARCHAR(50)  NOT NULL
         , CONSTRAINT pk_reports_det_id_rep PRIMARY KEY (id_rep, id_art)
         , CONSTRAINT fk_reports_det_id_rep FOREIGN KEY (id_rep)
               REFERENCES reports (id_rep)
                   ON DELETE CASCADE
                   ON UPDATE CASCADE
        );
END_SQL

        ok $engine->dbh->do($ddl1), "create 'reports' table";
        ok $engine->dbh->do($ddl2), "create 'reports_det' table";

        ok my $pkeys1 = $engine->table_keys('reports'), 'get PK keys for table';
        is_deeply $pkeys1, ['id_rep'], 'PK keys match';

        ok my $pkeys2 = $engine->table_keys('reports_det'),
            'get PK keys for table';
        is_deeply $pkeys2, ['id_rep', 'id_art'], 'PK keys match';

        if ($class eq 'Tpda3::Engine::sqlite') {
            ok my $fkeys2 = $engine->table_keys('reports', 'reports_det'),
                'get FK keys for table';
        }
        else {
            ok my $fkeys2 = $engine->table_keys('reports_det', 'foreign'),
                'get FK keys for table';
            is_deeply $fkeys2, ['id_rep'], 'FK keys match';
        }

        throws_ok { $engine->table_keys() }
            qr/\QMissing required arguments: table/,
            'Should get an exception for missing table param';


        ######################################################################
        # Test table_list

        ok my $tables = $engine->table_list, 'get table list';
        is_deeply $tables, ['test_info', 'reports', 'reports_det'],
            'table list match';


        ######################################################################
        # Test has_feature_returning

        my $has_feature = {
            firebird => 1,
            sqlite   => 0,
            pg       => 1,
        };

        is $engine->has_feature_returning, $has_feature->{ $engine->key },
            'test has_feature_returning';


        ######################################################################
        # Test get_columns

        my $colslist = [qw(field_01 field_02 field_03 field_04 field_05 field_06)];

        ok my $cols = $engine->get_columns($table_info), 'get table list';
        is_deeply $cols, $colslist, 'cols list match';

        throws_ok { $engine->get_columns() }
            qr/\QMissing required arguments: table/,
            'Should get an exception for missing table param';


        ######################################################################
        # Test table_exists

        ok $engine->table_exists($table_info), "table $table_info exists";

        throws_ok { $engine->table_exists() }
            qr/\QMissing required arguments: table/,
            'Should get an exception for missing table param';


        ######################################################################
        # All done.
        done_testing;
    };
}

1;
