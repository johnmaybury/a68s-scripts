echo off

rem em_ headers

set location=%CD%
cd ..\..
\lua\lua515 modules/src/em_data/make_flag_c.lua < h\em_table > h\em_flag.c
\lua\lua515 modules/src/em_data/make_mnem_c.lua < h\em_table > h\em_mnem.c
\lua\lua515 modules/src/em_data/make_mnem_h.lua < h\em_table > h\em_mnem.h
\lua\lua515 modules/src/em_data/make_pseu_c.lua < h\em_table > h\em_pseu.c
\lua\lua515 modules/src/em_data/make_pseu_h.lua < h\em_table > h\em_pseu.h
\lua\lua515 modules/src/em_data/make_spec_h.lua < h\em_table > h\em_spec.h
rem \lua\lua515 modules/src/em_data/make_mnem_h.lua < h\em_table > h\em_mnem.h
rem \lua\lua515 modules/src/em_data/make_pseu_h.lua < h\em_table > h\em_pseu.h
rem \lua\lua515 modules/src/em_data/make_spec_h.lua < h\em_table > h\em_spec.h
cd %location%

set ACK_SYS=%1
if    %ACK_SYS%. == . (
    echo system not specified on the command line.
    echo choose one of: pdp vax4 sun3 moon3 m68000 m68020 m68k2 cyber perq temp
    exit /b 7
)
set ACM=%ACK_SYS%
if    %ACK_SYS% == pdp_v7       set ACM=pdp
if    %ACK_SYS% == pdp_v7       set BM=0
if    %ACK_SYS% == vax_bsd4_1a  set ACM=vax4
if    %ACK_SYS% == vax_bsd4_2   set ACM=vax4
if    %ACK_SYS% == vax_sysV_2   set ACM=vax4
if    %ACK_SYS% == pc_ix        set ACM=i86
if    %ACK_SYS% == pc_ix        set BM=0
if    %ACK_SYS% == sun3         set ACM=sun3
if    %ACK_SYS% == sun2         set ACM=sun2
if    %ACK_SYS% == m68_unisoft  set ACM=m68k2
if    %ACK_SYS% == m68_sysV_0   set ACM=mantra

if exist last_ysed_build.bat copy /Y last_ysed_build.bat prev_used_build.bat
copy /Y build.bat                    last_used_build.bat

set PBASE=\p5\p2c-master
set PINCLUDE=%PBASE%
set PLIBRARY=%PBASE%

set CC=\tcc\tcc
set PC=%PBASE%\p2c.exe
set FP=\FPC\3.2.2\bin\i386-win32\fpc

if not exist bin mkdir bin
if not exist tmp mkdir tmp

echo x                          > tmp\x
del  /Q                           tmp\*

echo AnsiC            1         > tmp\_general.p2crc
echo BracesAlways     1        >> tmp\_general.p2crc
echo PreserveTypes    1        >> tmp\_general.p2crcs
rem echo CharSize         8        >> tmp\_general.p2crc
rem echo ShortSize       16        >> tmp\_general.p2crc
rem echo IntSize         32        >> tmp\_general.p2crc
rem echo LongSize        64        >> tmp\_general.p2crc
rem echo PtrSize         32        >> tmp\_general.p2crc
rem echo FloatSize       32        >> tmp\_general.p2crc
rem echo DoubleSize      64        >> tmp\_general.p2crc
rem echo Packing          0        >> tmp\_general.p2crc
rem echo Packing          1        >> tmp\_general.p2crc
rem echo Packing          2        >> tmp\_general.p2crc
echo ConstFormat  CONST_%%s    >> tmp\_general.p2crc
rem echo EnumFormat   %%S_%%_s     >> tmp\_general.p2crc
echo PhysTabSize      0        >> tmp\_general.p2crc
echo ElimDeadCode     0        >> tmp\_general.p2crc
rem we don't set PascalSignif to 8, that is handled by prePascal.awk/ppp.awk

copy /Y %PLIBRARY%\libp2c.dll    bin

set P2CGENERAL=-c tmp\_general.p2crc

set CFAIL=

rem set RBL=awk -f removeBlankLines.awk
set RBL=awk -f pp2.awk
rem set PPP=awk -f prePascal.awk
set PPP=awk -f ppp.awk
set PPC=awk -f ppc.awk

