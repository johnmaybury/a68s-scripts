# pp2.awk: Additional Pascal liba68s post-processing

BEGIN \
{

    FALSE               = 0;
    TRUE                = 1;

    inCaseSeveral       = FALSEl
    seenCase0           = FALSE;

} # BEGIN


# ensure the declaration of MAXREAL ends with a semicolon
/^ *MAXREAL *: *REAL *$/ \
{
    sub( /: *REAL/, ":REAL;", $0 );
} # fix declaration of MAXREAL


# fix (?) the declaration of MAXR
/FUNCTION  *MAXR  *REAL/ \
{
    sub( /MAXR  *REAL/, "MAXR: REAL", $0 );
} # MAXR declaration


# missing ")" in RNSTART ( which has a comment saying it should be written
#                          in assembler )
/SETMYSTATIC *[(] *GETCALLER *[(] *RNIB *[)] *;/ \
{
    sub( /SETMYSTATIC *[(] *GETCALLER *[(] *RNIB *[)] *;/,
         "SETMYSTATIC(GETCALLER(RNIB));", $0 );
} # missing ")"

# ensure each RECORD CASE SEVERAL has a case for 0
# note that the RECORD is not necessarily on the same line as the CASE
/CASE SEVERAL/ \
{
    inCaseSeveral = TRUE;
    seenCase0     = FALSE;
} # start of CASE SEVERAL
/^ *0 *[:,]/ \
{
    seenCase0 = TRUE;
} # have case 0
/^ *END *; *$/ \
{
    if( inCaseSeveral && ! seenCase0 )
    {
        case0 = $0;
        sub( /E.*$/, "0: ();", case0 );
        printf( "%s\n", case0 );
    } # if inCaseSeveral && ! seenCase0
    inCaseSeveral = FALSE;
} # END possibly of CASE SEVERAL


# WRITELN(OUTPUT...) -> WRITELN(...)
/WRITELN *[(] *OUTPUT *[,)]/ \
{
    gsub( /WRITELN *[(] *OUTPUT *[)]/, "WRITELN",  $0 );
    gsub( /WRITELN *[(] *OUTPUT *,/,   "WRITELN(", $0 );
} # WRITELN(OUTPUT


# WRITE(OUTPUT...) -> WRITE(...)
/WRITE *[(] *OUTPUT *[,)]/ \
{
    gsub( /WRITE *[(] *OUTPUT *[)]/, "WRITE",  $0 );
    gsub( /WRITE *[(] *OUTPUT *,/,   "WRITE(", $0 );
} # WRITE(OUTPUT


# remove blank lines
{
    if( $0 !~ /^ *$/ )
    {
        printf( "%s\n", $0 );
    } # if $0 !~ /^ *$/

} # remove blank lines
