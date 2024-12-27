// Program to make a WAV file from an ETA file
//
// This should probably compile ok on any platform where shorts are 2 bytes and
// longs are 4 bytes.  Big endian architechture such as SunSparc or Motorola chips
// are tested for, and the wav files should still be correct.
//
// (c) S.D.Sykes July 2001, all rights reserved, you may not copy or re-use this code
// without my permission.

#include <stdio.h>
#include <errno.h>
#include <math.h>
#include <string.h>

// #define MAPPING "h tiea n o s"  // with an Eb
#define MAPPING "h t ei n o sa"  // only the white notes

#define KHZ 12000       // kilohertz
#define SECS 1000		// max seconds of wav
#define FADE 2.2		// seconds to fade at the end
#define MAXRTL 100000	// eta buffer length
#define STCTOLEN 0.05   // length of staccato tones in seconds
#define GAP 0.025       // inter-note gap in seconds in normal style
// #define DEBUG

unsigned char buf[KHZ * SECS];
int bufposn;   // note that globals are always initialised to zero in C
int curscale = 5, curdur = 4, curvol = 7, curbpm = 300;
char curstyle = 'c';
char name[13];
int namep;

union {        // I've always wanted to use unions for something...
  struct {
    char  riff[4];
    long  len;
    char  wavefmt[8];
    long  fmtlen;
    short z1;
    short channels;
    long  rate;
    long  bytepsec;
    short bytepsample;
    short bitpsample;
    char  data[4];
    long  datalen;
  } head;
  unsigned char obuf[44];
} hu;

void addbing(float len, float freq, int level, char style) {
  float period;
  int cycles = 1;
  int counter = 0;
  int endpoint;
  int peaklevel = 8 * level;
  const int pi = 3.14159;
  static float prevwavpoint = 0;

  endpoint = bufposn + len * KHZ;
  if (freq) {
    period = (float)KHZ / freq;
  } else {
    period = KHZ * SECS;  // in case we are passed a frequency of zero
  }
                          // 1 cycle should take place in period samples
  while (bufposn < endpoint && bufposn < SECS * KHZ) {
    buf[bufposn] = sin(2 * pi * (counter / period + prevwavpoint)) * peaklevel + 128; // sine wave
//    buf[bufposn] = (2 * ((counter / period)-(int)(counter / period)) - 1) * peaklevel + 128; // saw
//    buf[bufposn] = counter/period-(int)(counter/period) > .5 ? peaklevel+128 : 128-peaklevel; // square
    switch (style) {
      case 's': {   // staccato - silence after short amount of note
        if ((float)counter / KHZ > STCTOLEN) {
          buf[bufposn] = 128;
        }
      }
      case 'n': {  // normal - make small gap at end of note
        if (len > GAP * 2 && counter > len * KHZ - GAP * KHZ) {
          buf[bufposn] = 128;
        }
      }
      case 'c': {  // continuous - nothing to do here
      }
    } 
    bufposn ++;
    counter ++;
  }
  if (style=='c') prevwavpoint = counter / period + prevwavpoint;
  else prevwavpoint = 0;
}

void writewav() {
  int i;
  FILE *fd = stdout;

  union {                 // Another union!  Never use one your whole life, then two come at once...
    short a;              // Suns and motorola are big endian, dec alpha and intel are little endian
    unsigned char b[2];   // this union is used to test endian-ness
  } endian_test;

  strncpy(hu.head.riff, "RIFF", 4);
  strncpy(hu.head.wavefmt, "WAVEfmt ", 8);
  hu.head.fmtlen = 16;
  hu.head.z1 = 1;
  hu.head.channels = 1;
  hu.head.rate = KHZ;
  hu.head.bytepsec = KHZ;
  hu.head.bytepsample = 1;
  hu.head.bitpsample = 8;
  strncpy(hu.head.data, "data", 4);
  hu.head.datalen = bufposn;
  hu.head.len = bufposn + 36;

  endian_test.a = 1;
  if (endian_test.b[1]) {     // this must be a big endian machinie
    for (i=0; i<44; i++) {      // write header
      switch (i) {
        case 4: case 5: case 6: case 7: fprintf(fd, "%c", hu.obuf[11-i]); break;
        case 16: case 17: case 18: case 19: fprintf(fd, "%c", hu.obuf[35-i]); break;
        case 20: case 21: fprintf(fd, "%c", hu.obuf[41-i]); break;
        case 22: case 23: fprintf(fd, "%c", hu.obuf[45-i]); break;
        case 24: case 25: case 26: case 27: fprintf(fd, "%c", hu.obuf[51-i]); break;
        case 28: case 29: case 30: case 31: fprintf(fd, "%c", hu.obuf[59-i]); break;
        case 32: case 33: fprintf(fd, "%c", hu.obuf[65-i]); break;
        case 34: case 35: fprintf(fd, "%c", hu.obuf[69-i]); break;
        case 40: case 41: case 42: case 43: fprintf(fd, "%c", hu.obuf[83-i]); break;
        default: fprintf(fd, "%c", hu.obuf[i]);
      }
    }
  } else { // little endian
    for (i=0; i<44; i++) {      // write header
      fprintf(fd, "%c", hu.obuf[i]);
    }
  }

  for (i=0; i<(bufposn - FADE * KHZ) ; i++) { // write non faded output
    fprintf(fd, "%c", buf[i]);
  }
  for (; i<bufposn; i++) {    // write output fading to nothing, log law fade
    fprintf(fd, "%c", (int)((buf[i]-128) * (pow(2,(bufposn - i)/(FADE * KHZ))-1) + 128));
  }
}

float lens[MAXRTL], freqs[MAXRTL];
int levels[MAXRTL];
char styles[MAXRTL];
int outcount = 0;

// parseeta does all the work of parsing the eta.

void parseeta(char * inbuf) {
  int i;

  for (i=0; i<strlen(inbuf); i++) {
        switch (tolower(inbuf[i])) {
          case 'e':
          case 't':
          case 'a':
          case 'o':
          case 'n':
          case 'i':
          case 's':
          case 'h': {
            int noteval;
            float base;
            const char *notes = MAPPING;
            // handle note
            noteval= (int)index(notes,inbuf[i]) - (int)notes; // filthy
            base = 261.626 * pow(2, curscale - 4);  // A4 is 440Hz, C4 is 261.626. A4 is the lowest note.
            freqs[outcount] = pow(2, (log(base) / log(2) + (float)noteval/12));
            levels[outcount] = curvol;
            if (!lens[outcount]) lens[outcount] = (60.0/curbpm) / ((float)curdur / 4);
            styles[outcount] = curstyle;
            outcount++;
            break;
          }
        }
  }
#ifdef DEBUG
  fprintf(stderr,"total notes=%d\n",outcount);
#endif
  for (i=0; i<outcount; i++) {
#ifdef DEBUG
   fprintf(stderr, "Wrote: len: %f, freq: %f, lev: %d, style: %c\n", lens[i], freqs[i], levels[i], styles[i]);
#endif
   addbing(lens[i], freqs[i], levels[i], styles[i]);
  }
}

main(int argc, char *argv[]) {
  char inbuf[MAXRTL];
  char c;
  int count=0;
  if (argc != 1) {
    fprintf(stderr, "Usage: eta2wav <etafile >wavfile\n");
    exit(1);
  }
  while (count < MAXRTL && (c = getc(stdin))!= EOF) {
   inbuf[count++] = c;
  }
  inbuf[count] = '\0';

  parseeta(inbuf);

  writewav();

  exit(0);
}
