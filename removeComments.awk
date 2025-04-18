# removeComments.awk: remove comments from a Pascal source

BEGIN \
{

    FALSE                    = 0;
    TRUE                     = 1;

    line                     = "";
    ch                       = "";
    cPos                     = -1;
    cMax                     = -2;
    sy                       = ">";
    syU                      = "?";
    syPos                    = -1;
    syLen                    = 0;
    isName                   = FALSE;
    comment1                 = FALSE;
    comment2                 = FALSE;
    commentLine              = -1;
    quote                    = "";

} # BEGIN


{

    line = $0;
    sub( /[\r\n]/, "", line );
    line = line "\n";

    cMax  = length( line );
    cPos  = 1;
    syPos = cPos;

    while( cPos <= cMax )
    {
        isName = FALSE;
        ch     = substr( line, cPos, 1 );

        if( ! comment1 && ! comment2 )
        {
            # not in a comment
            syPos = cPos;
        } # if ! comment1 && ! comment2

        if     ( ch == "\n" )
        {
            # end of line
            cPos ++;
        }
        else if( comment1 )
        {
            # in a possibly-multi-line {} comment
            if( ch != "}" )
            {
                # not at the end of the comment
                cPos ++;
            } # if ch != "}"
        }
        else if( comment2 )
        {
            # in a possibly-multi-line (**) comment
            if( substr( line, cPos, 2 ) != "*)" )
            {
                # not at the end of the comment
                cPos ++;
            } # if substr( line, cPos, 2 ) != "*)"
        }
        else if( ch <= " " )
        {
            # whitespace
            do
            {
                cPos ++;
                ch = substr( line, cPos, 1 );
            }
            while( ch <= " " && ch != "\n" );
        }
        else if( ch ~ /[0-9]/ )
        {
            # number
            cPos ++;
            ch = substr( line, cPos, 1 );
            while( ch ~ /[0-9]/ )
            {
                if( ch == "." && substr( line, cPos + 1, 1 ) != "." )
                {
                    # have a decimal-point
                    cPos ++;
                    ch = substr( line, cPos, 1 );
                } # if ch == "." && substr( line, cPos, 1 ) != "."
                cPos ++;
                ch = substr( line, cPos, 1 );
            } # while ch ~ /[0-9]/
            if( ch == "e" || ch == "E" )
            {
                cPos ++;
                ch = substr( line, cPos, 1 );
                while( ch ~ /[0-9]/ )
                {
                    cPos ++;
                    ch = substr( line, cPos, 1 );
                } # while ch <= " "
            } # if ch == "e" || == "E"
        }
        else if( ch ~ /[a-zA-Z_]/ )
        {
            # identifier/reserved-word
            isName = TRUE;
            ch = substr( line, cPos, 1 );
            while( ch ~ /[a-zA-Z_0-9]/ )
            {
                cPos ++;
                ch = substr( line, cPos, 1 );
            } # while ch ~ /[a-zA-Z_0-9]/
        }
        else if( ch == "{" )
        {
            # {} comment
            cPos ++;
            comment1    = TRUE;
            commentLine = NR;
        }
        else if( ch == "(" && substr( line, cPos + 1, 1 ) == "*" )
        {
            # (**) comment
            cPos       += 2;
            comment2    = TRUE;
            ch          = substr( line, cPos, 1 );
            commentLine = NR;
        }
        else if( ch == "\"" || ch == "'" )
        {
            # string literal
            quote = ch;
            do
            {
                cPos ++;
                ch = substr( line, cPos, 1 );
            }
            while( ch != quote && ch != "\n" );
            cPos ++;
            if( ch == "\n" )
            {
                printf( "**** %d: unterminated string\n", NR );
            } # if ch == "\n"
        }
        else
        {
            # treat everything else as a single character symbol,
            # even :=, <=, etc.
            cPos ++;
        } # if comment1 || comment2;; various characters;;

        syLen = cPos - syPos;
        sy    = substr( line, syPos, syLen );

        if( comment1 )
        {
            # in a possibly-multi-line {} comment
            if( substr( line, cPos, 1 ) == "}" )
            {
                # end of comment
                comment1 = FALSE;
                cPos ++;
            } # if substr( line, cPos, 1 ) == "}"
            sy = "";
        }
        else if( comment2 )
        {
            # in a possibly-multi-line (**) comment
            if( substr( line, cPos, 2 ) == "*)" )
            {
                # end of comment
                comment2 = FALSE;
                cPos += 2;
            } # if substr( line, sPos, 2 ) == "*)"
            sy = "";
        } # if comment1;; comment2

        if( ! comment1 && ! comment2 )
        {
            # not in a possibly mult-line comment
            printf( "%s", sy );
        }
        else if( sy ~ "\n$" )
        {
            # end-of-line in a comment
            printf( "\n" );
        } # if ! comment1 && ! comment2:; sy ~ "\n$"

    } # while cPos <= cMax

}


END \
{

    if( comment1 || comment2 )
    {
        # unterminated comment at EoF
        printf( "\n**** comment starting on line %d is not terminated",
                commentLine );
    } # if comment1 || comment2

} # END
