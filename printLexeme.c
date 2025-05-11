void printLexeme( LEXEME * LEX )
{
 printf( "LX: " );fflush( stdout );
 if( LEX == NULL )
 {
  printf( "NULL\n" );fflush( stdout );
 }
 else
 {
  printf( "%d: ", LEX->U1.LXV );fflush( stdout );
  printf( " {%d}", LEX->U1.LXTOKEN );fflush( stdout );
  switch( LEX->U1.LXTOKEN )
  {
  case TKTAG   : printf( "TAG    " );fflush( stdout ); break;
  case TKBOLD  : printf( "BOLD   " );fflush( stdout ); break;
  case TKDENOT : printf( "DEN    " );fflush( stdout );
       if( LEX->U1.UU.U9.LXDENMD == MDINT )
       {
           printf( "int %d ", LEX->U1.UU.U9.LXDENRP );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDLINT )
       {
           printf( "long int %d ", LEX->U1.UU.U9.LXDENRP );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDBITS )
       {
           printf( "bits       " );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDBYTES )
       {
           printf( "bytes      " );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDREAL )
       {
           printf( "real %f ", LEX->U1.UU.U10.LXDENRPR );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDLREAL )
       {
           printf( "long real %f ", LEX->U1.UU.U10.LXDENRPR );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDBOOL )
       {
           printf( "bool       " );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDCHAR )
       {
           printf( "char       " );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDSTRNG )
       {
           printf( "string (%d) ", LEX->U1.UU.U9.LXDENRP );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDNIL )
       {
           printf( "nil        " );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDCOMPL )
       {
           printf( "compl      " );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDLCOMPL )
       {
           printf( "long compl " );
       }
       else if( LEX->U1.UU.U9.LXDENMD == MDVOID )
       {
           printf( "void       " );
       }
       else
       {
           printf( "? (%p) ", LEX->U1.UU.U9.LXDENMD );
       } // if various modes
       fflush( stdout );
       break;
  case TKSYMBOL: printf( "SYM    " );fflush( stdout ); break;
  default      : printf( "???:%d " );fflush( stdout ); break;
  } // switch LEX->U1.LXTOKEN
  printf( "(%d): [", LEX->U1.LXCOUNT );fflush( stdout );
  int len = LEX->U1.LXCOUNT * CONST_CHARPERW;
  if( len > 32 )
  {
   len = 32;
  } // if len > 32
  while( len > 0 && LEX->U1.UU.STRNG[ len - 1 ] == ' ' )
  {
   len --;
  } // while len > 0 && LEX->U1.UU.STRNG[ len - 1 ] == ' '
  if( len > 0 )
  {
   for( int pos = 0; pos < 10 && pos < len; pos ++ )
   {
    char c = LEX->U1.UU.STRNG[ pos ];
    if( c <= ' ' || c > '~' )
    {
     printf( "[%2x]", c );fflush( stdout );
    }
    else
    {
     printf( "%c", c );fflush( stdout );
    } // if c <= ' ' || c > '~';;
   } // for pos
  } // if len > 0
  printf( "]\n" );fflush( stdout );
 } // if LEX == NULL;;
} // printLexeme
