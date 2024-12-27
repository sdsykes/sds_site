/*
    These libraries are part of the ETA C Compiler project by Stephen Sykes

    Copyright (C) 2003  Stephen Sykes

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    Stephen Sykes - etacc.9.sts@xoxy.net
*/

#ifndef _LIBETA_H

#define _LIBETA_H	1

#ifndef EOF
# define EOF (-1)
#endif

#ifndef NULL
# define NULL 0
#endif

#define stdin 0
#define stdout 1
#define stderr 2

char *strcpy(char *a, char *b) {
  char *x = a;
  while(*a++ = *b++);
  return x;
}

char *strncpy(char *a, char *b, int n) {
  char *x = a;
  while(n-- && (*a++ = *b++));
  while(n-- && *a) *a++ = '\0';
  return x;
}

void *memset(void *a, char c, int n) {
  void *x = a;
  while(n--) *(char *)a++ = c;
  return x;
}

int strlen(char *s) {
  int i = 0;
  while(*s++) i++;
  return i;
}

int atoi(char *s) {
  int i, n, sign;
  for(i=0; s[i]==' ' || s[i]=='\n' || s[i]=='\t'; i++);
  sign=1;
  if (s[i]=='+' || s[i]=='-') sign = (s[i++]=='+') ? 1 : -1;
  for(n=0; s[i] >= '0' && s[i] <= '9'; i++) n = 10 * n + s[i] - '0';
  return(sign * n);
}

int strcmp(char *s, char *t) {
  for(; *s == *t; s++, t++) if (*s == 0) return(0);
  return(*s - *t);
}

char *strchr(char *s, char c) {
  while(*s && *s != c) s++;
  if (!*s) return NULL;
  return s;
}

int isupper(int c) {
  return(c >= 'A' && c <= 'Z');
}

int islower(int c) {
  return(c >= 'a' && c <= 'z');
}

int isalpha(int c) {
  return(isupper(c) || islower(c));
}

int tolower(int c) {
  return(isupper(c) ? c + 'a' - 'A' : c);
}

int toupper(int c) {
  return(islower(c) ? c - 'a' + 'A' : c);
}

#endif
