/* 6502 and PET emulator - credit me if you use this */
/* Stephen Sykes, 2005 */
#include <stdio.h>
#include <string.h>
#include <curses.h>
#include <time.h>
#include <stdlib.h>

int pc; /* program counter */
int operand_addr; /* operand */
int C,Z,I,D,B,V,S; /* flags */
int i; /* current instruction */
int t,s,h; /* general use */
int pclock; /* increments once per instruction */
int debug_flag;
int pet_flag;
unsigned char *p; /* pointer to operand */
unsigned char mem[0x10000]; /* memory */
unsigned char a,x,y,sp; /* registers */

/* this table maps ascii key codes to the pet keyboard */
char *keytab = " ./  p/ 7 ] . 6 6 p     t7      r(0)1*+2,4WgcovGn^f_NVO>F?T\\swldiHZYI9QJRCKSL[b<D8AP:;a@`BXq3j=- HZYI9QJRCKSL[b<D8AP:;a@`BX   57";

/* this table maps each instruction code to an instruction */
char *insttab = ")<   <% ><%  <% '<   <% +<   <% 7$  ($A @$A ($A &$   $A *$   $A C2   2; =2; 62; '2   2; +2   2; D#   #B ?#B 6#B &#   #B *#   #B  F  HFG 1 L HFG 'F  HFG NFM  F  :89 :89 J8I :89 &8  :89 +8K :89 .,  .,/ 5,0 .,/ ',   ,/ +,   ,/ -E  -E3 4E  -E3 &E   E3 *E   E3 ";

/* this table maps the addressing modes */
char *amodetab = "2133024425660788";

void set_ZS(x) {
  Z = x ? 0 : 2;
  S = x & 0x80;
}

void cmp(x) {
  set_ZS(x - *p);
  C = x < *p ? 0 : 1;
}

void plp() {
  set_ZS(t = mem[(++sp & 0xFF) + 0x100]);
  C = t & 1;
  Z = t & 2;
  I = t & 4;
  D = t & 8;
  B = t & 16;
  V = t & 64;
}

void push_pc() {
  mem[(sp-- & 0xFF) + 0x100] = pc / 0x100;
  mem[(sp-- & 0xFF) + 0x100] = pc;
}

void interrupt() {
  push_pc(); 
  mem[(sp-- & 0xFF) + 0x100] = C|Z|I|D|B|V|S|32;
  I = 4;
  pc = mem[0xFFFE] + mem[0xFFFF] * 0x100;
}

inline void incpc() {
  pc = (pc + 1) & 0xFFFF;
}

void usage(char *name) {
  printf("Usage: %s rom_file [speed]\n", name);
  exit(0);
}

void read_rom(char *v[]) {
  FILE *rom_fp;
  int load_pos = 0xC000;

  rom_fp = fopen(v[1], "rb");
  if (!rom_fp) {
    perror(v[0]);
    exit(1);
  }
  while((s = fgetc(rom_fp)) != -1) mem[0xFFFF & load_pos++] = s; /* read given rom into memory */
  if (load_pos == 0x10000) { /* if rom was exactly 16384 bytes, go into pet mode */
    pet_flag = 1;
    pc = mem[0xFFFC] + mem[0xFFFD] * 0x100;
  } else {
    pet_flag = 0;
    pc = 0xC000; /* set up start address */
  }
}

void load_save() {
  unsigned char *u;
  FILE *io_fp;

  p = mem + 0x200 + mem[0x77]; /* points to BASIC text buffer */
  if (*p && (u = strchr(++p, '"'))) { /* grab filename from the line buffer */
    *u = 0;
    mem[0x77] = u - mem + 1; /* move TXTPTR */
    io_fp = fopen(p, pc == 0xFFD6 ? "rb" : "wb");
    if (io_fp) { /* LOAD or SAVE */
      if (pc == 0xFFD6) { /* LOAD */
        fgetc(io_fp);
        t = 0x401;
        for(fgetc(io_fp); (s = fgetc(io_fp)) != -1; mem[0xFFFF & t++] = s);
        for(p = mem + 42; p < mem + 47;) {
          *p++ = t % 0x100;
          *p++ = t / 0x100;
        }
      } else {
        s = 0x3FF;
        t = 3;
        while(t) {  /* output the program - three NULLS in a row indicate the end */
          if (mem[0xFFFF & s] == 0) t--;
          else t = 3;
          fputc(mem[0xFFFF & s], io_fp);
          s++;
        }
      }
      fclose(io_fp);
    }
  }
}

