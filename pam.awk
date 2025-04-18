# mergP.awk: Merge pascal source sections

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

    define[        "LONG"       ] = "INTEGER"; # "LONGINT";
    define[        "EXTERN"     ] = "EXTERNAL";
    define[        "XOR"        ] = "XOR9QZ";

    section[       "CONST"      ] = "Y";
    section[       "LABEL"      ] = "Y";
    section[       "TYPE"       ] = "Y";
    section[       "VAR"        ] = "Y";
    proc[          "PROCEDURE"  ] = "Y";
    proc[          "FUNCTION"   ] = "Y";

    # prefixes for messages
    ERROR_PREFIX                  = "Error: ";
    WARNING_PREFIX                = "Warning: ";

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
    lastSymbol                    = ";";
    sy_text                       = "";
    sy_type                       = OTHER_SYMBOL;
    sy_line                       = 0;
    sy_comments                   = "";
    uc_text                       = "";
    elementCount                  = 0;
    elementText                   = "";
    elementDef                    = "";
    delete inFile;
    delete eDef;
    delete eText;

    # output file name from the command line
    out         = "" out;

    # first  source file pathname from the command line
    src1        = "" src1;
    # second, third, etc. source file pathnames from the command line
    src2        = "" src2;
    src3        = "" src3;
    src4        = "" src4;
    src5        = "" src5;
    src6        = "" src6;
    src7        = "" src7;
    src8        = "" src8;
    src9        = "" src9;
    src[ 2 ]    =    src2;
    src[ 3 ]    =    src3;
    src[ 4 ]    =    src4;
    src[ 5 ]    =    src5;
    src[ 6 ]    =    src6;
    src[ 7 ]    =    src7;
    src[ 8 ]    =    src8;
    src[ 9 ]    =    src9;
    MAX_SOURCES = 9;

    # parse the sources if possible

    warningCount                 = 0;
    errorCount                   = 0;

    sectionType1                 = "?";
    sectionType2                 = "?";
    sectionType                  = "?";
    headerComments               = "";

    srcBaseName = src1;

    if( out == "" )
    {
        # no output file specified
        printf( "** Output file name required.\n" );
        errorCount ++;

    } # if out == ""

    if( errorCount == 0 )
    {
        # OK to try parsing the first source
        openSourceFile( src1 );

        if( errorCount == 0 )
        {
            # opened the source file - parse it
            parseSection();
            closeSourceFile();

            sectionType1 = sectionType;

        } # if errorCount == 9

    } # if errorCount == 0

    sPos = 1;
    for( sPos = 2; sPos <= MAX_SOURCES && errorCount == 0; sPos ++ )
    {
        if( src[ sPos ] != "" )
        {
            # have an additional source
            srcBaseName =   src[ sPos ];
            openSourceFile( src[ sPos ] );
            if( errorCount == 0 )
            {
                # opened the source file - parse it
                parseSection();
                closeSourceFile();

                sectionType2 = sectionType;

            } # if errorCount == 0

            if( errorCount == 0 && sectionType1 != sectionType2 )
            {
                # the sources contained different sections
                error( "Different sections: " sectionType1                   \
                       " and "                sectionType2                   );
 
            } # if errorCount == 0 && sectionType1 != sectionType2

        } # if srcBaseName != ""

    } # for sPos

    if( errorCount == 0 )
    {
        # sources parsed OK and they contained the same type of
        # section - output the merged sections
        mergeSections();

    } # if errorCount == 0

    if( errorCount != 0 || warningCount != 0 )
    {
        # errors parsing the sources
        printf( "**** %5d error(s) %5d warning(s) %s\n",
                errorCount, warningCount, srcBaseName );

    } # if errorCount != 0 || warningCount != 0

} # BEGIN


function message( prefix, text )
{

    printf( "%s %s:%d %s\n",
            prefix,
            srcBaseName,
            lineNumber,
            text );
    if( out != "" )
    {
        printf( "(*\n%s %s:%d %s\n*)\n",
                prefix,
                srcBaseName,
                lineNumber,
                text )                                           >> out;
    } # if out != ""

} # message


function warning( text )
{
    message( WARNING_PREFIX, text );
    warningCount ++;
} # error


function error( text )
{
    message( "** " ERROR_PREFIX, text );
    errorCount ++;
} # error


