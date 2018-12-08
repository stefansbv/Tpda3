## 0.99.11  (2018-12-08)

- Bugfix
  - Allow absolute path for SQLite dbname in the config

## 0.99.10  (2018-11-10)

- Feature
  - Allow a hash for the filter option for entry bindings
  - Add order option to the screen entry binding section
  - Implement embeded widgets in TM (jcombobox and dateentry);
- Bugfix
  - Croak on missing parameters, iterate on the TM fields not the record fields;

## 0.99.9  (2018-02-28)

- Features
  - Add SQL::Abstract special_op for Pg match: ~

## 0.99.8  (2018-02-27)

- Features
  - Add SQL::Abstract special_op for similar_to
  - Add method for "select from f()" (tested with Pg) - query_exec_proc;
  - Allow empty table bindings;
  - Add the column param to the query (query_filter_find);
- Bugfix
  - Fix set_status, revert change of config call for the else branch

## 0.99.7  (2018-01-09)

- Features
  - Deprecate 'subname' in tablebindings, replace with 'method';
  - Enable controls (entry) for report style screen;

## 0.99.6  (2017-11-16)

- Features
  - Call an 'on_record_loaded' method in screens if is defined.
    The purpose is to enable/disable controls depending on some other field values;
  - Add new dialog for Text;
  - Add/use new runtime vars: docsbasepath, docsoutpath;
- Bugfix
  - Add a warning for missing 'id' in attribs;

## 0.99.3   (2017-04-05)

- Bugfix

## 0.99.2   (2017-04-02)

- Bugfix

## 0.99.1   (2017-02-19)

- Bugfix
  - Ignore missing toolbar buttons.

## 0.99   (2016-12-06)

- Changes
  - Remove plan from screen tests.  Important - must update all screen tests!

## 0.98.8 (2016-01-29)

- Changes
  - Tpda3::Tk::Text - rename the widget.

## 0.98.7 (2015-06-10)

- Changes
  - Add an optional 'ib_role' config to the Firebird connection.
- Bugfix
  - Fix issue #8 Toolbar button stay disabled when switching from a
    screen that alters the default states.
  - Fix message, update ro translations.

## 0.98.5 (2015-05-26)

- Bugfix
  - Fix save geometry.
- Changes
  - Sync Wx menus and toolbar code with Tk.

## 0.98.1 (2015-01-13)

- Features
  - A default in screen method for altering the record passed to TT.
- Bugfix
  - Fix the too many parameters error from Report Manager's printrep.


## 0.98 (2014-10-22)

- Changes
  - Refactor and fix the configs dialog.
  - Refactor system call in Repman dialog.
- Bugfix
  - Fix TTGen dialog.
  - Fix Text entry coding, add bg color to param entries.
  - Remove setlocale, revert to allow only point (.) as decimal separator.
  - Use the short form for setting ISO time in Firebird.pm.
  - Add a delay param in screen test sub, for slower systems.


## 0.96 (2014-09-18)

- Changes
  - Use the Basic plugin bundle in disi.ini.
  - Update the translation files.


## 0.95 (2014-09-09)

- Bugfix
  - Fix bug in the Orders screen (old API syntax leftover).
- Changes
  - Add Tk::JFileDialog as requirement to dist.ini.
  - Remove the Tk Help module, adapt POSs for dzil, fix load_conf
  - Add the menubar and toolbar methods in the config.
  - Check if the 'get_template_datasources' method returns a hashref.
  - Move POD to the end of the files.
  - Ignore DistZilla produces files (Árpád Szász)
- Features (provided by Árpád Szász. Thanks!)
  - Add PerlApp support


## 0.94 (2014-09-01)

- Bugfix
  - Fix bug #5.
  - PerlApp project files


## 0.90 (2014-08-02)

- Bugfix
  - Do not reload detail tab data if already loaded. Fix for the #3 bug.
  - Cleanup READMEs.


### 0.89 (2014-07-22)

- Features
  - Implement table_info_short and table_keys for SQLite.
- Bugfix
  - Fix file move in Tpda::Generator.
  - Datasources - common data table is not required for templates.
- Changes
  - Refactor extract_tt_fields from Tpda3/Generator.


## 0.88 (2014-06-15)

- Features
  - Add administrator.yml used to disable menus by name.

## 0.87 (2014-06-14)

- Bugfix
  - Fix loading detail data for templates.


## 0.86 (2014-05-31)

- Changes
  - Remove Log::Dispatch::FileRotate from required.


## 0.85 (2014-05-31)

- Features
  - Add method to config for loading a .yaml or .conf file and return a Perl DS.
- Changes
  - Add the Tpda3 system tables to the Fb, Pg and SQLite schemas.


