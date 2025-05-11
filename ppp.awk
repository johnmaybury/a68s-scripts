# prePascal.awk: pre-processor for the a68s .p sources

BEGIN \
{

    FALSE                         = 0;
    TRUE                          = 1;

    EOF_CHAR                      = "<eof>";

    EOF_SYMBOL                    = "e:";
    STRING_SYMBOL                 = "s:";
    NUMBER_SYMBOL                 = "n:";
    NAME_SYMBOL                   = "a:";
    OTHER_SYMBOL                  = "o:";
    COMMENT_SYMBOL                = "c:";

    MAX_NAME_LENGTH               = 8;

    longReserved[ "PROCEDURE"   ] = "Y";
    longReserved[ "IMPLEMENT"   ] = "Y";
    longReserved[ "SEGMENTED"   ] = "Y";
    longReserved[ "ENEW_LENGTH" ] = "Y";

    standardFiles[ "INPUT"      ] = 0;
    standardFiles[ "OUTPUT"     ] = 1;

    ioFunction[    "GET"        ] = "^r";
    ioFunction[    "PUT"        ] = "^w";
    ioFunction[    "RESET"      ] = "r";
    ioFunction[    "REWRITE"    ] = "w";
    ioFunction[    "READ"       ] = "r";
    ioFunction[    "READLN"     ] = "r";
    ioFunction[    "WRITE"      ] = "w";
    ioFunction[    "WRITELN"    ] = "w";

    afterEnd[      "ELSE"       ] = "Y";
    afterEnd[      "END"        ] = "Y";
    afterEnd[      "UNTIL"      ] = "Y";
    beforeIf[      "BEGIN"      ] = "Y";
    beforeIf[      "THEN"       ] = "Y";
    beforeIf[      "ELSE"       ] = "Y";
    beforeIf[      "DO"         ] = "Y";
    beforeIf[      "REPEAT"     ] = "Y";
    beforeIf[      ":"          ] = "Y";
    beforeIf[      ";"          ] = "Y";

    define[        "LONG"       ] = "INTEGER"; # "LONGINT";
    define[        "EXTERN"     ] = "EXTERNAL";
    define[        "INLINE"     ] = "XQINLINE";
    define[        "XOR"        ] = "XOR9QZ";
    define[        "SEGMENTED"  ] = "";

    # prefixes for messages
    ERROR_PREFIX                  = "Error: ";
    INFORMATION_PREFIX            = "Note:  ";

    # "declare" some global arrays and variables
    atEof                         = FALSE;
    fileNumber                    = 0;
    filePosition                  = 0;
    c                             = "";
    line                          = "";
    thisLine                      = "";
    fullLine                      = "";
    lineNumber                    = 0;
    lastErrorLineNumber           = 0;
    haveComment                   = FALSE;
    pushBackPos                   = 0;
    lastSymbol                    = ";";
    sy_text                       = "";
    sy_type                       = OTHER_SYMBOL;
    sy_line                       = 0;
    sy_comments                   = "";
    uc_text                       = "";
    delete inFile;
    delete pbLine;
    delete pbText;
    delete pbType;
    delete files;
    delete buffered;
    delete ioMode;

    # source file name from the command line
    #        either a pathname or "-" for standard input
    src  = "" src;

    # optional RC file name from the command line
    RC   = "" RC;

    # additional defines, from the command line
    delete additionalDefines;
    def  = "" def;
    n    = split( def, additionalDefines, ";" );
    dPos = 0;
    for( dPos = 1; dPos <= n; dPos ++ )
    {
        dName  = additionalDefines[ dPos ];
        dValue = additionalDefines[ dPos ];
        sub( /=.*$/,    "", dName );
        sub( /^[^=]*=/, "", dValue );
        define[ toupper( dName ) ] = dValue;
    } # for dPos

    # how to process ENEW from the command line
    #     N -> do not process ENEW
    #     Q -> quote the first parameter    (currently the default)
    #     B -> convert to a block using "new"
    #     N and B also apply to EDISPOSE calls
    ENEW = "" ENEW;
    if( ENEW == "" )
    {
        ENEW = "Q";
    } # if ENEW == ""

    # whether or not to keep non-standard files in the program header
    # from the command line
    HDRF = "" HDRF;

    includeNonStandardFiles      = HDRF == "Y";

    errorCount                   = 0;

    # parse the source if possible

    srcBaseName = src;
    while( srcBaseName ~ /[\/\\]/ )
    {
        sub( /^[^\/\\]*[\/\\]/, "", srcBaseName );
    } # while srcBaseName ~ /[\/\\]/

    openSourceFile( src );

    if( errorCount == 0 )
    {
        # opened the source file - parse it
        parseProgram();
        closeSourceFile();

        if( errorCount == 0 )
        {
            if( RC != "" )
            {
                # have a pathname to write the p2crc file to
                writeRcFile();
            } # if RC != ""
        } # if errorCount == 0

    } # if errorCount == 0


} # BEGIN


