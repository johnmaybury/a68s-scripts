// a68Calls.c: Routines for the a68s compiler: open/clsoe files specified on
//                                             the program command-line and
//                                             ABORT()

#include <stdio.h>


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
        // popen the named file
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
        fprintf( stderr, "**** Unable to open file %d\n", pos );
        exit( 7 );
    } // if 1 == NULL

return f;
} // mustopen


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


void ABORT( void )
{
    printf( "**** HALT\n" );
    exit( 5 );
} // ABORT


int GETADDRE( void * p )
{
return (int) p;
} // GETADDRE
