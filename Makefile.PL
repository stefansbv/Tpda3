#
# Makefile.PL for Tpda3
#
# Copyright (C) 2010-2011  Stefan Suciu
# GNU General Public License v3
#

use 5.010;
use strict;
use warnings;

use inc::Module::Install;

name     'Tpda3';
all_from 'lib/Tpda3.pm';

requires 'perl'                       => '5.008005';
requires 'Config::General'            => '0';
requires 'YAML::Tiny'                 => '0';
requires 'Class::Unload'              => '0';
requires 'Class::Singleton'           => '1.4';
requires 'Class::Accessor'            => '0';
requires 'Try::Tiny'                  => '0.07';
requires 'SQL::Abstract'              => '1.68';
requires 'Log::Log4perl'              => '0';
requires 'Number::Compare'            => '0';
requires 'File::UserConfig'           => '0';
requires 'File::Find::Rule'           => '0.30';
requires 'File::HomeDir'              => '0.89';
requires 'File::Spec::Functions'      => '0';
requires 'DBI'                        => '1.53';

#- Tk

recommends 'Tk'                       => '804.028';
recommends 'Tk::ToolBar'              => '0.09';
recommends 'Tk::StatusBar'            => '0.04';
recommends 'Tk::MListbox'             => '1.11';
recommends 'Tk::JComboBox'            => '1.14';
recommends 'Tk::DateEntry'            => '1.39';
recommends 'Tk::TableMatrix'          => '1.23';
recommends 'Tk::RadiobuttonGroup'     => '0.2.2';

#- and/or Wx

recommends 'Wx'                       => '0.970101';
recommends 'Wx::Perl::ListCtrl'       => '0.03';

#- Database

recommends 'DBD::InterBase'           => '0.44';
recommends 'DBD::Pg'                  => '1.32';

test_requires 'Test::More'            => '0.47';
test_requires 'DBD::SQLite'           => '1.29';

install_share  'share';
install_script 'bin/tpda3';

WriteAll;
