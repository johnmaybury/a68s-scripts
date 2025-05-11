# pas.awk: Split Pascal sources

BEGIN \
{

    FALSE                        = 0;
    TRUE                         = 1;

    EOF_CHAR                     = "<eof>";

    EOF_SYMBOL                   = "e:";
    STRING_SYMBOL                = "s:";
    NUMBER_SYMBOL                = "n:";
    NAME_SYMBOL                  = "a:";
    OTHER_SYMBOL                 = "o:";
    COMMENT_SYMBOL               = "c:";

    MAX_NAME_LENGTH              = 8;

    longReserved[ "PROCEDURE"  ] = "Y";
    longReserved[ "IMPLEMENT"  ] = "Y";
    longReserved[ "SEGMENTED"  ] = "Y";

    standardFiles[ "INPUT"     ] = 0;
    standardFiles[ "OUTPUT"    ] = 1;

    ioFunction[    "GET"       ] = "^r";
    ioFunction[    "PUT"       ] = "^w";
    ioFunction[    "RESET"     ] = "r";
    ioFunction[    "REWRITE"   ] = "w";
    ioFunction[    "READ"      ] = "r";
    ioFunction[    "READLN"    ] = "r";
    ioFunction[    "WRITE"     ] = "w";
    ioFunction[    "WRITELN"   ] = "w";

    afterEnd[      "ELSE"      ] = "Y";
    afterEnd[      "END"       ] = "Y";
    afterEnd[      "UNTIL"     ] = "Y";

    define[        "LONG"      ] = "INTEGER"; # "LONGINT";
    define[        "EXTERN"    ] = "EXTERNAL";
    define[        "INLINE"    ] = "XQINLINE";
    define[        "XOR"       ] = "XOR9QZ";
    define[        "SEGMENTED" ] = "";

    section[       "CONST"     ] = "Y";
    section[       "LABEL"     ] = "Y";
    section[       "TYPE"      ] = "Y";
    section[       "VAR"       ] = "Y";

    # prefixes for messages
    ERROR_PREFIX                 = "Error: ";
    WARNING_PREFIX               = "Warning: ";
    INFORMATION_PREFIX           = "Note:  ";

    # "declare" some global arrays and variables
    atEof                        = FALSE;
    fileNumber                   = 0;
    filePosition                 = 0;
    c                            = "";
    line                         = "";
    thisLine                     = "";
    fullLine                     = "";
    lineNumber                   = 0;
    lastErrorLineNumber          = 0;
    haveComment                  = FALSE;
    pushBackPos                  = 0;
    lastSymbol                   = ";";
    sy_text                      = "";
    sy_type                      = OTHER_SYMBOL;
    sy_line                      = 0;
    sy_comments                  = "";
    uc_text                      = "";
    sectionName                  = "?";
    sectionFile                  = "?";
    savedText                    = "";
    savedSymbols                 = "";
    delete inFile;
    delete pbLine;
    delete pbText;
    delete pbType;
    delete files;
    delete buffered;
    delete ioMode;
    delete forward;

    # whether to initialise ENEW_LENGTH or not, from the command line
    ENEW = "" ENEW;
    # source file name from the command line
    #        either a pathname or "-" for standard input
    src  = "" src;
    # output folder name from the command line - default "."
    out  = "" out;

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


    warningCount                 = 0;
    errorCount                   = 0;

    # parse the source if possible

    srcBaseName = src;
    while( srcBaseName ~ /[\/\\]/ )
    {
        sub( /^[^\/\\]*[\/\\]/, "", srcBaseName );
    } # while srcBaseName ~ /[\/\\]/

    outputFolder = ( ( out == "" ) ? "." : out );

    openSourceFile( src );

    if( errorCount == 0 )
    {
        # opened the source file - parse it
        parseProgram();
        closeSourceFile();

    } # if errorCount == 0

    printf( "%5d error(s) %5d warning(s) %s\n",
            errorCount, warningCount, srcBaseName );


} # BEGIN


function message( prefix, text )
{

    printf( "** %s %s:%d %s\n",
            prefix,
            srcBaseName,
            lineNumber,
            text );


} # message


