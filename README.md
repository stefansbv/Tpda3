Tpda3 (Tiny Perl Database Application 3)
========================================
Ștefan Suciu
2022-11-28

Version: 1.000

Tpda3 is a classic desktop database application framework and
run-time, written in Perl.  The graphical user interface is based on
PerlTk. It supports the CUBRID, Firebird, PostgreSQL and SQLite RDBMS.

There is also an experimental graphical user interface based on wxPerl.

Tpda3 is the successor of TPDA and, hopefully, has a much better API
implementation, Tpda3 follows the Model View Controller (MVC)
architecture pattern.  The look and the user interface functionality
of Tpda3 is almost the same as of TPDA, with some minor improvements.

The configuration files formats are new and are in YAML (YAML::Tiny)
and Apache format (Config::General).


Requirements
------------

- Perl v5.10.1 or newer.

- A database, one or more of the following:
  * SQLite (required for testing);
  * PostgreSQL version 8.2 or greater (using DBD::Pg)
  * Firebird version 2.1 or greater (using DBD::Firebird or DBD::ODBC)
  * CUBRID version 8.4 (using DBD::cubrid);

- The Operating System

Tpda3 should work on any OS where Perl and the required dependencies
can be installed, but currently it's only tested on GNU/Linux and
Windows (XP, 7 and 10).  Feedback and patches for other OSs are
welcome.


Installation
------------

Download the distribution, unpack and install:

    % tar xaf Tpda3-0.NN.tar.gz
    % cd Tpda3-0.NN

Then as usual for a Perl application:

    % perl Makefile.PL
    % make
    % make test
    % make install

For testing the application without installation, after 'make' one can use:

    % perl -Mblib bin/tpda3 [options] ...`

Only make install should be run as root.


### Usage

After installing the application, at first start, the configuration
directory is initialized automatically.  The following command will
list all the defined application configurations.

    % tpda3 -l

On a fresh installation this command should return:

    test-tk
    test-wx

Run the demo application with:

    % tpda3 test-tk


Troubleshooting
---------------

Note: There is a dir on SF with some patched modules that can fix all
this problems, and also the modules can be installed from
stratopan.com.

Problems and their fix, listed here for reference:

_Problem_: Tk::Error: unknown color name "systembuttonface"

_Fix_: remove the option '-systembuttonface' from Tk::StatusBar module

_Problem_: In Perl 5.10.0 on Slackware 12.2 the module MListbox throws
an error like: XS_Tk__Callback_Call error:Not a CODE reference at \
/usr/lib/perl5/site_perl/5.10.0/Tk/MListbox.pm line 703.  Similar
error on ActivePerl5.10.0 build 1004.

_Fix_: Fortunately there is a fix on the ActiveState forum (thanks to
RobSeegel):

Go into the MListbox code, and replace all references of
 `$w->can('SUPER::`
with
 `$w->can('Tk::Listbox::`

_Problem_: Tk::Error: Can't set -state to `normal' for
Tk::JComboBox=HASH(0x930c6a8): Cannot use undef value for object of
type 'color' at /usr/lib/perl5/site_perl/5.10.0/Tk/JComboBox.pm line
1061.

_Fix_: There is a patch on PerlMonks (Thank you lamprecht!)
http://www.perlmonks.com/?node_id=799099


Links
-----

Home page:

http://stefansuciu.ro/tpda3/

Development takes place, currently, on GitHub:

https://github.com/stefansbv/Tpda3/

The project page on SourceForge:

https://sourceforge.net/projects/tpda/


License And Copyright
---------------------

Copyright (C) 2010-2022 Ștefan Suciu

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