%PPP% -v src=util/tailor.p -v RC=tmp/tailor.p2crc        > tmp\_tailor.p
type tmp\_general.p2crc                                 >> tmp\tailor.p2crc
%PC% tmp\_tailor.p -o  tmp\tailor.ct -c tmp\tailor.p2crc
awk  -f fixtailor.awk  tmp\tailor.ct  > tmp\tailor.c
%CC% -o bin\tailor.exe -I%PINCLUDE% tmp\tailor.c mustopen.c bin\libp2c.dll
if errorlevel 1 set CFAIL=%CFAIL%tailor;

set TAILOR=bin\tailor.exe

echo ACM: %ACM%; BM: %BM%

set MACH=%ACM%

rem default to not a BSD4 system, have floating point, 32-bit word and pointers
set BSD4=
set NOFLOAT=0
set W=4
set P=4
set RECIPE=112 13 119
set cg=123 24 125
set init5=init5
set cybOption=

rem in the original Makefile, 174 was used for most a68sdec.p tailors but that
rem causes OPIDBLK to have the "wrong" declaration in some init programs which
rem are no-longer separate
rem similarly for 171, 172, 173, 176, 177, 178
set N71=71
set N72=72
set N73=73
set N74=74
set N76=76
set N77=77
set N78=78

rem set machine specifica
if      %MACH%. == pdp.      (
   set W=2
   set P=2
   set RECIPE=12 13 119
) else if %MACH%. == m68k2.  (
   set W=2
   set P=4
   set RECIPE=12 113 19
) else if %MACH%. == moon3.  (
   set W=2
   set P=4
   set RECIPE=12 113 19
   set BSD4=-DBSD4
) else if %MACH%. == m68020. (
   set skip=
) else if %MACH%. == m68000. (
   set skip=
) else if %MACH%. == sun3.   (
   set BSD4=-DBSD4
) else if %MACH%. == vax4.   (
   set BSD4=-DBSD4
) else if %MACH%. == perq.   (
   set BSD4=-DBSD4
   set cg=123 124 125
   set init5=perqcod
) else if %MACH%. == cyber.  (
   set BSD4=-DBSD4
   set cg=123 124 125
   set init5=cybcod
   set cybOption=-v CYB=Y
) else if %MACH%. == temp.   (
   set BSD4=-DBSD4
   set cg=23 24 125
   set N78=78
) else if %MACH%. == debug.  (
   set BSD4=-DBSD4
   set N33=33
) else                       (
   echo machine %MACH% not known to a68s.
   exit /b 1
)

echo %MACH%: w/p: %W%/%P% RECIPE(%RECIPE%) NOFLOAT:%NOFLOAT% BSD4:%BSD4%

rem note, originally, 21/121 did not appear in the tailoring options
rem setting 21 causes the "semantic monitoring" code to be included
set F21=121

set TERRS=

rem option 33 "generate code for the symbolic debugger"
set N33=133
rem set N33=33
set TNOS=101   2 103 104 105 111 %F21% 122 123 %cg% 32 %N33% 41 42 150 151 152 153 154 155 161 %RECIPE%
set TNOP=101 102 103 104   5 111 %F21% 122 123 %cg% 32 %N33% 41 42 150 151 152 153 154 155 161 %RECIPE%
set TNOC=  1 102 103 104 105 111 %F21% 122 123 %cg% 32 %N33% 41 42 150 151 152 153 154 155 161 %RECIPE%
set TNOE=%TNOS%

echo TNOS:%TNOS%

set LX1RC=-v RC=tmp/lx1.p2crc

echo %TNOE% 70   71  %N72%   73  %N74% 175 %N76% %N77% %N78% 300 | %TAILOR% aem/a68sdec.p %TERRS% > tmp\a68sdec_.h
echo lx0
type tmp\a68sdec_.h                                                                         > tmp\_lx0.p
echo %TNOE% 81 282 284 285 286 300                        | %TAILOR% aem\a68s1lx.p %TERRS% >> tmp\_lx0.p
echo begin end.                                                                            >> tmp\_lx0.p
%PPP% -v src=tmp/_lx0.p     -v ENEW=N -v HDRF=Y %LX1RC%   | %RBL%                           > tmp\lx0.p