function note( text )
{
    message( INFORMATION_PREFIX, text );
} # error


function warning( text )
{
    message( WARNING_PREFIX, text );
    warningCount ++;
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


function nextSymbol()
{

    
    sy_comments = "";
    basicNextSymbol();
    while( sy_type == COMMENT_SYMBOL )
    {
        sy_comments = sy_comments sy_text;
        basicNextSymbol();
    } # while sy_type == COMMENT_SYMBOL

    if( sy_type == NAME_SYMBOL )
    {
        if( length( sy_text ) > MAX_NAME_LENGTH )
        {
            # symbol is longer than the maximum identifier length
            if( ! ( uc_text in longReserved ) )
            {
                # not a lonmg reserrved word - truncate the symbol
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
    printf( "%s%s", sy_comments, sy_text ) > sectionFile;
} # printSymbol


function saveSymbol()
{
    savedText = savedText sy_comments sy_text;

    if( savedSymbols ~ /[a-zA-Z0-9_]$/ && sy_text ~ /^[a-zA-Z0-9_$]/ )
    {
        savedSymbols = savedSymbols " ";
    } # if savedSymbols ~ /[a-zA-Z0-9_]$/ && sy_text ~ /^[a-zA-Z0-9_$]/

    savedSymbols = savedSymbols sy_text;

} # saveSymbol


function mustBe( where, requiredText )
{
    if( uc_text != requiredText )
    {
        error( "Expected \"" requiredText                                    \
               "\", not \"" sy_text "\" after " where                        );
    } # if uc_text != requiredText

} # mustBe


function mustBeSemicolon( where )
{
    mustBe( where, ";" );
} # mustBeSemicolon


function skipSemicolon()
{
    if( sy_text == ";" )
    {
        printSymbol();
        nextSymbol();
    } # if sy_text == ";"

} # skipSemicolon


function parseSection(                                        continueSection )
{

    continueSection = TRUE;

    do
    {
        do
        {
            printSymbol();
            nextSymbol();
        }
        while( sy_text != ";"           &&
               sy_type != EOF_SYMBOL    &&
               ! ( uc_text in section ) &&
               uc_text != "PROCEDURE"   &&
               uc_text != "FUNCTION"    &&
               uc_text != "BEGIN"       );

        if( sy_text == ";" )
        {
            printSymbol();
            nextSymbol();
        } # if sy_text == ":"

        continueSection = ( ! ( uc_text in section ) &&
                            uc_text != "PROCEDURE"   &&
                            uc_text != "FUNCTION"    &&
                            uc_text != "BEGIN"       );
    }
    while( continueSection );

    if( lastSymbol != ";" )
    {
        printf( ";" ) > sectionFile;
    } # if lastSymbol != ";"

    printf( "\n" )    > sectionFile;

} # parseSection


function parseBlock( where, followingSymbol,                       blockDepth )
{

    mustBe( where, "BEGIN" );

    if( uc_text == "BEGIN" )
    {
        # have begin
        blockDepth = 1;
        do
        {
            printSymbol();
            nextSymbol();
            if( uc_text == "BEGIN" || uc_text == "CASE" )
            {
                blockDepth ++;
            }
            else if( uc_text == "END" )
            {
                blockDepth --;
            } # if uc_text == "BEGIN" || == "CASE";; uc_text == "END"
        }
        while( sy_type != EOF_SYMBOL && blockDepth > 0 );
        mustBe( where, "END" );
        if( uc_text == "END" )
        {
            # have "END"
            printSymbol(); 
            nextSymbol();
            mustBe( where, followingSymbol );

        } # if uc_text == "END";;

    } # if uc_text == "BEGIN";;

} # parseBlock


function parseProcedure( procDepth,                             procedureName,
                                                                 bracketDepth,
                                                                     topLevel,
                                                             topLevelExternal )
{

    topLevel     = procDepth < 1;

    savedText    = "";
    savedSymbols = "";
    saveSymbol();
    nextSymbol();

    if( sy_type != NAME_SYMBOL )
    {
        error( "Expected a procedure/function name, not \"" sy_text "\"" );
    }
    else
    {
        # have a procedure name

        topLevelExternal = FALSE;

        if( topLevel )
        {
            # not a nested procedure
            sectionName = uc_text;
        } # if topLevel

        procedureName = sy_text;

        saveSymbol();
        nextSymbol();

        if( sy_text == "(" )
        {
            # have a parameter list
            bracketDepth = 1;
            do
            {
                saveSymbol();
                nextSymbol();
                if( sy_text == "(" )
                {
                    bracketDepth ++;
                }
                else if( sy_text == ")" )
                {
                    bracketDepth --;
                } # if sy_text == "(";; == ")"
            }
            while( sy_type != EOF_SYMBOL && bracketDepth > 0 );

            mustBe( "the " procedureName " parameter list", ")" );
            if( sy_text == ")" )
            {
                saveSymbol();
                nextSymbol();

            } # if sy_text == ";"

        } # if sy_text == "("

        if( sy_text == ":" )
        {
            # have a return type
            while( sy_type != EOF_SYMBOL && sy_text != ";" )
            {
                saveSymbol();
                nextSymbol();
            } # while sy_type != EOF_SYMBOL && sy_text != ";"

        } # if sy_text == ":"

        if( sy_text != ";" )
        {
            # no ";" after the procedure/function hgeader
            mustBeSemicolon( "the " procedureName " header" );
        }
        else
        {
            # have a ";"
            saveSymbol();
            nextSymbol();
            if( uc_text == "EXTERN" || uc_text == "EXTERNAL" )
            {
                # procedure is external
                if( ! topLevel )
                {
                    # nested external procedure
                    printSymbol();
                }
                else
                {
                    # top level external procedure
                    printf( "%s\n",
                            savedSymbols ) > outputFolder "/EXTERN";
                    topLevelExternal = TRUE;
                } # if ! topLevel;;
                nextSymbol();
                mustBeSemicolon( "the procedure/function " procedureName );
            }
            else if( uc_text == "FORWARD" )
            {
                # forward procedure
                if( ! topLevel )
                {
                    # only include forward declarations for non-top level
                    # routines
                    printf( "%s\n",
                            savedText ) > outputFolder "/" sectionName;
                    printSymbol();
                }
                else
                {
                    # have a routine declared as forward at the top-level
                    # include it in the generated FORWARD section
                    printf( "%sFORWARD;\n",
                            savedSymbols ) > outputFolder "/FORWARD";
                    # note it is forward so we don't generate another
                    # forward declaration
                    forward[ procedureName ] = "Y";
                } # if ! topLevel
                nextSymbol();
                mustBeSemicolon( "the procedure/function " procedureName );
            }
            else
            {
                # appears to be an inline procedure
                printf( "%-*.*s%s\n",
                        procDepth, procDepth, " ", procedureName );
                if( topLevel )
                {
                    # create a forward declaration for the procedure
                    if( ! ( procedureName in forward ) )
                    {
                        # the procedure didn't already have a preceding forward
                        # declaration
                        printf( "%sFORWARD;\n",
                                savedSymbols ) > outputFolder "/FORWARD";
                    } # if ! ( procedureName in forward
                    sectionFile = outputFolder "/" sectionName;
                    # remove the paramter and return type
                    savedText = savedSymbols;
                    sub( /[(].*$/, "", savedText );
                    sub( /:.*$/,   "", savedText );
                    if( savedText !~ /;$/ )
                    {
                        savedText = savedText ";";
                    } # if savedText !~ /;$/
                } # if topLevel
                printf( "%s", savedText ) > sectionFile;            

                while( uc_text in section     ||
                       uc_text == "PROCEDURE" ||
                       uc_text == "FUNCTION"  )
                {
                    if( uc_text == "PROCEDURE" || uc_text == "FUNCTION" )
                    {
                        parseProcedure( procDepth + 1 );
                    }
                    else
                    {
                        # const/type/var
                        parseSection();

                    } # if various symbols
              
                } # while uc_text in section
                  #    || uc_text == "PROCEDURE"
                  #    || uc_text == "FUNCTION"

                parseBlock( "the " sectionName " body", ";" );

            } # if various symbols;;

            if( topLevelExternal )
            {
                nextSymbol();
            }
            else
            {
                skipSemicolon();
                printf( "\n" ) > sectionFile;

            } # if topLevelExternal;;

        } # if sy_text != ";";;

    } # if sy_type != NAME_SYMBOL;;

} # parseProcedure


function parseProgram(                                            mainSection,
                                                                    isAModule,
                                                                     mainFile,
                                                                       ucLast,
                                                                       fnName,
                                                                         mode )
{

    mainSection = "unknown";
    mainFile    = outputFolder "/unknown";

    isAModule   = uc_text == "MODULE";

    if( uc_text == "PROGRAM" || uc_text == "MODULE" )
    {
        sectionName = uc_text;
        sectionFile = outputFolder "/" sectionName;
        mainSection - sectionName;
        mainFile    = sectionFile;
        do
        {
            printSymbol();
            nextSymbol();
        }
        while( sy_type != EOF_SYMBOL    &&
               sy_text != ";"           &&
               ! ( uc_text in section ) &&
               uc_text != "PROCEDURE"   &&
               uc_text != "FUNCTION"    );
        mustBeSemicolon( "the program/module header" );
        skipSemicolon();
        while( uc_text == "PROGRAM" )
        {
            # more than "PROGRAM" - skip the extra ones
            warning( "Skipping additional program header" );
            do
            {
                nextSymbol();
            }
            while( sy_type != EOF_SYMBOL    &&
                   sy_text != ";"           &&
                   ! ( uc_text in section ) &&
                   uc_text != "PROCEDURE"   &&
                   uc_text != "FUNCTION"    );
            mustBeSemicolon( "the second/subsequent program header" );
            skipSemicolon();
        } # while uc_text == "PROGRAM"
        if( uc_text == "IMPLEMENT" )
        {
            nextSymbol();
        } # if uc_text == "IMPLEMENT"

    } # if uc_text == "PROGRAM" || == "MODULE"

    while( uc_text in section     ||
           uc_text == "PROCEDURE" ||
           uc_text == "FUNCTION"  )
    {

        if( uc_text == "PROCEDURE" || uc_text == "FUNCTION" )
        {
            parseProcedure( 0 );
        }
        else
        {
            # const/type/var
            sectionName = uc_text;
            sectionFile = outputFolder "/" sectionName;
            parseSection();

        } # if various symbols
              
    } # while uc_text in section || == "PROCEDURE" || == "FUNCTION"

    sectionName = mainSection;
    sectionFile = outputFolder "/BEGIN";

    if( uc_text == "BEGIN" )
    {
        # have a program/module body
        printf( "PROCEDURE PROGRAM_MAIN;\n" )       > sectionFile;
        parseBlock( "the program/module", "." );
        printf( "\n;\nBEGIN\n" )                    > sectionFile;
        if( ENEW != "N" )
        {
            printf( "    ENEW_LENGTH := -1;\n" )    > sectionFile;
        } # if ENEW != "N"
        printf( "    PROGRAM_MAIN\nEND.\n" )        > sectionFile;
#        printf( ".\n" )                            > sectionFile;
    }
    else if( uc_text == "END" )
    {
        # looks like ther is no body - must be a module
        if( ! isAModule )
        {
            error( "Program has no body - expected \"BEGIN\"" );
        } # if ! isAModule
        nextSymbol();
    }
    else
    {
        # symething invalid
        mustBe( "the program/module declarations", "BEGIN" );
    } # if uc_text == "BEGIN";; == "END";;

    mustBe( "the program/module body", "." );

    if( sy_text == "." )
    {
        # have "." - check it is followed by eof
        nextSymbol();
        if( sy_type != EOF_SYMBOL )
        {
            # didn't get EoF
            error( "Expected EoF, not \"" sy_text "\"" );
        } # if sy_type != EOF_SYMBOL
    } # if sy_text != ".";;


} # parseProgram