## 0.84 (2014-04-16)

- Changes
  - Refactor TemplDet screen, update Reports and Templates screens.


## 0.83 (2014-04-12)

- Features
  - Make TM in Details tab
  - Detail screen for template vars.
  - Add method to ::Tk::Screen to check if it's a tool screen.
  - Add method to extract fields from templates to Generator.
- Changes
  - TTGen screen changes.
  - Change table name in conf.
  - Add sequence_list method.
- Bugfix
  - Fix regexp to match full date strings, update test.
  - Convert format of dates from ISO to configured, for generated documents.
  - Fix utf8 problems when the ODBC driver is used.


## 0.82 (2014-04-08)

- Changes
  - Replace 'each' with 'foreach' globally;
  - Refactor document generation code.
  - Add message dialog to TTGen, configure fields.
- Bugfix
  - Fix image path for Windows.
  - Use short paths on Windows.
  - Fix utf8 encoding problems in generated TeX document.


## 0.81 (2014-04-06)

- Changes
  - Remove Log::Dispatch::FileRotate, does not work.
  - Simplify code in Firebird.pm
  - Guess the app distribution name.
- Features
  - Add dialog and screen for Templates.
  - Add info methods to the OdbcFb module.
  - Generator new parameter: suffix, for generated pdf name.


## 0.80 (2014-03-09)

- Features
  - Allow Tk::Checkbutton to have other off/on values; not tested.
  - Add ODBC support using Firebird
- Changes
  - Increase config version number to v5
  - Add proper localization using gettext and switch to Dist::Zilla.
  - Implement Table module to keep track of keys and values using Mouse.
  - Add test for Model::Table; update the module.
  - Switch to IPC::System::Simple for RepMan preview
  - Remove localisation configs from main.yml
  - Remove Words TT plugin
  - Sync Wx implemetation with Tk
  - Use Git::CommitBuild plugin.
  - Move Wx tests to a lib


## 0.69 (2013-10-19)

- Bugfix
  - Switch to JFileDialog
  - Refactor the PDF generation module
  - Miscelaneous fixes
- Features
  - Replace the old help module with a manual in CHM format for all platforms
  - Small advance for the Wx implmentation


## 0.68 (2013-05-09)

- Features
  - Check for widget type before read / write (Tk) and report fields
    with inconsistent configuration - devel tool.
  - Wx GUI improvements.


## 0.67 (2013-04-13)

- Bugfix
  - Miscelaneous fixes and changes
- Features
  - When the test database is created, load the data in the tables.
- Docs
  - Update manuals in htb and chm format and PODs.


## 0.66 (2013-04-03)

- Docs
  - Update docs.
- Feature
  - Change 2 icons - new icons for copy and paste.
- Other
  - Wx GUI experimentes.


## 0.65 (2013-02-15)

- Bugfix
  - Fix search of type CONTAINING specific to Firebird.
  - Fix inconsistent usage of $pkcol as string vs hash ref.
  - Fix Select dialog and it's bindings.
  - Increase delay at close for tk tests;
- Changes
  - Move some menu itms from app to the new Admin menu.
  - Start chm help viewer on Win instead of guide dialog.
- Docs
  - Update configs reference docs.


## 0.64 (2013-02-18)

- Bugfix
  - Fix message dialogs (Tk).


## 0.63 (2013-02-06)

- Feature
  - Pick a default mnemonic when one is not set.
  - Exception for RepMan's print preview command.
  - Dialogs layout change - remove toolbar;
  - Implement update main.yml.
- Docs
  - Update PODs.
  - Translate and update user guide.
- Bugfix
  - Fix creating new records with provided PK key.
  - Fix error when no title provided.
  - Fix problem with encodings in list header and items.
- Features
  - New Exceptions for IO.
  - Message dialog on file/path exceptions.
  - Add experimental methods to check file and path and throw exceptions.
  - Update method params for the Message dialog.
  - Add new strings to localisation configs.
  - Refactor Config::Screen using the Data::Diver module.
  - Add commented code to fetch all keys.
  - Fix helper method in Cubrid.pm.
  - Rise 'not connected' exception when appropriate.
  - Add color to login dialog message.
  - Use last_insert_id as alternative to insert... returning.
  - Deal with connection errors; Add table list method.
  - Add CUBRID support, initial import.
  - Use Tpda3::Exceptions, remove Ouch.


## 0.61 (2012-12-29)

- Bugfix
  - Fallback to share dir from the dist for copying user data.
- Configuration file change
  - Move attributes form main.yml into code.
- Features
  - Configuration dialog for external apps.


## 0.60 (2012-12-02)

See ChangeLog...
