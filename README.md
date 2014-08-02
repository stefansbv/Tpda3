Tpda3 (Tiny Perl Database Application 3)
========================================
Ștefan Suciu <stefan@s2i2.ro>
2014-08-02

Version: 0.90

Copyright (C) 2010-2014  Stefan Suciu
GNU General Public License v3

Tpda3 is a classic desktop database application framework and
run-time, written in Perl.  The graphical user interface is based on
PerlTk. It supports the CUBRID, Firebird, PostgreSQL and SQLite RDBMS.

There is also an experimental, graphical user interface based on wxPerl.


Requirements
------------

- Perl v5.8.9 or newer. For full UTF support is recomended at least v5.10.1

- SQLite (required for testing);
- PostgreSQL version 8.2 or greater;
  or
- Firebird version 2.1 or greater
  (Because of the "INSERT ... RETURNING" SQL statement, feature);
  or
- CUBRID version 8.4;

- Operating System

Tpda3 should work on any OS where Perl and the required dependencies
can be installed, but currently it's only tested on GNU/Linux and
Windows (XP and 7).  Feedback and patches for other OSs is welcome.

Tpda3 is the successor of TPDA and, hopefully, has a much better API
implementation, Tpda3 follows the Model View Controller (MVC)
architecture pattern.  The look and the user interface functionality
of Tpda3 is almost the same as of TPDA, with some minor improvements.

The configuration files formats are new and are in YAML (YAML::Tiny)
and Apache format (Config::General).


Installation
------------

Because Tpda3 uses a few modules that need to be patched, the best way
to install is from Stratopan.  This is a good time to say to the
Stratopan team: thank you for a great service!

cpanm --mirror https://stratopan.com/stefansbv/Tpda3/master --mirror-only Tpda3


Troubleshooting
---------------

See README.trouble. There is a new dir on SF with some patched modules.


Links
-----

Home page:

http://tpda.s2i2.ro/

Development takes place, currently, on GitHub:

https://github.com/stefansbv/Tpda3/

The project page on SourceForge:

https://sourceforge.net/projects/tpda/


License And Copyright
---------------------

Copyright (C) 2010-2014 Ștefan Suciu

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