int main(int c, char *v[]) {
  int i_rate;
  int inkey;
  int shift;
  int keybit;
  WINDOW *w;

  mem[0] = time(0); /* random value used in some programs (not used by pet though) */

  if (c < 2 || c > 3) usage(v[0]);

  read_rom(v);

  if (c > 2) t = atoi(v[2]) + 1; /* handle rate parameter */
  else t = 4; /* default rate */
  if (t > 0) {
    i_rate = t * 0x4000; /* regulates the interrupt speed */
    debug_flag = 0;
  } else {  /* negative parameter gives pet rom monitor */
    i_rate = (1 - t) * 0x4000;
    debug_flag = 1;
  }

  w = initscr();  /* set up curses */
  nodelay(w, 1);
  curs_set(0);
  cbreak();
  noecho();

  for(;;) { /* main instruction loop */

    if (pclock % (i_rate * 4) == 0) { /* check for new keypresses at 1/4 interrupt rate */
      refresh(); /* needed for pelles C with pdcurses */
      inkey = getch();
      if (!pet_flag && inkey != ERR) mem[0xA2] = inkey | 0x80; /* key input for non pet use */
    }

    if (pet_flag) { /* do pet keyboard */
      if (debug_flag == 0) mem[0xE810] |= 0x80; /* keep this bit high except in debug mode */
      s = mem[0xE810] & 0x0F; /* s represents the key group being scanned */
      if (s == 8 && /* shift is in this group - needed for ^B, ^E, ^L, ^P & ^Y */
           (inkey==2 || inkey==5 || inkey==12 || inkey==16 || inkey==25)) shift = 1;
      else shift = 0;
      if (inkey == ERR) mem[0xE812] = 0xFF;
      else {
        t = (keytab[inkey] - 40) >> 3; /* keytab high bits indicate which group */
        if (t == s) keybit = 1 << (keytab[inkey] & 7); /* low bits indicate which column */
        else keybit = 0;
        mem[0xE812] = ~(shift | keybit);
      }
    }

    pclock++;  /* increment clock here so that interrupt is not done at start (but keypress is) */

    if (pclock % i_rate == 0 && !I) interrupt();

    i = mem[pc]; /* i is the current instruction */
    incpc();

    /* if in pet mode, detect if we are at a location called by LOAD or SAVE */
    if (pet_flag && (pc == 0xFFD6 || pc == 0xFFD9)) {
      load_save();
      i = 0x60; /* set RTS to be done */
    }

    t = amodetab[(i / 2 & 14) | (i & 1)]; /* look up addressing mode - use 4 bits: 76543210 -> 4320 */
    switch(t) {
      case '8': /* absolute x & y */
        t = pc;
        incpc();
        if (i == 0xBE) operand_addr = 0xFFFF & (mem[t] + mem[pc] * 0x100 + y);
        else operand_addr = 0xFFFF & (mem[t] + mem[pc] * 0x100 + x);
        incpc();
        break;
      case '7': /* absolute y */
        t = pc;
        incpc();
        operand_addr = 0xFFFF & (mem[t] + mem[pc] * 0x100 + y);
        incpc();
        break;
      case '6': /* zero page x & y */
        if (i == 0x96 || i == 0xB6) operand_addr = 0xFF & (mem[pc] + y);
        else operand_addr = 0xFF & (mem[pc] + x);
        incpc();
        break;
      case '5': /* indirect y */
        t = mem[pc];
        incpc();
        operand_addr = (mem[t] + mem[t + 1] * 0x100) + y;
        break;
      case '4': /* absolute */
        t = pc;
        incpc();
        operand_addr = mem[t] + mem[pc] * 0x100;
        incpc();
        break;
      case '3': /* zero page */
        operand_addr = mem[pc];
        incpc();
        break;
      case '2': /* immediate */
        operand_addr = pc;
        incpc();
        break;
      case '1': /* indirect x */
        t = (mem[pc] + x) & 0xFF;
        incpc();
        operand_addr = mem[t] + mem[t + 1] * 0x100;
        break;
      case '0': /* accumulator */
        operand_addr = &a - mem; /* p ends up as a pointer to a */
    }

    p = operand_addr + mem; /* pointer to operand */
    s = i >> 6;
    switch(insttab[i]) {
      case 'N': set_ZS(a = y); /* TYA */
	  break;
      case 'M': sp = x; /* TXS */
        break;
      case 'L': set_ZS(a = x); /* TXA */
        break;
      case 'K': set_ZS(x = sp); /* TSX */
        break;
      case 'J': set_ZS(y = a); /* TAY */
        break;
      case 'I': set_ZS(x = a); /* TAX */
        break;
      case 'H': *p = y; /* STY */
        break;
      case 'G': *p = x; /* STX */
        break;
      case 'F': *p = a; /* STA */
        break;
      case 'E': /* SBC */
        t = a - *p - 1 + C;
        C = t & 0x100 ? 0 : 1;
        V = ((a ^ *p) & (a ^ t) & 0x80) / 2;
        set_ZS(a = t & 0xFF);
        break;
      case 'D': /* RTS */
        pc = mem[(++sp & 0xFF) + 0x100];
        pc += mem[(++sp & 0xFF) + 0x100] * 0x100;
        incpc();
        break;
      case 'C': /* RTI */
        plp();
        pc = mem[(++sp & 0xFF) + 0x100];
        pc += mem[(++sp & 0xFF) + 0x100] * 0x100;
        break;
      case 'B': /* ROR */
        t = *p;
        set_ZS(*p = (*p / 2) | (C * 0x80));
        C = t & 1;
        break;
      case 'A': /* ROL */
        t = *p;
        set_ZS(*p = (*p * 2) | C);
        C = t / 0x80;
        break;
      case '@': plp(); /* PLP */
        break;
      case '?': set_ZS(a = mem[(++sp & 0xFF) + 0x100]); /* PLA */
        break;
      case '>': mem[(sp-- & 0xFF) + 0x100] = C|Z|I|D|B|V|S|32; /* PHP */
        break;
      case '=': mem[(sp-- & 0xFF) + 0x100] = a; /* PHA */
        break;
      case '<': set_ZS(a |= *p); /* ORA */
        break;
      case ';': /* LSR */
        C = *p & 1;
        set_ZS(*p /= 2);
        break;
      case ':': set_ZS(y = *p); /* LDY */
        break;
      case '9': set_ZS(x = *p); /* LDX */
        break;
      case '8': set_ZS(a = *p); /* LDA */
        break;
      case '7': /* JSR */
        s = mem[0xFFFF & (pc - 1)] + mem[pc] * 0x100;
        push_pc();
        pc = s;
        break;
      case '6': /* JMP */
        if (i & 32) pc = mem[operand_addr] + mem[0xFFFF & (operand_addr + 1)] * 0x100;
        else pc = operand_addr;
        break;
      case '5': set_ZS(++y); /* INY */
        break;
      case '4': set_ZS(++x); /* INX */
        break;
      case '3': set_ZS(++*p); /* INC */
        break;
      case '2': set_ZS(a ^= *p); /* EOR */
        break;
      case '1': set_ZS(--y); /* DEY */
        break;
      case '0': set_ZS(--x); /* DEX */
        break;
      case '/': set_ZS(--*p); /* DEC */
        break;
      case '.': cmp(y); /* CPY */
        break;
      case '-': cmp(x); /* CPX */
        break;
      case ',': cmp(a); /* CMP */
        break;
      case '+': *(s ? s-1 ? s-2 ? &D : &V : &I : &C) = 0; /* CLC(s==0) / CLI(1) / CLV(2) / CLD(3) */
        break;
      case '*': *(s ? s-1 ? &D : &I : &C) = (s ? s-1 ? 8 : 4 : 1); /* SEC(s==0) / SEI(1) / SED(3) */
        break;
      case ')': /* BRK */
        pc--;
        B = 16;
        interrupt();
        break;
      case '(': /* BIT */
        set_ZS(a & *p);
        V = *p & 0x40;
        S = *p & 0x80;
        break;
      case '\'': /* BNE / BCC / BVC / BPL */
        if (!(s ? s - 1 ? s - 2 ? Z : C : V : S)) pc = (pc + (*p & 0x80 ? *p - 0x100 : *p)) & 0xFFFF;
        break;
      case '&': /* BEQ / BCS / BVS / BMI */
        if (s ? s - 1 ? s - 2 ? Z : C : V : S) pc = (pc + (*p & 0x80 ? *p - 0x100 : *p)) & 0xFFFF;
        break;
      case '%': /* ASL */
        C = *p / 0x80;
        set_ZS(*p *= 2);
        break;
      case '$': /* AND */
        set_ZS(a &= *p);
        break;
      case '#': /* ADC */
        t = a + *p + C;
        C = t & 0x100 ? 1 : 0;
        V = (~(a ^ *p) & (a ^ t) & 0x80) / 2;
        set_ZS(a = t & 0xFF);
    }

    t = operand_addr - 0x8000; /* check if operand is inside screen area */
    if (t >= 0 && t < 1000) { /* update with curses if so */
      *p > 127 ? attron(A_REVERSE) : attroff(A_REVERSE);
      s = *p & 127;
      if (pet_flag) {
        if (s < 32) s += 64;
        if (s > 95) s -= 32;
      }
      mvaddch(t / 40, t % 40, s);
    }
  }
}
