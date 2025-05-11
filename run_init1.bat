set pgm=%1
set lst=%2
if not %pgm%. == . goto :haveSrc
   echo Program name required.
   exit /b 1
:haveSrc
   if %lst%. == . set lst=-
   set bn=%pgm%QQ
   set bn=%bn:.a68QQ=%
   set bn=%bn:.8QQ=%
   set bn=%bn:QQ=%
   set lgo=%bn%.k
   set em=%bn%.e
   rem           SOURCDEC LGO   LSTFILE SYNTAXF DUMPF
   bin\init0.exe %pgm%    %lgo% %lst%   zz4     F1
   \ack\x\modules\src\read_em\k2e %lgo% > %em%
:endSrc
