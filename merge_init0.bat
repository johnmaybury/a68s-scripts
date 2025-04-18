@echo off
setlocal enabledelayedexpansion
set ofW=tmp\_init0.pas
set ofA=%ofW:\=/%

set cons=
set typs=
set vars=
set fwds=

set n=1
for %%s in ( lx4 lx2 lx1 init1 init2 init3 init4 init5 ) do (
    set cons=!cons! -v src!n!=tmp/%%s/CONST
    set typs=!typs! -v src!n!=tmp/%%s/TYPE
    set vars=!vars! -v src!n!=tmp/%%s/VAR
    set fwds=!fwds! -v src!n!=tmp/%%s/FORWARD
    set /A n=!n! + 1
)
set vars=%vars% -v src%n%=tmp/_VAR

awk -f pam.awk %fwds%                                       -v out=tmp/_FWD

set fwds=%fwds% -v src1=tmp/_FWD
set n=2
for %%s in ( a68s1s1 a68s1s2 a68s1pa a68s1md a68s1s2 a68s1ce a68s1cg ) do (
    set fwds=!fwds! -v src!n!=tmp/%%s/FORWARD
    set /A n=!n! + 1
)

type tmp\lx1\PROGRAM                                             > %ofW%
awk -f pam.awk %cons%                                       -v out=%ofA%
awk -f pam.awk %typs%                                       -v out=%ofA%
awk -f pam.awk %vars%                                       -v out=%ofA%
awk -f pam.awk %fwds%                                       -v out=%ofA%

echo PROCEDURE SWAPF( F1, F2: TEXT );EXTERN;                    >> %ofW%
for %%d in ( lx4 lx2 lx1 a68s1pa a68s1s1 a68s1s2 a68s1md a68s1ce a68s1cg ) do (
    for %%s in ( tmp\%%d\* ) do (
        if not %%~ns == PROGRAM (
           if not %%~ns == CONST (
              if not %%~ns == TYPE (
                 if not %%~ns == VAR (
                    if not %%~ns == FORWARD (
                       if not %%~ns == EXTERN (
                          if not %%~ns == BEGIN (
                             if not %%~ns == RESTORE (
                                type %%s                        >> %ofW%
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
type tmp\init5\INITCODE      >> %ofW%
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
echo     rewrite(LGO);       >> %ofW%
echo     rewrite(DUMPF);     >> %ofW%
echo     ENEW_LENGTH := -1;  >> %ofW%
echo     ALGOL68;            >> %ofW%
echo END.                    >> %ofW%
