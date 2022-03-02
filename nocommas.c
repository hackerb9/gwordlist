#include <stdio.h>

/* Google's word lists after 2020 are in a slow format because they
   now use a comma character as a subfield separator. The problem is
   that commas are allowed as data in the first field, so one cannot
   simply split lines into fields using a regular expression.

   One possible solution is to create a simple statemachine
   preprocessor that will turn all the commas that come after the
   first tab on a line into spaces. Space is not treated as data in
   any of the fields, so it makes sense to use it as a field separator.

   Input:
   WORD [ TAB YEAR COMMA WORD_COUNT COMMA BOOK_COUNT ]+ NEWLINE

   Output:
   WORD [ TAB YEAR SPACE WORD_COUNT SPACE BOOK_COUNT ]+ NEWLINE

 */
int main() {
  int state = 0;		/* 0: Beginning of line until first TAB */
				/* 1: After first TAB until NEWLINE */

  int c;
  while ( (c = getchar()) != EOF )  {
    switch (c) {
    case ',':
      if (state == 1) c = ' ';
      break;
    case '\t':
      state = 1;
      break;
    case '\n':
      state = 0;
      break;
    }
    putchar(c);
  }
  return 0;
}