function message( prefix, text )
{

    printf( "(*\n** %s %s:%d %s\n*)\n",
            prefix,
            srcBaseName,
            lineNumber,
            text );


} # message


function note( text )
{
    message( INFORMATION_PREFIX, text );
} # error


function error( text )
{
    message( ERROR_PREFIX, text );
    errorCount ++;
} # error


function openSourceFile( srcPath )
{

    pushBackPos                  = 0;
    haveComment                  = FALSE;
    atEof                        = FALSE;
    fullLine                     = "";
    line                         = "";
    c                            = "";
    lineNumber                   = 1;
    lastErrorLineNumber          = 0;

    fileNumber                   = 0;
    inFile[ fileNumber ]         = srcPath;


    # open the source file if possible

    if( inFile[ fileNumber ] == "" )
    {

        # no source file specified
        error( "Expected source file name on the command line: " \
               "\"-v src=<source_file_path>\"" );

    }
    else if( inFile[ fileNumber ] != "-"                 &&
             ( getline line < inFile[ fileNumber ] ) < 0 )
    {

        # source file not found
        error( "Source file " inFile[ fileNumber ] " not found" );
    }
    else if( inFile[ fileNumber ] == "-" && ( getline line ) < 0 )
    {
        # unable to read from standard input
        error( "Unable to read from standard input" );
    }
    else
    {
        # opened OK

        line     = line "\n";
        thisLine = line;
        fullLine = line;

        nextChar();
        nextSymbol();

    } # if inFile[ fileNumber ] == "";;
      #    inFile[ fileNumber ] != "-"
      # && ( getline line < inFile[ fileNumber ] ) < 0
      #    inFile[ fileNumber ] == "-" && ( getline line ) < 0


} # openSourceFile


function closeSourceFile()
{

    if( inFile[ fileNumber ] != "-" )
    {
        # not reading from standard input
        close( inFile[ fileNumber ] );
    } # if inFile[ fileNumber ] != "-"

} # closeSourceFile


function nextChar(                                                    ioStat )
{

    if( length( line ) < 1 )
    {
        # reached end of line

        if( inFile[ fileNumber ] == "-" )
        {
            # reading from standard input
            ioStat = getline thisLine;
        }
        else
        {
            # not reading from standard input
            ioStat = ( getline thisLine < inFile[ fileNumber ] );
        } # if inFile[ fileNumber ] == "-";;

        line     = thisLine "\n";
        fullLine = thisLine;

        if( ioStat > 0 )
        {
            # got a line
            lineNumber ++;
        }
        else
        {
            # EOF or error
            atEof = TRUE;

            if( ioStat < 0 )
            {
                # error
                error( "I/O error on: " inFile[ fileNumber ] );

            } # if ioStat < 0

        } # if ioStat <= 0

    } # if length( line ) < 1

    if( atEof )
    {
        # at end-of-file
        c    = EOF_CHAR;
    }
    else
    {
        # have a character
        c    = substr( line, 1, 1 );
        line = substr( line, 2    );

    } # if atEof


} # nextChar


function addAndNextChar()
{

    sy_text = sy_text c;
    nextChar();

} # addAndNextChar


function getStringSymbol(                                               quote )
{

    sy_type      = STRING_SYMBOL;
    quote        = c;

    while( c == quote )
    {
        do
        {
            addAndNextChar();
        }
        while( c != quote    &&
               c != "\n"     &&
               c != EOF_CHAR );
        if( c != quote )
        {
            # didn't get a closing quote
            error( "Closing quote expected" );
        }
        else
        {
            # have a closing quote
            addAndNextChar();

        } # if c != quote;;

    } # while c == quote


} # getStringSymbol


