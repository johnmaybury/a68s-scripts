// a68Calls.c: Routines for the a68s compiler: open/clsoe files specified on
//                                             the program command-line and
//                                             various other routines

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define MAX_NAME_LENGTH    50


static FILE * openF( char * fileName, char * mode )
{
    FILE * f        = NULL;
    char   rwMode   = ( * mode );

    if( rwMode != 'r' && rwMode != 'w' )
    {
        // invalid file I/O mode
        fprintf( stderr
               , "file %s has an invalid I/O mode: '%c'\n"
               , fileName
               , rwMode 
               );
    }
    else if( fileName == NULL )
    {
        // no file on the command line
        fprintf( stderr
               , "file name required (openF)\n"
               );
    }
    else if( strcmp( fileName, "-" ) == 0 )
    {
        // opening "-" - use standard input/output if possible
        if( rwMode == 'r' )
        {
            // reading from stdin - ths is OK
            f = stdin;
        }
        else if( rwMode == 'w' )
        {
            // writing to stdout - ths is OK
            f = stdout;
        }
        else
        {
            // shouldn't get here...
            // can't use stdout for the specified I/O mnde
            fprintf( stderr, "Can't use stdin/stdout for ioMode %c\n"
                   , rwMode
                   );
        } // if rwMode == 'r';; == 'w';;
    }
    else if( strcmp( fileName, "=" ) == 0 )
    {
        // opening "=" - use standard error if possible
        if( rwMode == 'w' )
        {
            // writing to stderr - ths is OK
            f = stderr;
        }
        else
        {
            // can't use stderr for input
            fprintf( stderr, "Can't use stderr for input\n" );
        } // if rwMode == 'w';;
    }
    else
    {
        // open the named file
        f = fopen( fileName, mode );
        if( f == NULL )
        {
            // unable to open the file
            perror( fileName );
        } // if f == NULL
    } // if fileName == NULL;;

    if( f == NULL )
    {
        // failed to open the file
        fprintf( stderr, "**** Unable to open file %s\n"
               , ( ( fileName == NULL ) ? "(null)" : fileName )
               );
        exit( 7 );
    } // if 1 == NULL

return f;
} // openF


FILE * openFile( int argc, char ** argv, int pos, char * mode )
{
    char * fileName = ( ( pos < argc ) ? argv[ pos ] : NULL );
    FILE * f        = NULL;
    char   rwMode   = ( * mode );

    if( rwMode != 'r' && rwMode != 'w' )
    {
        // invalid file I/O mode
        fprintf( stderr
               , "file %d has an invalid I/O mode: '%c'\n"
               , pos
               , rwMode 
               );
    }
    else if( fileName == NULL )
    {
        // no file on the command line
        fprintf( stderr
               , "file %d not specified on the command line\n"
               , pos
               );
    }
    else
    {
        // open the named file
        f = openF( fileName, mode );
    } // if rwMode != 'r' && != 'w';; fileName == NULL;;

    if( f == NULL )
    {
        // failed to open the file
        fprintf( stderr, "**** Unable to open file %d\n", pos );
        exit( 7 );
    } // if 1 == NULL

return f;
} // openFile


void closeFile( FILE * f )
{
    if( f != NULL )
    {
        // have a file to close
        if( f != stdin && f != stdout && f != stderr )
        {
            // it isn't standard input/output/error - try closing it
            fclose( f );
        } // if f != stdin && f != stdout && f != stderr
    } // if f != NULL

} // closeFile


int GETARG( char * argText, int argMax, int sl, int argNumber )
{
printf( "GETARG...\n" );fflush( stdout );
    if( argMax > MAX_NAME_LENGTH || argMax < 1 )
    {
        // name too long/short
        fprintf( stderr
               , "Invalid arg text length: %d: must be in 1..%d (GETARG)\n"
               , argMax
               , MAX_NAME_LENGTH
               );
    }
    else
    {
        // namew length is probably OK
        // pretend the command line had #<argNumber> for the parameter
        char aName[ MAX_NAME_LENGTH + 1 ];
        sprintf( aName, "#%d", argNumber );
        strncpy( argText, aName, argMax );
        argText[ argMax - 1 ] = '\0';
    } // if argMax > MAX_NAME_LENGTH || < 1;;

printf( "...(%s)\n", argText  );fflush( stdout );

} // GETARG


void NAMEFILE( char * fileName, int nameMax, int mode, FILE ** f )
{
printf( "NAMEFILE...\n" );fflush( stdout );
    if( nameMax > MAX_NAME_LENGTH || nameMax < 1 )
    {
        // name too long/short
        fprintf( stderr
               , "Invalid File name length: %d: must be in 1..%d (NAMEFILE)\n"
               , nameMax
               , MAX_NAME_LENGTH
               );
    }
    else
    {
        // namew length is probably OK
        char fName[ MAX_NAME_LENGTH + 1 ];
        strncpy( fName, fileName, nameMax );
        fName[ nameMax ] = '\0';
        * f = openF( fName, ( ( mode == 1 ) ? "w" : "r" ) );
    } // if nameMax > MAX_NAME_LENGTH || < 1;;

printf( "...(%s)\n", fileName );fflush( stdout );

} // NAMEFILE


void ABORT( void )
{
    printf( "**** HALT\n" );
    exit( 5 );
} // ABORT


int GETADDRE( void * p )
{
return (int) p;
} // GETADDRE


void CTIME1( char * dateTime, int dtLength )
{

    time_t      td;
    struct tm * dt;

    char        dateBuffer[ 128 ];
    int         bfLength;

    time( & td );
    dt = localtime( & td );
    strcpy( dateBuffer, ctime( & td ) );

    sprintf( dateBuffer
           , "%04d/%02d/%02d %02d:%02d:%02d"
           , dt -> tm_year + 1900
           , dt -> tm_mon + 1
           , dt -> tm_mday
           , dt -> tm_hour
           , dt -> tm_min
           , dt -> tm_sec
           );
    bfLength = strlen( dateBuffer );
    while( bfLength < dtLength )
    {
        dateBuffer[ bfLength ] = ' ';
        bfLength ++;
    } // while bfLength < dtLength

    strncpy( dateTime, dtLength, dateBuffer );
    dateTime[ dtLength - 1 ] = '\0';


} // CTIME1
