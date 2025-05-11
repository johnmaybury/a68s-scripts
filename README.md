# a68s-scripts
Prototype scripts used to build the ACK A68S compiler: https://github.com/davidgiven/ack/tree/default/lang/a68s

The scripts here are what I've been using to build an executable from the A68S sources
They are for use on Windows and use TCC as the C compiler (assumed to be installed at \TCC\TCC.exe)
and use p2c to convert Pascal to C (assumed to be installed at \p5\p2c-master).

It should work with GCC but I haven't tried that.

Quite a bit of it would be irrelevant if FreePascal was used, particularly the file-handling as FP
can do the "file names on the command line" thing.

NB: I've created an executable using this (will be bin\init0.exe) but it will produce code that the rest of the ACK won't like.

Also included is hilo.8 - an A68S version of DG's hilo.* example programs.

The buildLib.bat script will attempt to build the Pascal parts of liba68s - this needs more work and all of this is still WIP.