function getNumberSymbol()
{

    sy_type = NUMBER_SYMBOL;

    while( c ~ /^[0-9]$/ )
    {
        addAndNextChar();
    } # while c ~ /^[0-9]$/

    if( c == "." && line !~ /^[.]/ )
    {
        # decimal point
        addAndNextChar();
        if( c !~ /^['0-9]$/ )
        {
            # invalid number
            error( "No digits after the decimal point: " sy_text );
        }
        else
        {
            # at least one digit
            while( c ~ /^[0-9]$/ )
            {
                addAndNextChar();
            } # while c ~ /^[0-9]$/
        } # if c !~ /^[0-9]$/;;

    } # if c == "." && line !~ /^[.]/

    if( c ~ /^[eE]$/ )
    {
        # exponent
        addAndNextChar();
        if( c ~ /^[-+]$/ )
        {
            # the exponent is signed
            addAndNextChar();
        } # if c ~ /^[-+]$/
        if( c !~ /^['0-9]$/ )
        {
            # invalid number
            error( "No digits after the exponent: " sy_text );
        }
        else
        {
            # at least one digit
            while( c ~ /^[0-9]$/ )
            {
                addAndNextChar();
            } # while c ~ /^[0-9]$/
        } # if c !~ /^[0-9]$/;;

    } # if c ~ /^[eE]$/

} # getNumberSymbol


function basicNextSymbol(                                    commentStartLine,
                                                                        quote )
{

    if( sy_type != COMMENT_SYMBOL )
    {
        # remember the last non-comment symbol
        lastSymbol = sy_text;
    } # if sy_type != COMMENT_SYMBOL

    if( pushBackPos > 0 )
    {
        # have a pushed back symbol

        sy_line = pbLine[ pushBackPos ];
        sy_text = pbText[ pushBackPos ];
        sy_type = pbType[ pushBackPos ];

        pushBackPos --;
    }
    else
    {
        # no pushed back symbol - get the next

        haveComment = FALSE;
        sy_text     = "";
        sy_line     = lineNumber;

        if( c == EOF_CHAR )
        {
            # reached EOF
            sy_text = "";
            sy_type = EOF_SYMBOL;

        }
        else if( c <= " " )
        {
            # whitespace
            sy_type = COMMENT_SYMBOL;
            while( c <= " " )
            {
                addAndNextChar();
            } # while c <= " "
        }
        else if( c == "\"" ||
                 c == "'"  )
        {
            # string literal
            getStringSymbol();
        }
        else if( c ~ /^[0-9]$/ )
        {
            # numeric literal
            getNumberSymbol();
        }
        else if( c ~ /^[a-zA-Z]$/ )
        {
            # name or keyword
            sy_type = NAME_SYMBOL;
            while( c ~ /^[a-zA-Z0-9_]$/ )
            {
                addAndNextChar();
            } # while c in name_chars
        }
        else if( c == "{" )
        {
            # {} comment
            sy_type          = COMMENT_SYMBOL;
            commentStartLine = sy_line;
            do
            {
                addAndNextChar();
            }
            while( c != "}" );
            if( c == "}" )
            {
                # properly terminated comment
                addAndNextChar();
            }
            else
            {
                # unterminated comment
                error( "Unterminated \"{\" comment starting on line: "        \
                       commentStartLine );
                sy_text = sy_text "}";

            } # if c != "}"
        }
        else if( c == "(" && line ~ /^[*]/ )
        {
            # (**) comment
            sy_type          = COMMENT_SYMBOL;
            commentStartLine = sy_line;
            addAndNextChar();
            addAndNextChar();
            while( c != "*" || line !~ /^[)]/ )
            {
                addAndNextChar();
            } # while c != "*" || line !~ /^[)]/
 
            # ensure the comment doesn't contain compiler directives that
            # probably don't work/might cause problems for the Pascal
            # compiler/transpiler we are going to use
            gsub( /[(][*][$]/, "(*S", sy_text );
 
            if( c == "*" )
            {
                # have a terminator
                addAndNextChar();
                addAndNextChar();
            }
            else
            {
                # unterminated comment
                error( "Unterminated \"(**)\" comment starting on line: "     \
                       commentStartLine );
                sy_text = sy_text "*)";

            } # if c == "}";;
        }
#        else if( c == "#" )
#        {
#            # pre-processor directive ?
#            preprocessorDirective();
#        }
        else
        {
            # operator, punctuation, etc.
            sy_type = OTHER_SYMBOL;
            addAndNextChar();
            if( ( sy_text == "<" && ( c == ">" || c == "=" ) ) ||
                ( sy_text == ">" &&   c == "="               ) ||
                ( sy_text == ":" &&   c == "="               ) ||
                ( sy_text == "." &&   c == "."               ) )
            {
                # digraph
                addAndNextChar();

            } # if various digraphs

        } # if various characters;;

    } # if pushBackPos > 0;;

    uc_text = toupper( sy_text );


} # basicNextSymbol


function nextSymbol(                                               prevSymbol )
{

    prevSymbol  = sy_text;
    sy_comments = "";

    do
    {
        basicNextSymbol();
        while( sy_type == COMMENT_SYMBOL )
        {
            sy_comments = sy_comments sy_text;
            basicNextSymbol();
        } # while sy_type == COMMENT_SYMBOL
    }
    while( prevSymbol == ";" && sy_text == ";" );

    if( sy_type == NAME_SYMBOL )
    {
        if( length( sy_text ) > MAX_NAME_LENGTH )
        {
            # symbol is longer than the maximum identifier length
            if( ! ( uc_text in longReserved ) )
            {
                # not a long reserrved word - truncate the symbol
                sy_text = substr( sy_text, 1, MAX_NAME_LENGTH );
                uc_text = substr( uc_text, 1, MAX_NAME_LENGTH );
            } # if ! ( uc_text in longReserved )

        } # if length( sy_text ) > MAX_NAME_LENGTH

        if( uc_text in define )
        {
            # symbol is a #define - translate it
            sy_text = define[ uc_text ];
            uc_text = toupper( sy_text );
        } # if uc_text in define

    } # if sy_type == NAME_SYMBOL


} # nextSymbol


function printSymbol()
{
    printf( "%s%s", sy_comments, sy_text );
} # printSymbol


function concatenateSymbols( sy1, sy2,                                 result )
{

    if( sy2 ~ /^[a-zA-Z0-9_]/ && sy1 ~ /[a-zA-Z0-9_]$/ )
    {
        result = sy1 " " sy2;
    }
    else
    {
        result = sy1     sy2;

    } # if sy2 ~ /^[a-zA-Z0-9_]/ && sy1 ~ /[a-zA-Z0-9_]$/;;

return result;
} # concatenateSymbols


function parseProgramHeader(                                         fileList,
                                                              preListComments,
                                                              haveHeaderFiles )
{

    # find the non-standard name files in the program header

    fileList        = "";
    filePosition    = 0;
    haveHeaderFiles = FALSE;
    preListComments = "";
    filePosition    = 0;

    printSymbol();                 # program
    nextSymbol();
    printSymbol();                 # name
    nextSymbol();

    if( sy_text == "(" )
    {
        # have a file list
        preListComments sy_comments;
        nextSymbol();
        while( sy_type == NAME_SYMBOL )
        {
            # have another file name
            if( ! ( uc_text in standardFiles ) )
            {
                # non-standard file name
                files[    uc_text ] = ++ filePosition;
                buffered[ uc_text ] = FALSE;
                ioMode[   uc_text ] = "?";
            } # if ! ( uc_text in standardFiles

            if( ! ( uc_text in standardFiles ) && ! includeNonStandardFiles )
            {
                # must remove non-standard files from the header
                fileList        = fileList sy_comments;
            }
            else
            {
                # is a standard filename or we should leave non-standard
                # files in the header
                if( haveHeaderFiles )
                {
                    # there were preceding standard files so need a ","
                    # to separate this from them
                    fileList    = fileList ",";
                } # if haveHeaderFiles
                fileList        = fileList sy_comments;
                fileList        = fileList sy_text;
                haveHeaderFiles = TRUE;
            } # if ! ( uc_text in standardFiles );;
            nextSymbol();
            if( sy_text == "," )
            {
                # the file name is followed by ","
                fileList = fileList sy_comments;
                nextSymbol();
            } # if sy_text == ","
        } # while sy_type == NAME_SYMBOL

        if( sy_text == ")" )
        {
            # have a closing ")"
            fileList = fileList sy_comments;
            nextSymbol();
        }
        else
        {
            # no ")" after the file list
            error( "Expected \")\", not \"" sy_text "\" "                     \
                   "after the file list in the program header" );
        } # if sy_text == ")";;

        if( haveHeaderFiles )
        {
            # there are some files in the header so we need a file list
            printf( "(%s)", fileList );
        }
        else
        {
            # no header files - just print the comments
            printf( "%s", fileList );

        } # if haveHeaderFiles

    } # if sy_text == "("


} # parseProgramHeader


function parseProgram(                                           bracketDepth,
                                                                       ucLast,
                                                                       fnName,
                                                                         mode,
                                                                          eOp,
                                                                          ptr )
{

    while( sy_type != EOF_SYMBOL )
    {
        if( sy_text == "^" )
        {
            # could indicate buffered file access
            ucLast = toupper( lastSymbol );
            if( ucLast in files )
            {
                # buffered access to a file
                buffered[ ucLast ] = TRUE;
            } # if ucLast in files
            printSymbol();
            nextSymbol();
        }
        else if( uc_text == "TYPE" )
        {
            # type definitions
            if( lastSymbol != ";" )
            {
                # ensure there is a ";" before "type"
                printf( ";" );
            } # if lastSymbol != ";"

            printSymbol();
            nextSymbol();
        }
        else if( uc_text == "PROGRAM" )
        {
            # program header
            parseProgramHeader();
        }
        else if( uc_text in ioFunction )
        {
            # io operation: get/put/reset/rewrite/read/readln/write/writeln
            fnName = uc_text;
            # the file name is the first parameter
            printSymbol();
            nextSymbol();
            if( sy_text == ";" || uc_text == "END" )
            {
                # no parameters - this is OK, e.g.: "readln;"
            }
            else if( sy_text != "(" )
            {
                # something other that (/;/END
                error( "Expected \"(\" after " fnName                         \
                       ", not \"" sy_text "\"" );
            }
            else
            {
                # have a "("
                printSymbol();
                nextSymbol();
                mode = ioFunction[ fnName ];
                if( mode ~ /\^/ )
                {
                    # io operation implies the file is buffered
                    # set it even if it is not a file declared in the
                    # program header
                    buffered[ uc_text ] = TRUE;
                    sub( /\^/, "", mode ); 
                } # if mode ~ /\^/
                if( ! ( uc_text in files ) )
                {
                    # not a file we know about - could be input/output
                    # or a temporary file
                    if( ! ( uc_text in standardFiles ) )
                    {
                        # not a standard file
                        if( sy_type == NAME_SYMBOL )
                        {
                            # is a name
                            if( fnName == "RESET" || fnName == "REWRITE" )
                            {
                                # opening the file
                                note( "Non-header file name: \""             \
                                      uc_text "\""                           );
                            } # if fnName == "RESET" || == "REWRITE"
                        } # if sy_type == NAME_SYMBOL
                    } # if ! ( uc_text in standardFiles )
                }
                else
                {
                    # io operation implies the file I/O modee
                    if( ioMode[ uc_text ] == "?" )
                    {
                        ioMode[ uc_text ] = mode;
                    }
                    else if( ioMode[ uc_text ] != mode )
                    {
                        error( uc_text " is used for both input and output" );
                    } # if ioMode[ uc_text ] == "?";; != mode
                } # if ! ( uc_text in files );;
                printSymbol();
                nextSymbol();
            } # if sy_text == ";" || uc_text == "END;; sy_text !- "(";;
        }
        else if( uc_text == "ENEW" && ENEW == "Q" )
        {
            # cpem non-standard new statement
            # if we convert it to an assignment, p2c sometimes deletes
            # the "name :=" part, so we convert the first parameter to
            # a string and leave it to ppc.awk to fix
            printSymbol();
            nextSymbol();
            printSymbol();
            nextSymbol();
            printf( "'" );
            while( sy_text != "," && sy_text != ")" && sy_type != EOF_SYMBOL )
            {
                printf( "%s", uc_text );
                nextSymbol();
            } # while not at ",", ")" or eof
            printf( "'" );
            if( sy_text != "," )
            {
                # didn't find a comma
                error( "Expected \",\" after \"" lastSymbol "\" "            \
                       "in ENEW statement"                                   );
            } # if sy_text != ","
        }
        else if( ( uc_text == "ENEW" || uc_text == "EDISPOSE" ) &&
                 ENEW == "B" )
        {
            # cpem non-standard new/dispose statement - convert to a block
            ptr = "";
            eOp = ( ( uc_text == "ENEW" ) ? "new" : "dispose" );
            printf( "%s", sy_comments );
            nextSymbol();
            printf( "%s", sy_comments );
            nextSymbol();
            while( sy_text != "," && sy_text != ")" && sy_type != EOF_SYMBOL )
            {
                ptr = concatenateSymbols( ptr, sy_comments sy_text );
                nextSymbol();
            } # while not at ",", ")" or eof
            if( sy_text == "," )
            {
                # found a comma
                ptr = ptr sy_comments;
                nextSymbol();
            }
            else
            {
                # didn't find a comma
                error( "Expected \",\" after \"" lastSymbol "\" "            \
                       "in ENEW/EDISPOSE statement"                          );
            } # if sy_text == ",";;
            if( eOp == "dispose" )
            {
                # dispose - just free the pointer
                printf( "%s(%s)", eOp, ptr );
                bracketDepth = 1;
                while( bracketDepth > 0          &&
                       sy_text     != ";"        &&
                       sy_type     != EOF_SYMBOL )
                {
                    nextSymbol();
                    if( sy_text == "(" )
                    {
                        bracketDepth ++;
                    }
                    else if( sy_text == ")" )
                    {
                        bracketDepth --;
                    } # if sy_text == "(";; == ")"
                } # while bracketDepth > 0 and not at ";" or eof
                if( sy_text == ")" )
                {
                    # found a closing brqcket
                    nextSymbol();
                }
                else
                {
                    # didn't find a closing bracket
                    error( "Expected \")\" after \"" lastSymbol "\" "        \
                            "in ENEW/EDISPOSE statement"                     );
                } # if sy_text == ")";;
            }
            else
            {
                # new - need to set the length and allocate the pointer
                #       in a block
                printf( "begin ENEW_LENGTH := " );
                bracketDepth = 1;
                while( bracketDepth > 0          &&
                       sy_text     != ";"        &&
                       sy_type     != EOF_SYMBOL )
                {
                    printSymbol();
                    nextSymbol();
                    if( sy_text == "(" )
                    {
                        bracketDepth ++;
                    }
                    else if( sy_text == ")" )
                    {
                        bracketDepth --;
                    } # if sy_text == "(";; == ")"
                } # while bracketDepth > 0 and not at ";" or eof
                if( sy_text == ")" )
                {
                    # found a closing brqcket
                    printf( "%s", sy_comments );
                    nextSymbol();
                }
                else
                {
                    # didn't find a closing bracket
                    error( "Expected \")\" after \"" lastSymbol "\" "        \
                            "in ENEW/EDISPOSE statement"                     );
                } # if sy_text == ")";;
                printf( "; %s(%s) end", eOp, ptr );
            } # if eOp == "dispose";;
        }
        else if( sy_type == NAME_SYMBOL )
        {
            # have a name
            ucLast = toupper( lastSymbol );
            if     ( ucLast == "PROCEDURE" || ucLast == "FUNCTION" )
            {
                # this is a procedure/function
                # - ensure it has an uppercase name
                sy_text = toupper( sy_text );
                define[ sy_text ] = sy_text;
            }
            else if( ucLast == "END" )
            {
                # the previous symbol was END, if this isn't END/ELSE/UNTIL
                # there should have been a semi-colon
                if( ! ( uc_text in afterEnd )             )
                {
                    note( "Semicolon inserted between END and " sy_text );
                    printf( ";" );
                } # if ! ( uc_text in afterEnd )
            }
            else if( uc_text == "IF" )
            {
                # the current symbol is IF, if it wasn't preceded by
                # BEGIN/ELSE/DO/REPEAT/:/; there should have been a semi-colon
                if( ! ( ucLast in beforeIf ) )
                {
                    note( "Semicolon inserted between " lastSymbol           \
                          " and " sy_text                                    );
                    printf( ";" );
                } # if ! ( ucLast in beforeIf )
            } # if ucLast == "PROCEDURE" || == "FUNCTION";; ucLast == "END"
            printSymbol();
            nextSymbol();
        }
        else
        {
            # something else
            printSymbol();
            nextSymbol();

        } # if various symbols;;

    } # while sy_type != EOF_SYMBOL

    printf( "%s\n", sy_comments );


} # parseProgram


function writeRcFile(                                                      fn,
                                                                      noFiles )
{

    printf( "# %s\n", srcBaseName ) > RC;

    noFiles = TRUE;

    for( fn in files )
    {
        printf( "%-20s %s    # index: %d mode: %s\n",
                ( buffered[ fn ] ? "BufferedFile" : "UnBufferedFile" ),
                fn,
                files[  fn ],
                ioMode[ fn ] ) > RC;
        noFiles = FALSE;

    } # for fn in files

    if( noFiles )
    {
        printf( "# no non-standard files\n" ) > RC;
    } # if noFiles

    for( fn in buffered )
    {
        if( ! ( fn in files ) )
        {
            # a buffered file not declared in the program header
            printf( "%-20s %s    # index: %d mode: %s\n",
                    ( buffered[ fn ] ? "BufferedFile" : "UnBufferedFile" ),
                    fn,
                    -1,
                    ioMode[     fn ] ) > RC;
        } # if ! ( fn in files )
    } # for fn in files

    close( RC );

} # writeRcFile
