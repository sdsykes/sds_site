/*$NetBSD: pig.c,v 1.8 1999/09/18 19:38:53 jsm Exp $*/

/*-
 * Copyright (c) 1992, 1993
 *The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
#include "libeta.h"

char buf[100];

int
main(argc, argv)
     int argc;
     char *argv[];
{
  int len;
  int ch;
  for (len = 0; (ch = getchar()) != EOF;) {
    if (isalpha(ch)) {
      if (len >= sizeof(buf) - 1) {
	printf("Ate too much!\n");
        return;
      }
      buf[len++] = ch;
      continue;
    }
    if (len != 0) {
      pigout(buf, len);
      len = 0;
    }
    (void)putchar(ch);
  }
  //  exit(0);
}

void
pigout(buf, len)
     char *buf;
     int len;
{
  int ch, start, i;
  int olen, allupper, firstupper;

  /* See if the word is all upper case */
  allupper = firstupper = isupper(buf[0]);
  for (i = 1; i < len && allupper; i++)
    allupper = allupper && isupper(buf[i]);

  /*
   * If the word starts with a vowel, append "way".  Don't treat 'y'
   * as a vowel if it appears first.
   */
  if (strchr("aeiouAEIOU", buf[0]) != NULL) {
    buf[len] = '\0';
    (void)printf("%s%s", buf, allupper ? "WAY" : "way");
    return;
  }

  /*
   * Copy leading consonants to the end of the word.  The unit "qu"
   * isn't treated as a vowel.
   */
  if (!allupper)
    buf[0] = tolower(buf[0]);
  for (start = 0, olen = len;
       !strchr("aeiouyAEIOUY", buf[start]) && start < olen;) {
    ch = buf[len++] = buf[start++];
    if ((ch == 'q' || ch == 'Q') && start < olen &&
	(buf[start] == 'u' || buf[start] == 'U'))
      buf[len++] = buf[start++];
  }
  if (firstupper)
    buf[start] = toupper(buf[start]);
  buf[olen+start] = '\0';
  (void)printf("%s%s", buf + start, allupper ? "AY" : "ay");
}