function openSourceFile( srcPath )
{

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
#    else if( c == "#" )
#    {
#        # pre-processor directive ?
#        preprocessorDirective();
#    }
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


function skipToSemicolon()
{
    do
    {
        nextSymbol();
    }
    while( sy_type != EOF_SYMBOL && sy_text != ";" );

} # skipToSemicolon


function addSymbol()
{

    if( sy_text ~ /^[a-zA-Z0-9_]/ && elementDef ~ /[a-zA-Z0-9_]$/ )
    {
        elementDef = elementDef " " sy_text;
    }
    else
    {
        elementDef = elementDef     sy_text;

    } # if sy_text ~ /^[a-zA-Z0-9_]/ && elementDef ~ /[a-zA-Z0-9_]$/;;

    elementText = elementText sy_comments sy_text;

} # addSymbol


function addAndNextElementSymbol(                                 recordDepth,
                                                                   recordLine )
{

    addSymbol();
    nextSymbol();

    if( uc_text == "RECORD" )
    {
        # parsing a record type
        recordDepth = 1;
        recordLine  = sy_line;
        do
        {
            addSymbol();
            nextSymbol();
            if( uc_text == "RECORD" )
            {
                recordDepth ++;
            }
            else if( uc_text == "END" )
            {
                recordDepth --;
            } # if uc_text == "RECORD";; == "END"
        }
        while( recordDepth > 0 && sy_type != EOF_SYMBOL );

        if( uc_text == "END" )
        {
            addSymbol();
            nextSymbol();
        }
        else
        {
            error( "Expected \"END\" to terminate the RECORD in line "       \
                   recordLine                                                );

        } # if uc_text == "END";;

    } # if uc_text == "RECORD"

} # addAndNextElementSymbol


function parseProcElement(                                        elementName,
                                                                 bracketDepth )
{

    elementDef   = "";
    elementText  = "";

    addAndNextElementSymbol();
    elementName  = uc_text;

    addAndNextElementSymbol();
    if( sy_text == "(" )
    {
        # have parameters
        addAndNextElementSymbol();
        bracketDepth = 1;
        do
        {
            addAndNextElementSymbol();
            if( uc_text == "(" )
            {
                bracketDepth ++;
            }
            else if( uc_text == ")" )
            {
                bracketDepth --;
            } # if uc_text == "(";; == ")"
        }
        while( bracketDepth > 0 && sy_type != EOF_SYMBOL );

        if( sy_text != ")" )
        {
            # no ")" after the parameters
            error( "Expected \")\" after the parameters of " elementName     \
                   ", not \"" sy_text "\""                                   );
        }
        else
        {
            # have ")"
            addSymbol();
            nextSymbol();

        } # if sy_text != ")";;

    } # if sy_text == "("

    if( sy_text == ":" )
    {
        # have a return type
        while( sy_type != EOF_SYMBOL && sy_text != ";" )
        {
            addAndNextElementSymbol();
        } # while sy_type != EOF_SYMBOL && sy_text != ";"

    } # if sy_text != ":";;

    if( sy_text == ";" )
    {
        # have a ";" after the procedure header
        addAndNextElementSymbol();
        if( uc_text == "FORWARD" || uc_text == "EXTERNAL" )
        {
            # have FORWARD/EXTERNAL
            addSymbol();
            nextSymbol();

        } # if uc_text == "FORWARD" || == "EXTERNAL"

    } # if sy_text == ";"

    if( sy_text != ";" )
    {
        error( "Expected \";\" after the definition of " elementName        \
               ", not \"" sy_text "\""                                      );
    }
    else
    {
        addSymbol()
        nextSymbol();
        while( sy_text == ";" )
        {
            # skip extraneous ";" that may have been added by pas.awk
            nextSymbol();
        } # while sy_text == ";"

    } # if sy_text != ";";;

    if( ! ( elementName in eDef ) )
    {
        # this is the first definition of this element
        eDef[      elementName ] = elementDef;
        eText[ ++ elementCount ] = elementText;
    }
    else if( elementDef != eDef[ elementName ] )
    {
        # the element is already defined but has a different definition
        warning( "Different definition of " elementName );

    } # if ! ( elementName in eDef );; elementDef != eDef[ elementName ]

} # parseProcElement


function parseSimpleElement(                                      elementName )
{

    elementName = uc_text;
    elementDef  = "";
    elementText = "";

    do
    {
        addAndNextElementSymbol();
    }
    while( sy_type != EOF_SYMBOL && sy_text != ";" );

    if( sy_text != ";" )
    {
        error( "Expected \";\" after the definition of " elementName );
    }
    else
    {
        addSymbol()
        nextSymbol();
        while( sy_text == ";" )
        {
            # skip extraneous ";" that may have been added by pas.awk
            nextSymbol();
        } # while sy_text == ";"

    } # if sy_text != ";";;

    if( ! ( elementName in eDef ) )
    {
        # this is the first definition of this element
        eDef[      elementName ] = elementDef;
        eText[ ++ elementCount ] = elementText;
    }
    else if( elementDef != eDef[ elementName ] )
    {
        # the element is already defined but has a different definition
        warning( "Different definition of " elementName );

    } # if ! ( elementName in eDef );; elementDef != eDef[ elementName ]

} # parseSimpleElement


function parseVarElement(                                         elementName,
                                                                    varNumber,
                                                                     varNames )
{

    elementName = uc_text;
    elementDef  = "";
    elementText = "";

    varNames[ uc_text ] = "Y";
    addSymbol();
    nextSymbol();

    while( sy_text == "," )
    {
        addSymbol();
        nextSymbol();
        if( sy_type != NAME_SYMBOL )
        {
            error( "Expected a name after \",\", not \"" sy_text "\"" );
        }
        else
        {
            varNames[ uc_text ] = "Y";
            addSymbol();
            nextSymbol();

        } # if sy_type != NAME_SYMBOL;;
    } # while sy_text == ","

    if( sy_text != ":" )
    {
        # no ":" ?
        error( "Expected \":\" in the declaration of " elementName );
    }
    else
    {
        # have a ":"
        do
        {
            addAndNextElementSymbol();
        }
        while( sy_type != EOF_SYMBOL && sy_text != ";" );

    } # if sy_text != ":";;

    if( sy_text != ";" )
    {
        error( "Expected \";\" after the declaration of " elementName );
    }
    else
    {
        addSymbol()
        nextSymbol();
        while( sy_text == ";" )
        {
            # skip extraneous ";" that may have been added by pas.awk
            nextSymbol();
        } # while sy_text == ";"

    } # if sy_text != ";";;

    varNumber = 0;

    for( elementName in varNames )
    {
        if( ! ( elementName in eDef ) )
        {
            # this is the first definition of this element
            if( ( ++ varNumber ) == 1 )
            {
                # this is the first variable
                elementCount ++;
            } # if ( ++ varNumber ) == 1

            eDef[   elementName ] = elementDef;
            eText[ elementCount ] = elementText;
        }
        else if( elementDef != eDef[ elementName ] )
        {
            # the element is already defined but has a different definition
            warning( "Different definition of " elementName );

        } # if ! ( elementName in eDef );; elementDef != eDef[ elementName ]

    } # for elementName in varNames


} # parseVarElement


function parseSection(                                        continueSection )
{

    sectionType = uc_text;

    if( sectionType in proc )
    {
        # merging FORWARD or EXTERN procedure lists
        sectionType = "PROCEDURE";
        if( sy_comments !~ /\n$/ )
        {
            sy_comments = sy_comments "\n";
        } # if sy_comments !~ /\n$/
        while( uc_text in proc )
        {
            parseProcElement();

        } # while uc_text in proc
        if( sy_type != EOF_SYMBOL )
        {
            # unexpected text in the section
            error( "Expected end-of-file, not \"" sy_text "\"" );

        } # if sy_type != EOF_SYMBOL        
    }
    else if( sectionType in section )
    {
        # have a CONST/TYPE/VAR section header
        if( headerComments != "" && sy_comments != "" )
        {
            headerComments = headerComments "\n";
        } # if headerComments != "" && sy_comments != ""

        headerComments = headerComments sy_comments;

        nextSymbol();

        while( sy_type != EOF_SYMBOL )
        {
            # possibly have another element
            if( sy_type != NAME_SYMBOL )
            {
                # didn't get a name
                error( "Expected a " sectionType " name, not "              \
                       sy_text                                              );
                skipToSemicolon();
            }
            else if( sectionType == "VAR" )
            {
                # the element should be a variable declaration
                parseVarElement();
            }
            else
            {
                # must be a CONST or TYPE
                parseSimpleElement();

            } # if sectionType == "VAR";;

        } # while sy_type != EOF_SYMBOL
    }
    else
    {
        # the section didn't start with PROCEDURE/FUNCTION/CONST/TYPE/VAR
        error( "Expected PROCEDURE/FUNCTION/CONST/TYPE/VAR, not \""          \
               sy_text "\""                                                  );

    } # if sectionType in proc;; sectionType in section;;


} # parseSection


function mergeSections(                                                  ePos,
                                                                      printed )
{

    if( sectionType in proc )
    {
        printf( "%s", headerComments )                  >> out;
    }
    else
    {
        printf( "%s%s\n", headerComments, sectionType ) >> out;

    } # if sectionType in proc;;

    for( ePos = 1; ePos <= elementCount; ePos ++ )
    {
        if( ! ( ePos in printed ) )
        {
            printf( "%s", eText[ ePos ] )               >> out;
            printed[ ePos ] = "Y";

        } # if ! ( ePos in printed )

    } # for e Pos

    printf( "\n" )                                      >> out;

} # mergeSections
