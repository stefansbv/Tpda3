#
# Tpda3::Generator test script
#

use strict;
use warnings;

use Cwd;
use File::Spec::Functions;
use IPC::System::Simple 1.17 qw(capture);
use Try::Tiny;
use Test::More;
use File::Which ();

use lib qw( lib ../lib );

require Tpda3::Config;

my $cwd        = Cwd::cwd();
my $model_file = catfile( $cwd, qw{t tex model test.tt} );
my $out_path   = catdir( $cwd, qw{t tex output} );

BEGIN {
    eval {
        require Tpda3::Generator;
    };
    if ($@) {
        plan( skip_all => 'pdflatex is required for this test' );
    }
    else {
        plan tests => 4;
    }
}

END {
    # Cleanup
    foreach my $file (qw{test.aux test.log test.pdf test.tex}) {
        my $tmpfile = catfile($out_path, $file);
        unlink $tmpfile if -f $tmpfile;
    }
}

my $args = {
    cfname => 'test-tk',
    user   => 'user',
    pass   => 'pass',
    cfpath => 't/',
};

my $c1 = Tpda3::Config->instance($args);
ok( $c1->isa('Tpda3::Config'), 'created Tpda3::Config instance 1' );

ok(my $gen = Tpda3::Generator->new(), 'new Generator');

#--

my $record = [
    {   'data' => {
            name1 => 'Muskehounds',
            name2 => 'Top Cat',
            init2 => 'T.C.',
        },
        'metadata' => {
            'table' => 'v_contracte_imobil',
            'where' => { 'id_contr' => '1' }
        }
    }
];

ok( my $tex_file = $gen->tex_from_template( $record, $model_file, $out_path ),
    'Generate LaTeX from template' );

SKIP: {
    skip "pdflatex is required for this test", 1
        unless $gen->find_pdflatex();
    ok( $gen->pdf_from_latex( $tex_file, $out_path ),
        'Generate PDF from LaTeX' );
}

# end test
