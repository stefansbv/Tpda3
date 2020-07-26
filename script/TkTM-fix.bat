REM Fix compile errors for TK::TableMatrix
REM FRom: https://www.perlmonks.org/?node_id=1228529
REM Not tested as script!, only as individual command in cpan look shell
REM

cd .\blib\arch 

md Tk
md Tk\pTk
md Tk\pTk\compat
md Tk\X11

echo > Tk\pTk\.exists
echo > Tk\pTk\compat\.exists
echo > Tk\X11\.exists