if %init5%. == perqcod. set TNOS=%TNOP%
if %init5%. == cybcod.  set TNOS=%TNOC%

echo %TNOS% 70   71  %N72%   73  %N74% 175 %N76% %N77% %N78%    300 | %TAILOR% aem/a68sdec.p %TERRS% > tmp\a68sdec0.h
echo %TNOS% 70 %N71%   72    73  %N74% 175 %N76% %N77% %N78%    300 | %TAILOR% aem/a68sdec.p %TERRS% > tmp\a68sdec2.h
echo %TNOS% 70 %N71% %N72%   73    74   75 %N76% %N77% %N78%    300 | %TAILOR% aem/a68sdec.p %TERRS% > tmp\a68sdec4.h
echo %TNOS% 70 %N71% %N72% %N73% %N74%  75   76  %N77%   78     300 | %TAILOR% aem/a68sdec.p %TERRS% > tmp\a68sdec5.h
echo %TNOS% 70 %N71% %N72%   73  %N74% 175   76    77    78     300 | %TAILOR% aem/a68sdec.p %TERRS% > tmp\a68sdec6.h

echo %TNOP% 70 %N71% %N72% %N73% %N74%  75   76  %N77%   78  86 300 | %TAILOR% aem/a68sdec.p %TERRS% > tmp\a68sdecP.h

echo lx1
type tmp\a68sdec0.h                                                                         > tmp\_lx1.p
echo %TNOS% 81 282 284 285 286 300                        | %TAILOR% aem\a68s1lx.p %TERRS% >> tmp\_lx1.p
echo begin end.                                                                            >> tmp\_lx1.p
%PPP% -v src=tmp/_lx1.p     -v ENEW=N -v HDRF=Y %LX1RC%   | %RBL%                           > tmp\lx1.p

echo a68s1ce
type tmp\a68sdec0.h                                                         > tmp\_a68s1ce.p
echo %TNOS% 182 183 184 185 186 87 300 | %TAILOR% aem/a68s1int.p %TERRS%   >> tmp\_a68s1ce.p
echo %TNOS% 87 300                     | %TAILOR% aem/a68s1ce.p  %TERRS%   >> tmp\_a68s1ce.p
echo begin end.                                                            >> tmp\_a68s1ce.p
%PPP% -v src=tmp/_a68s1ce.p -v ENEW=N -v HDRF=Y | %RBL%                     > tmp\a68s1ce.p

echo a68s1cg
type tmp\a68sdec0.h                                                         > tmp\_a68s1cg.p
echo %TNOS% 182 183 184 185 86 187 300 | %TAILOR% aem\a68s1int.p %TERRS%   >> tmp\_a68s1cg.p
echo %TNOS% 86 300                     | %TAILOR% aem\a68s1cg.p  %TERRS%   >> tmp\_a68s1cg.p
echo begin end.                                                            >> tmp\_a68s1cg.p
%PPP% -v src=tmp/_a68s1cg.p -v ENEW=N -v HDRF=Y | %RBL%                     > tmp\a68s1cg.p

echo a68s1md
type tmp\a68sdec0.h                                                         > tmp\_a68s1md.p
echo %TNOS% 182 183 84 185 186 187 300 | %TAILOR% aem\a68s1int.p %TERRS%   >> tmp\_a68s1md.p
echo %TNOS% 84 300                     | %TAILOR% aem\a68s1md.p  %TERRS%   >> tmp\_a68s1md.p
echo begin end.                                                            >> tmp\_a68s1md.p
%PPP% -v src=tmp/_a68s1md.p -v ENEW=N -v HDRF=Y | %RBL%                     > tmp\a68s1md.p

echo a68s1s1
type tmp\a68sdec0.h                                                         > tmp\_a68s1s1.p
echo %TNOS% 182 183 184 85 186 187 300 | %TAILOR% aem\a68s1int.p %TERRS%   >> tmp\_a68s1s1.p
echo %TNOS% 85 300                     | %TAILOR% aem\a68s1s1.p %TERRS%    >> tmp\_a68s1s1.p
echo begin end.                                                            >> tmp\_a68s1s1.p
%PPP% -v src=tmp/_a68s1s1.p -v ENEW=N -v HDRF=Y | %RBL%                     > tmp\a68s1s1.p

