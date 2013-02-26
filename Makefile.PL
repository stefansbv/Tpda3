#
# Makefile.PL for Tpda3
#
# Copyright (C) 2010-2012  Stefan Suciu
# GNU General Public License v3
#

use 5.008009;
use strict;
use warnings;

use inc::Module::Install;

name 'Tpda3';
all_from 'lib/Tpda3.pm';

requires 'perl'                  => '5.008005';
requires 'Regexp::Common'        => '0';
requires 'Config::General'       => '0';
requires 'YAML::Tiny'            => '0';
requires 'Class::Unload'         => '0';
requires 'Class::Singleton'      => '1.4';
requires 'Class::Accessor'       => '0';
requires 'Data::Compare'         => '0';
requires 'Data::Diver'           => '0';
requires 'Try::Tiny'             => '0.07';
requires 'Exception::Base'       => '0.2401';
requires 'SQL::Abstract'         => '1.68';
requires 'Log::Log4perl'         => '0';
#requires 'Log::Dispatch::FileRotate' => '0';
requires 'Number::Compare'       => '0';
requires 'List::Compare'         => '0';
requires 'List::MoreUtils'       => '0';
requires 'File::Path'            => '2.07';
requires 'File::UserConfig'      => '0';
requires 'File::Find::Rule'      => '0.30';
requires 'File::HomeDir'         => '0.89';
requires 'File::Spec::Functions' => '0';
requires 'File::Slurp'           => '0';
requires 'DBI'                   => '1.53';
requires 'Math::Symbolic'        => '0';
requires 'Tree::DAG_Node'        => '0';

#- Tk

requires 'Tk'                   => '804.028';
requires 'Tk::ToolBar'          => '0.09';
requires 'Tk::StatusBar'        => '0.04';
requires 'Tk::MListbox'         => '1.11';
requires 'Tk::JComboBox'        => '0';
requires 'Tk::DateEntry'        => '0';
requires 'Tk::TableMatrix'      => '1.23';
requires 'Tk::RadiobuttonGroup' => '0';

#- For generating PDF from TeX

requires 'IPC::Run3' => '0';
requires 'Template'  => '0';

#- and/or Wx - Experimental

eval { require Wx; };
unless ($@) {
    requires 'Wx'                 => '0.970101';
    requires 'Wx::Perl::ListCtrl' => '0.03';
}

#- Database

#-- One of this is required for full functionality ...

recommends 'DBD::Pg'       => '1.32';
recommends 'DBD::Firebird' => '0.80';

test_requires 'Test::More'          => '0.47';
#test_requires 'Test::FailWarnings'  => '0.001';
test_requires 'DBD::SQLite'         => '1.29';
recommends    'Test::Pod::Coverage' => '0';
recommends    'Test::CheckManifest' => '0';

install_share 'share';
install_script 'bin/tpda3';

WriteAll;

#- end
