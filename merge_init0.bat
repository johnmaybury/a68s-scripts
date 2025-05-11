@echo off
setlocal enabledelayedexpansion
set init5=%1
if %init5%. == . set init5=init5
set a68s1ce=a68s1ce
if %init5%. == perqcod. set a68s1ce=perqce
rem if %init5%. == cybcod. ECHO ON
set ofW=tmp\_init0.pas
set ofA=%ofW:\=/%
set semi=;

echo Merging... init5=%init5% a68s1ce=%a68s1ce%

set cons=
set typs=
set vars=
set fwds=

set n=1
for %%s in ( lx4 lx2 lx1 lx0 init1 init2 init3 init4 %init5% ) do (
    set cons=!cons! -v src!n!=tmp/%%s/CONST
    set typs=!typs! -v src!n!=tmp/%%s/TYPE
    set vars=!vars! -v src!n!=tmp/%%s/VAR
    set fwds=!fwds! -v src!n!=tmp/%%s/FORWARD
    set /A n=!n! + 1
)

awk -f pam.awk %fwds%                                       -v out=tmp/_FWD

set fwds=%fwds% -v src1=tmp/_FWD
set n=2
for %%s in ( a68s1s1 a68s1s2 a68s1pa a68s1md a68s1s2 %a68s1ce% a68s1cg ) do (
    set fwds=!fwds! -v src!n!=tmp/%%s/FORWARD
    set /A n=!n! + 1
)

awk -f pam.awk %typs%                                       -v out=tmp/_TYP
if %a68s1ce%. == perqce. (
    awk -f pam.awk -v src1=tmp/_TYP -v src2=%a68s1ce%/TYPE  -v out=tmp/_TYP
)

type tmp\lx0\PROGRAM                                             > %ofW%
awk -f pam.awk %cons%                                       -v out=%ofA%
type tmp\_TYP                                                   >> %ofW%
awk -f pam.awk %vars%                                       -v out=%ofA%
type tmp\_VAR                                                   >> %ofW%
awk -f pam.awk %fwds%                                       -v out=%ofA%

if not %a68s1ce%. == a68s1ce. echo PROCEDURE TAKELINE;FORWARD;  >> %ofW%
if not %a68s1ce%. == a68s1ce. echo PROCEDURE SETTEXTS;FORWARD;  >> %ofW%
if not %a68s1ce%. == a68s1ce. echo PROCEDURE WRITEINS(INST:COMPACT);FORWARD; >> %ofW%

echo PROCEDURE SWAPF( F1, F2: TEXT );EXTERN;                    >> %ofW%
echo PROCEDURE ABORT;EXTERN;                                    >> %ofW%
if     %a68s1ce%. == perqce.  echo PROCEDURE NAMEFILE(N:ARGSTRIN;L,B:INTEGER;VAR F:TEXT);EXTERN; >> %ofW%
if     %a68s1ce%. == perqce.  echo FUNCTION GETARG(VAR S:ARGSTRING;SU,SL:INTEGER;I:INTEGER):BOOLEAN;EXTERN; >> %ofW%
if not %a68s1ce%. == a68s1ce. echo PROCEDURE CTIME1(D:TIMSTRIN;LEN:INTEGER);EXTERN;    >> %ofW%

echo PROCEDURE SETTEXTS;                                         > tmp\_SETTEXTS
echo BEGIN                                                      >> tmp\_SETTEXTS
echo   WRITE('[[SETTEXTS:');                                    >> tmp\_SETTEXTS
echo   IF DATASTAT=INDATA THEN WRITE(EOOPNDS);                  >> tmp\_SETTEXTS
echo   WRITELN(']]:');                                          >> tmp\_SETTEXTS
echo   DATASTAT := ENDDATA                                      >> tmp\_SETTEXTS
echo END;                                                       >> tmp\_SETTEXTS

for %%d in ( lx4 lx2 lx1 a68s1pa a68s1s1 a68s1s2 a68s1md %a68s1ce% a68s1cg ) do (
    for %%s in ( tmp\%%d\* ) do (
        if not %%~ns == PROGRAM (
           if not %%~ns == CONST (
              if not %%~ns == TYPE (
                 if not %%~ns == VAR (
                    if not %%~ns == FORWARD (
                       if not %%~ns == EXTERN (
                          if not %%~ns == BEGIN (
                             if not %%~ns == RESTORE (
                                if not %%~ns == DUMP (
                                   type %%s                     >> %ofW%
                                )
                             )
                          )
                       )
                    )
                 )
              )
           )
        )
    )
)
type tmp\init1\STASHLEX      >> %ofW%
type tmp\init1\STASHLLE      >> %ofW%
type tmp\init1\INITLEX1      >> %ofW%
type tmp\init2\INITLEX2      >> %ofW%
type tmp\init3\PARSEPAR      >> %ofW%
type tmp\init4\STANDARD      >> %ofW%
type tmp\init4\INITSEMA      >> %ofW%
type tmp\%init5%\INITCODE    >> %ofW%
if not %a68s1ce%. == a68s1ce. (
   if %a68s1ce%. == perqce. (
    type tmp\_SETTEXTS       >> %ofW%
   ) else (
    type tmp\a68s1ce\SETTEXTS>> %ofW%
    type tmp\a68s1ce\WRITEINS>> %ofW%
   )
)
echo PROCEDURE RESTORE;      >> %ofW%
echo     BEGIN               >> %ofW%
echo        SWAPF( SOURCDEC  >> %ofW%
echo             , A68INIT   >> %ofW%
echo             );          >> %ofW%
echo        INITLEX1;        >> %ofW%
echo        INITLEX2;        >> %ofW%
echo        PARSEPAR;        >> %ofW%
echo        STANDARD;        >> %ofW%
echo        INITSEMA;        >> %ofW%
echo        INITCODE;        >> %ofW%
echo        SWAPF( SOURCDEC  >> %ofW%
echo             , A68INIT   >> %ofW%
echo             );          >> %ofW%
echo        reset(SOURCDECS);>> %ofW%
echo     END;                >> %ofW%
echo BEGIN                   >> %ofW%
echo     reset(A68INIT);     >> %ofW%
echo     reset(SOURCDECS);   >> %ofW%
echo     rewrite(LSTFILE);   >> %ofW%
if not %a68s1ce%. == perqce. echo     rewrite(LGO);>> %ofW%
echo     rewrite(DUMPF);     >> %ofW%
echo     ENEW_LENGTH := -1;  >> %ofW%
echo     ALGOL68;            >> %ofW%
echo END.                    >> %ofW%