echo a68s1s2
type tmp\a68sdec0.h                                                         > tmp\_a68s1s2.p
echo %TNOS% 182 83 184 185 186 187 300 | %TAILOR% aem\a68s1int.p %TERRS%   >> tmp\_a68s1s2.p
echo %TNOS% 83 300                     | %TAILOR% aem\a68s1s2.p  %TERRS%   >> tmp\_a68s1s2.p
echo begin end.                                                            >> tmp\_a68s1s2.p
%PPP% -v src=tmp/_a68s1s2.p -v ENEW=N -v HDRF=Y | %RBL%                     > tmp\a68s1s2.p

echo a68s1pa
type tmp\a68sdec0.h                                                         > tmp\_a68s1pa.p
echo %TNOS% 82 183 184 185 186 187 300 | %TAILOR% aem\a68s1int.p %TERRS%   >> tmp\_a68s1pa.p
echo %TNOS% 82 300                     | %TAILOR% aem\a68s1pa.p  %TERRS%   >> tmp\_a68s1pa.p
echo begin end.                                                            >> tmp\_a68s1pa.p
%PPP% -v src=tmp/_a68s1pa.p -v ENEW=N -v HDRF=Y | %RBL%                     > tmp\a68s1pa.p

echo lx2
type tmp\a68sdec0.h                                                         > tmp\_lx2.p
echo %TNOS% 300                        | %TAILOR% aem\a68sint.p %TERRS%    >> tmp\_lx2.p
echo %TNOS% 281 82 284 285 286 300     | %TAILOR% aem\a68s1lx.p %TERRS%    >> tmp\_lx2.p
echo begin end.                                                            >> tmp\_lx2.p
%PPP% -v src=tmp/_lx2.p     -v ENEW=N -v HDRF=Y -v RC=tmp/lx2.p2crc | %RBL% > tmp\lx2.p

echo lx4
type tmp\a68sdec0.h                                                         > tmp\_lx4.p
echo %TNOS% 300                        | %TAILOR% aem\a68sint.p %TERRS%    >> tmp\_lx4.p
echo %TNOS% 281 282 84 285 286 300     | %TAILOR% aem\a68s1lx.p %TERRS%    >> tmp\_lx4.p
echo begin end.                                                            >> tmp\_lx4.p
%PPP% -v src=tmp/_lx4.p     -v ENEW=N -v HDRF=Y -v RC=tmp/lx4.p2crc | %RBL% > tmp\lx4.p


rem echo %TNOS% 300                                  | %TAILOR% aem/cmpdum.p  %TERRS%  > tmp\cmpdum.p

type tmp\a68sdec0.h                                                                > tmp\init1.p
echo %TNOS% 300                                  | %TAILOR% aem\a68sint.p %TERRS% >> tmp\init1.p
echo %TNOS% 83 300                               | %TAILOR% aem\a68sdum.p %TERRS% >> tmp\init1.p
echo %TNOS% 81 83 184 300                        | %TAILOR% aem\a68sin.p  %TERRS% >> tmp\init1.p
echo begin end.                                                                   >> tmp\init1.p

type tmp\a68sdec4.h                                                                > tmp\init2.p
echo %TNOS% 84 300                               | %TAILOR% aem\a68sint.p %TERRS% >> tmp\init2.p
echo %TNOS% 83 300                               | %TAILOR% aem\a68sdum.p %TERRS% >> tmp\init2.p
echo %TNOS% 181 83 84 300                        | %TAILOR% aem\a68sin.p  %TERRS% >> tmp\init2.p
echo begin end.                                                                   >> tmp\init2.p

type tmp\a68sdec2.h                                                                > tmp\init3.p
echo %TNOS% 82 300                               | %TAILOR% aem\a68sint.p %TERRS% >> tmp\init3.p
echo %TNOS% 82 300                               | %TAILOR% aem\a68sdum.p %TERRS% >> tmp\init3.p
echo %TNOS% 82 300                               | %TAILOR% aem\a68spar.p %TERRS% >> tmp\init3.p
echo begin end.                                                                   >> tmp\init3.p

type tmp\a68sdec4.h                                                                > tmp\init4.p
echo %TNOS% 84 300                               | %TAILOR% aem\a68sint.p %TERRS% >> tmp\init4.p
echo %TNOS% 85 300                               | %TAILOR% aem\a68sdum.p %TERRS% >> tmp\init4.p
echo %TNOS% 85 300                               | %TAILOR% aem\a68ssp.p  %TERRS% >> tmp\init4.p
echo begin end.                                                                   >> tmp\init4.p

