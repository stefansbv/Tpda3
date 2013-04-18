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
