#
# Makefile.PL for Tpda3
#
# Copyright (C) 2010  Stefan Suciu
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
requires 'DBD::InterBase'             => '0.44';
requires 'DBD::Pg'                    => '1.32';
requires 'DBD::mysql'                 => '4.004';
requires 'Tk'                         => '804.028';
requires 'Tk::ToolBar'                => '0.09';
requires 'Tk::StatusBar'              => '0.04';
requires 'Tk::MListbox'               => '1.11';
requires 'Tk::JComboBox'              => '1.14';
requires 'Tk::DateEntry'              => '1.39';
requires 'Tk::TableMatrix'            => '1.23';
requires 'Tk::RadiobuttonGroup'       => '0.2.2';
requires 'Tk::FontDialog'             => '0.15';

build_requires 'Test::More'           => '0.47';

install_share  'share';
install_script 'bin/tpda3';

WriteAll;