type tmp\a68sdec5.h                                                                > tmp\init5.p
echo %TNOS%    300                               | %TAILOR% aem\a68sint.p %TERRS% >> tmp\init5.p
echo %TNOS% 86 300                               | %TAILOR% aem\a68sdum.p %TERRS% >> tmp\init5.p
echo %TNOS% 86 300                               | %TAILOR% aem\a68scod.p %TERRS% >> tmp\init5.p
echo begin end.                                                                   >> tmp\init5.p

for %%s in ( perqcod perqce ) do (
    awk -f perq.awk                < aem\%%s.p             | %RBL%                 > tmp\_%%s
    type tmp\a68sdecP.h                                                            > tmp\%%s.p
    echo %TNOP%    300    | %TAILOR% aem\a68sint.p %TERRS% | %RBL%                >> tmp\%%s.p
    echo %TNOP% 86 300    | %TAILOR% aem\a68sdum.p %TERRS% | %RBL%                >> tmp\%%s.p
    echo %TNOP% 86 300    | %TAILOR% tmp\_%%s      %TERRS% | %RBL%                >> tmp\%%s.p
)
for %%s in ( cybcod ) do (
    awk -f perq.awk                < aem\%%s.p             | %RBL%                 > tmp\_%%s
    type tmp\a68sdecP.h                                                            > tmp\%%s.p
    echo %TNOC%    300    | %TAILOR% aem\a68sint.p %TERRS% | %RBL%                >> tmp\%%s.p
    echo %TNOC% 86 300    | %TAILOR% aem\a68sdum.p %TERRS% | %RBL%                >> tmp\%%s.p
    echo %TNOC% 86 300    | %TAILOR% tmp\_%%s      %TERRS% | %RBL%                >> tmp\%%s.p
)
rem echo begin end.                                                               >> tmp\cybcod.p
rem echo begin end.                                                               >> tmp\perqcod.p
echo begin end.                                                                   >> tmp\perqce.p


set pList=a68s1ce a68s1cg a68s1md a68s1pa a68s1s1 a68s1s2 lx0 lx1 lx2 lx4 init4 init5 cybcod perqcod perqce
for %%n in ( %pList% ) do ( if not exist tmp\%%n mkdir tmp\%%n
                            echo x > tmp\%%n\x
                            del /Q   tmp\%%n\*
                            awk -f pas.awk -v src=tmp/%%n.p -v out=tmp/%%n -v ENEW=N
                          )
for %%n in ( init1  ) do ( if not exist tmp\%%n mkdir tmp\%%n
                            echo x > tmp\%%n\x
                            del /Q   tmp\%%n\*
                            awk -f pas.awk -v src=tmp/%%n.p -v out=tmp/%%n -v ENEW=N -v def=INITIALI=INITLEX1;
                          )
for %%n in ( init2  ) do ( if not exist tmp\%%n mkdir tmp\%%n
                            echo x > tmp\%%n\x
                            del /Q   tmp\%%n\*
                            awk -f pas.awk -v src=tmp/%%n.p -v out=tmp/%%n -v ENEW=N -v def=INITIALI=INITLEX2;
                          )
for %%n in ( init3  ) do ( if not exist tmp\%%n mkdir tmp\%%n
                            echo x > tmp\%%n\x
                            del /Q   tmp\%%n\*
                            awk -f pas.awk -v src=tmp/%%n.p -v out=tmp/%%n -v ENEW=N -v def=PARSER=PARSESYN
                          )
rem for %%n in ( cmpdum  ) do ( if not exist tmp\%%n mkdir tmp\%%n
rem                             echo x > tmp\%%n\x
rem                             del /Q   tmp\%%n\*
rem                             awk -f pas.awk -v src=tmp/%%n.p -v out=tmp/%%n -v ENEW=N
rem                           )

echo VAR> tmp\_VAR
echo ENEW_LENGTH: INTEGER;>> tmp\_VAR

rem call merge_cmpdum.bat

