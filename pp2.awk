# pp2.awk: Additional Pascal post-processing


# replace WRITELN(ERROR...) with WRITELN(...) for the PERQ code generator
/WRITELN *[(] *ERROR/ \
{
    gsub( /WRITELN *[(] *ERROR *,/,   "WRITELN(", $0 );
    gsub( /WRITELN *[(] *ERROR *[)]/, "WRITELN",  $0 );
} # WRITELN(ERROR...)

# fix incorrect name generation for standard prelude routines with names
# exactly 4 (SZWORD) characters long
/WHILE *[(]* *HI *<= *RTNLENGT/ \
{
    sub( /HI *<= *RTNLENGT[A-Z]*/, "HI<=STRLEN (* was: RTNLENGT *)", $0 );
} # fix external name generation

# remove blank lines
{
    if( $0 !~ /^ *$/ )
    {
        printf( "%s\n", $0 );
    } # if $0 !~ /^ *$/

} # remove blank lines
