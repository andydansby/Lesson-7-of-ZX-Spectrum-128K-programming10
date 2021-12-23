cd utils
    copy "pasmo.exe" "..\RAM1"
    copy "pasmo.exe" "..\RAM3"
    copy "pasmo.exe" "..\RAM4"
    copy "pasmo.exe" "..\RAM6"

    copy "bin2tap.exe" "..\RAM1"
    copy "bin2tap.exe" "..\RAM3"
    copy "bin2tap.exe" "..\RAM4"
    copy "bin2tap.exe" "..\RAM6"
cd ..

cd RAM1
    rem call ram1.bat
cd ..

cd RAM3
    rem call ram3.bat
cd ..

cd RAM4
    call ram4.bat
cd ..

cd RAM6
    call ram6.bat
cd ..
