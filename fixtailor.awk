BEGIN \
{
    printf( "#define x__OPEN_INFILE     mustopen( argv[ 1 ], \"r\", (FILE *)NULL )    \n" );
    printf( "#define x__OPEN_error      mustopen( ( argc < 3 ) ? (char *)NULL : argv[ 2 ], \"w\", stderr )\n" );
    printf( "#define x__CLOSE(f)        (   ( f == NULL )   \\\n" );
    printf( "                           ? 0                 \\\n" );
    printf( "                           : ( ( f == stderr ) \\\n" );
    printf( "                             ? 0               \\\n" );
    printf( "                             : fclose(f)       \\\n" );
    printf( "                             )                 \\\n" );
    printf( "                           )\n"                      );

    seenInclude = 0;

} # BEGIN

                         { gsub( /\t/, "        ", $0 );    }
/^ *INFILE *= *NULL/     { sub( /NULL/, "x__OPEN_INFILE" ); }
/^ *error *= *NULL/      { sub( /NULL/, "x__OPEN_error"  ); }              
/ fclose[(] *error *[)]/ { sub( /fclose/, "x__CLOSE" );     }                 
{ print; }                                                         
/^ *# *include/ \
{
    if( ! seenInclude )
    {
        seenInclude = TRUE;
        printf( "extern FILE * mustopen( char *, char *, FILE * );\n" );
    } # if ! seenInclude
}