rem %PPP% -v src=tmp/_cmpdum.pas       -v RC=tmp/cmpdum.p2crc -v ENEW=B | %RBL%        > tmp\cmpdum.pas
rem type tmp\_general.p2crc               >> tmp\cmpdum.p2crc
rem %PC% -o tmp\_cmpdum.c tmp\cmpdum.pas  -c tmp\cmpdum.p2crc
rem %PPC% -v RC=tmp/cmpdum.p2crc -v EXTERN=N -v ENEW=N tmp\_cmpdum.c                   > tmp\cmpdum.c
rem %CC% -o bin\cmpdum.exe -I%PINCLUDE% tmp\cmpdum.c a68Calls.c bin\libp2c.dll
rem if errorlevel 1 set CFAIL=%CFAIL%cmpdum;
rem echo.

call merge_init0.bat %init5%

%PPP% -v src=tmp/_init0.pas -v def=A68INIT=SYNTAXF;ASSERT=ASERT -v RC=tmp/init0.p2crc -v ENEW=B | %RBL% > tmp\init0.pas
               TYPE tmp\init0.p2crc
type tmp\_general.p2crc                               >> tmp\init0.p2crc
echo ModName    PMOD                                  >> tmp\init0.p2crc
echo BufferedFile SYNTAXF # mode: r type: text        >> tmp\init0.p2crc
%PC% -o tmp\_init0.c tmp\init0.pas                    -c tmp\init0.p2crc -h tmp\init0.h
%PPC% -v EXTERN=N %cybOption%   -v RC=tmp/init0.p2crc    tmp\_init0.c   > tmp\init0.c
%CC% -o tmp\mod.o -c liba68s\mod.c
%CC% -o bin\init0.exe -I%PINCLUDE% -I. tmp\init0.c a68Calls.c tmp\mod.o bin\libp2c.dll
if errorlevel 1 set CFAIL=%CFAIL%init0.exe;
echo.


echo %TNOS% 70 71 172 73 174 175 176 177 %N78% 300  | %TAILOR% aem\a68sdec.p %TERRS%    > tmp\_lx1s1.p
echo %TNOS% 81 282 284 285 286 300                  | %TAILOR% aem\a68s1lx.p %TERRS%   >> tmp\_lx1s1.p
type                                                           aem\dec_main_s1.p       >> tmp\_lx1s1.p
%PPP% -v src=tmp/_lx1s1.p -v RC=tmp/_lx1s1.p2crc -v ENEW=B | %RBL%                      > tmp\lx1s1.p

for %%n in ( lx1s1   ) do ( if not exist tmp\%%n mkdir tmp\%%n
                            echo x > tmp\%%n\x
                            del /Q   tmp\%%n\*
                            awk -f pas.awk -v src=tmp/%%n.p -v out=tmp/%%n -v ENEW=N
                          )

rem %CC% -o bin\a68s.exe tmp\lx2.o tmp\lx4.o tmp\a68s1ce.o tmp\a68s1cg.o tmp\a68s1md.o tmp\a68s1pa.o tmp\a68s1s1.o tmp\a68s1s2.o a68Calls.c bin\libp2c.dll
rem if errorlevel 1 set CFAIL=%CFAIL%a68s.exe;
rem echo.

if not "%CFAIL%" == "" echo **** ERRORS in: %CFAIL:;=, %

set amp="address-of"

echo LGO is currently opened input - will need to be output for a68s1cg/a68s1ce
echo TODO Now uses A68INIT ( renamed as SYNTAXF ) as the input for PARSEPAR,
echo      so SOURCDEC and SYNTAXF are swapped  before and after PARSEPAR and
echo      SOURCDEC re-init after the second swap
echo      - currently, SYNTAXF is left declared as LOADFILE: should now be TEXT
echo **** ALIGNMENT reals need 8-byte alignment
echo      currently replacing CONST_SZADDR + CONST_SZREAL
echo                     with CONST_SZADDR + CONST_PAD_ADDR2REAL + CONST_SZREAL
echo **** Generated code is rejected by the ACK
echo **** Assertion failures e.g.: ".loc .int x := .entier ( random * 100 ) + 1;"
echo      Also null-pointer de-references
echo      - appears to be due to PASC procedures without parameters
echo       (random is the only one)
echo      changing random to PROC instead of PASC appears to "work" but would
echo      need library changes
echo TODO make "semantic trace" be controlled by a pragma
