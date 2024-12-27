/*
    This bison parser is part of the ETA C Compiler project by Stephen Sykes
    It was derived from a grammar posted by Jeff Lee

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
/*
 * If this code doesn't work for you it may be due to my somewhat unclean use of sprintf. Sorry.
 */
%{
#include <stdio.h>
#include <stdlib.h>

  /* hard wired limits */
#define GLOBALMAX 128
#define LOCALMAX 128
#define STRINGMAX 512
#define FUNCMAX 64

extern char yytext[];

#define YYERROR_VERBOSE 1

#define P1 if (pass == 1)
#define P2 if (pass == 2)
int pass;

int pointer_dec; /* is this a pointer declaration? */
int pointer_dec_fn; /* is this function def a pointer one? */
int stringcnt;
char arg_list[64][128];
int arg_list_cnt;
char currentfunc[64];
int arr_dim_size[10]; /* keeps size of current declaration, 10 dims max */
int arr_dim_cnt; /* num of dimensions */
int funccnt;   /* counts functions */
int curtype; /* most recent type specifier */
int funcflag;
int init_list_len; /* length of initialiser list - used to size array initialisers */

#define YYSTYPE char *
char *freelist[4096]; /* garbage collection, kind of */
int freelistcnt;
#define NEWSTR(n) n=freelist[freelistcnt++]=(char *)malloc(32768)
#define SNEWSTR(n) n=freelist[freelistcnt++]=(char *)malloc(1024)
#define FREE for(;freelistcnt;free(freelist[--freelistcnt]))

#define INTSYM 1
#define INTSYM_S "1"
#define CHARSYM 2
#define CHARSYM_S "2"
#define INTSTAR 3
#define INTSTAR_S "3"
#define CHARSTAR 4
#define CHARSTAR_S "4"
#define IMPOSSIBLE 0 /* value for address - null pointer */
#define IMPOSSIBLE_S "0" /* value for address - null pointer */

void sym_add(int *type, char *name, int initflag);
void addfuncargs();
void addfixed_string(char *value);
char *lookup(char *name);
char *lookup_addressof(char *name);
char *lookup_string(int n);
int lookup_size(char *name);
void write_table();
void addfuncdef();
void finishfunc();
char *funccall(char *name, int arity);
char *funcreturn();
char *funcreturnval();
char *addlabel(char *name);
char *gotolabel(char *name);

char *library_functions[] = {"printf","getchar","putchar"};
int num_library_functions = 3;

#define E_EAPUSH(s,v,a) sprintf(s,"$e.push(%s)\n$ea.push(%s)\n",v,a)
#define E_EACHOMP "$e.chomp\n$ea.chomp\n"

#define CEXP(a,b,c,op) {NEWSTR(a);P1 sprintf(a, "%s %s %s",b,op,c);P2 sprintf(a,"%s%s $e.pop\n $e.topval\n $e.topval=EtaImmediate.instance %s EtaImmediate.instance\n$ea.chomp\n",b,c,op);}
#define NOTIMP(w) P2 fprintf(stderr, "%s not implemented\n", w)

%}

%defines

%token IDENTIFIER CONSTANT STRING_LITERAL SIZEOF
%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN TYPE_NAME

%token TYPEDEF EXTERN STATIC AUTO REGISTER
%token CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token STRUCT UNION ENUM ELLIPSIS

%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%start translation_unit
%%

primary_expression
        : IDENTIFIER {
        SNEWSTR($$);
	P2 {
          if (!lookup(yylval)) strcpy($$,yylval); /* for fn calls just return identifier string */ 
	  else {
	    E_EAPUSH($$,lookup(yylval),lookup_addressof(yylval));
	  }}}
        | CONSTANT {SNEWSTR($$); P1 strcpy($$, yylval); P2 {E_EAPUSH($$,yylval,IMPOSSIBLE_S);}}
        | STRING_LITERAL {SNEWSTR($$); P1 addfixed_string(yylval); P2 {E_EAPUSH($$,lookup_string(stringcnt),IMPOSSIBLE_S); stringcnt++;}}
        | '(' expression ')' {$$=$2;}  /* *(x+1) = y case */
	;

postfix_expression
        : primary_expression 
        | postfix_expression '[' expression ']' {P2 {NEWSTR($$); 
          sprintf($$, "%s %s $ea.chomp\n $e.pop\n $e.topval=$e.topval+EtaImmediate.instance\n dereference\n", $1, $3);}}
        | postfix_expression '(' ')' {P2 {NEWSTR($$); sprintf($$,"%s",funccall($1,0));}}
        | postfix_expression '(' argument_expression_list ')' {P2 {int b,c=0;
	for (b=0; b<strlen($3); b++) if ($3[b] == '\t') {c++;$3[b]=' ';} /* count tabs for arity */
	NEWSTR($$); 
        sprintf($$,"%s%s",$3,funccall($1, c));}}
	| postfix_expression '.' IDENTIFIER
	| postfix_expression PTR_OP IDENTIFIER
	| postfix_expression INC_OP {P2 strcat($$,"+");}
        | postfix_expression DEC_OP {P2 strcat($$,"-");}
	;

argument_expression_list
        : assignment_expression  {P2 {NEWSTR($$); sprintf($$,"\t%s", $1);}} /* tabs count arity */
        | argument_expression_list ',' assignment_expression {P2 {NEWSTR($$); sprintf($$,"%s\t%s",$1,$3);}}
	;

unary_expression
        : postfix_expression
	| INC_OP unary_expression {NEWSTR($$); sprintf($$,"%s preinc\n", $2);}
	| DEC_OP unary_expression {NEWSTR($$); sprintf($$,"%s predec\n", $2);}
        | unary_operator cast_expression {NEWSTR($$); sprintf($$, "%s%s", $1, $2);}
	| SIZEOF unary_expression {SNEWSTR($$); sprintf($$,"$e.push(%d)\n $ea.push(%d)\n",lookup_size(yylval),IMPOSSIBLE);}
	| SIZEOF '(' type_name ')' {SNEWSTR($$); E_EAPUSH($$,"1",IMPOSSIBLE_S);}
	;

unary_operator
        : '&' {$$ = "&";}
        | '*' {$$ = "*";}
	| '+' {$$ = "+";}
	| '-' {$$ = "-";}
        | '~' {$$ = "~";}
	| '!' {$$ = "!";}
	;

cast_expression
        : unary_expression {
	  char endc ,*sp;
          sp=$1;
	  P2 {
	  endc = sp[strlen(sp)-1];
	  NEWSTR($$);
	  if (*$1 == '*') {
	    sp += 1;
	    sprintf($$, "%s dereference\n", sp);
	  } else if (*$1 == '&') {
	    sp += 1;
            sprintf($$, "%s $e.topval=$ea.topval\n", sp);
	  } else if (*$1 == '!') {
	    sp += 1;
	    sprintf($$, "%s $e.topval\n $p.write_not\n $e.topval=EtaImmediate.instance\n", sp);
	  } else if (*$1 == '+') {
	    sp += 1;
	    strcpy($$,sp);
	  } else if (*$1 == '-') {
	    sp += 1;
	    sprintf($$, "%s $e.topval\n $e.topval= -EtaImmediate.instance\n", sp);
	  } else if (*$1 == '~') {
	    sp += 1;
	    sprintf($$, "%s $e.topval\n $e.topval= ~EtaImmediate.instance\n", sp);
	  } else strcpy($$,sp);
	  if (endc == '+' || endc == '-') $$[strlen($$)-1] = '\0';
	  if (endc == '+') {
	    strcat($$, "postinc\n");
	  }
	  if (endc == '-') {
	    strcat($$, "postdec\n");
	  }
	}}
        | '(' type_name ')' cast_expression {$$ = $4;}
	;

multiplicative_expression
	: cast_expression
        | multiplicative_expression '*' cast_expression {CEXP($$,$1,$3,"*");}
	| multiplicative_expression '/' cast_expression {CEXP($$,$1,$3,"/");}
	| multiplicative_expression '%' cast_expression {CEXP($$,$1,$3,"%");}
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression {CEXP($$,$1,$3,"+");}
	| additive_expression '-' multiplicative_expression {CEXP($$,$1,$3,"-");}
	;

shift_expression
	: additive_expression
	| shift_expression LEFT_OP additive_expression {CEXP($$,$1,$3,"<<");}
	| shift_expression RIGHT_OP additive_expression {CEXP($$,$1,$3,">>");}
	;

relational_expression
	: shift_expression
	| relational_expression '<' shift_expression {CEXP($$,$1,$3,"<");}
	| relational_expression '>' shift_expression {CEXP($$,$1,$3,">");}
	| relational_expression LE_OP shift_expression {CEXP($$,$1,$3,"<=");}
	| relational_expression GE_OP shift_expression {CEXP($$,$1,$3,">=");}
	;

equality_expression
	: relational_expression
	| equality_expression EQ_OP relational_expression {CEXP($$,$1,$3,"==");}
	| equality_expression NE_OP relational_expression {CEXP($$,$1,$3,"==");
	P2 strcat($$, "$e.topval\n $p.write_not\n $e.topval=EtaImmediate.instance\n");}
	;

and_expression
	: equality_expression
	| and_expression '&' equality_expression {CEXP($$,$1,$3,"&");}
	;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression {CEXP($$,$1,$3,"^");}
	;

inclusive_or_expression
	: exclusive_or_expression
        | inclusive_or_expression '|' exclusive_or_expression {CEXP($$,$1,$3,"|");}
	;

logical_and_expression
	: inclusive_or_expression
        | logical_and_expression AND_OP inclusive_or_expression {
        P2 {NEWSTR($$);sprintf($$,"%s $e.topval\n eif(EtaImmediate.instance){\n%s%s}\n",$1,E_EACHOMP,$3);}}
	;

logical_or_expression
	: logical_and_expression
	| logical_or_expression OR_OP logical_and_expression {
        P2 {NEWSTR($$);sprintf($$,"%s $e.topval\n $p.write_not\n eif(EtaImmediate.instance){\n%s%s}\n",$1,E_EACHOMP,$3);}}
	;

conditional_expression
	: logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression {
        P2 {NEWSTR($$);sprintf($$,"%s $ea.chomp\n $e.pop\n eif(EtaImmediate.instance){\n%s}\n eelse{\n%s}\n",$1,$3,$5);}}
	;

assignment_expression
        : conditional_expression
        | unary_expression assignment_operator assignment_expression {P2 {
	  NEWSTR($$);
	  if (*$1 == '*') sprintf($$, "%s %s dereference\n deref_assignment('%s')\n", $3, $1 + 1, $2);
	  else sprintf($$, "%s %s deref_assignment('%s')\n", $3, $1, $2);
	  }}
	;

assignment_operator
        : '=' {$$ = "=";}
        | MUL_ASSIGN {$$ = "*=";}
	| DIV_ASSIGN {$$ = "/=";}
	| MOD_ASSIGN {$$ = "%=";}
	| ADD_ASSIGN {$$ = "+=";}
	| SUB_ASSIGN {$$ = "-=";}
	| LEFT_ASSIGN {$$ = "<<=";}
	| RIGHT_ASSIGN {$$ = ">>=";}
	| AND_ASSIGN {$$ = "&=";}
	| XOR_ASSIGN {$$ = "^=";}
	| OR_ASSIGN {$$ = "|=";}
	;

expression
        : assignment_expression
        | expression ',' assignment_expression {NEWSTR($$);sprintf($$,"%s%s%s",$1,E_EACHOMP,$3);}
	;

constant_expression
	: conditional_expression
	;

declaration
        : declaration_specifiers ';' {curtype = INTSYM; $$="";}
        | declaration_specifiers init_declarator_list ';' {P1 curtype = INTSYM;
  P2 {if (strcmp(currentfunc,"")) $$ = $2;
      else printf("%s",$2);} /* in global context print initialisers */
  }
	;

declaration_specifiers
	: storage_class_specifier
	| storage_class_specifier declaration_specifiers
        | type_specifier {curtype = atoi($1);}
        | type_specifier declaration_specifiers {curtype = atoi($1);}
	| type_qualifier
	| type_qualifier declaration_specifiers
	;

init_declarator_list
        : init_declarator
        | init_declarator_list ',' init_declarator {P2 {NEWSTR($$); sprintf($$,"%s%s",$1,$3);}}
	;

init_declarator
        : declarator {if (strlen($1)) {P1 sym_add(arr_dim_size, $1, 0); arr_dim_cnt = 0; $$="";}}
        | declarator '=' initializer {P1 sym_add(arr_dim_size, $1, 1); arr_dim_cnt = 0; /* P2:init vals pushed on the estack by $3*/
          P2 {NEWSTR($$); strcpy($$,$3); sprintf($$, "%s %s = $e.topval\n %s", $$, lookup($1), E_EACHOMP);}}
	;

storage_class_specifier
	: TYPEDEF
	| EXTERN
	| STATIC
	| AUTO
	| REGISTER
	;

type_specifier
	: VOID {$$ = INTSYM_S;}
        | CHAR {$$ = CHARSYM_S;}
	| SHORT {$$ = INTSYM_S;}
	| INT {$$ = INTSYM_S;}
	| LONG {$$ = INTSYM_S;}
        | FLOAT {NOTIMP("float");}
	| DOUBLE {NOTIMP("double");}
	| SIGNED
	| UNSIGNED {NOTIMP("unsigned");}
	| struct_or_union_specifier
	| enum_specifier
	| TYPE_NAME
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'
	| struct_or_union '{' struct_declaration_list '}'
	| struct_or_union IDENTIFIER
	;

struct_or_union
	: STRUCT
	| UNION
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list
	| type_specifier
	| type_qualifier specifier_qualifier_list
	| type_qualifier
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator
	: declarator
	| ':' constant_expression
	| declarator ':' constant_expression
	;

enum_specifier
	: ENUM '{' enumerator_list '}'
	| ENUM IDENTIFIER '{' enumerator_list '}'
	| ENUM IDENTIFIER
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' constant_expression
	;

type_qualifier
	: CONST
	| VOLATILE
	;

declarator
        : pointer direct_declarator {$$ = $2; curtype += 2;if(funcflag){arg_list_cnt=funcflag=0;$$="";}}
        | direct_declarator {if(funcflag){arg_list_cnt=funcflag=0;$$="";}}
	;

function_declarator
        : pointer direct_declarator {$$ = $2; P2 curtype += 2;strcpy(currentfunc,$2); P1 addfuncargs(); arr_dim_cnt=0; P2 addfuncdef($2); arg_list_cnt=0;funcflag=0;}
        | direct_declarator {strcpy(currentfunc,$1); P1 addfuncargs(); arr_dim_cnt=0; P2 addfuncdef($1); arg_list_cnt=0;funcflag=0;}
	;

direct_declarator
        : IDENTIFIER {NEWSTR($$); strcpy($$, yylval);}
        | '(' declarator ')' {$$ = $2;}
        | direct_declarator '[' constant_expression ']' {P1 {
	  char *a,b[16];
	  FILE *f;
	  SNEWSTR(a);
	  strcpy(b,"/tmp/etaXXXXXX");
	  close(mkstemp(b)); /* who cares? */
	  sprintf(a,"echo '%s'|bc>%s",$3,b);
	  system(a);
	  f = fopen(b, "r");
	  fgets(a,32,f);
	  fclose(f);
	  remove(b);
	  arr_dim_size[arr_dim_cnt++] = atoi(a);}}
        | direct_declarator '[' ']' {P1 arr_dim_size[arr_dim_cnt++] = -1;} /* this form use with initialiser, or as param spec */
	| direct_declarator '(' parameter_type_list ')' {funcflag=1;}
	| direct_declarator '(' identifier_list ')' {funcflag=1;}
	| direct_declarator '(' ')' {funcflag=1;}
	;

pointer
	: '*'
	| '*' type_qualifier_list
	| '*' pointer
	| '*' type_qualifier_list pointer
	;

type_qualifier_list
	: type_qualifier
	| type_qualifier_list type_qualifier
	;


parameter_type_list
	: parameter_list
	| parameter_list ',' ELLIPSIS
	;

parameter_list
        : parameter_declaration {strcpy(arg_list[arg_list_cnt++], $1);}
	| parameter_list ',' parameter_declaration {strcpy(arg_list[arg_list_cnt++], $3);}
	;

parameter_declaration
        : declaration_specifiers declarator {$$ = $2;}
	| declaration_specifiers abstract_declarator
	| declaration_specifiers
	;

identifier_list
        : IDENTIFIER {strcpy(arg_list[arg_list_cnt++], $1);}
	| identifier_list ',' IDENTIFIER {strcpy(arg_list[arg_list_cnt++], $2);}
	;

type_name
	: specifier_qualifier_list
	| specifier_qualifier_list abstract_declarator
	;

abstract_declarator
	: pointer
	| direct_abstract_declarator
	| pointer direct_abstract_declarator
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'
	| '[' ']'
	| '[' constant_expression ']'
	| direct_abstract_declarator '[' ']'
	| direct_abstract_declarator '[' constant_expression ']'
	| '(' ')'
	| '(' parameter_type_list ')'
	| direct_abstract_declarator '(' ')'
        | direct_abstract_declarator '(' parameter_type_list ')'
	;

initializer
	: assignment_expression
        | '{' initializer_list '}' {$$ = $2;}
        | '{' initializer_list ',' '}' {$$ = $2;}
	;

initializer_list
	: initializer
        | initializer_list ',' initializer {NEWSTR($$); sprintf($$, "%s%s", $1, $3);}
	;

statement
	: labeled_statement
	| compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	;

label_prefix
	: IDENTIFIER ':' {P2 $$ = addlabel(yylval);}
	;

labeled_statement
        : label_prefix statement {P2 {NEWSTR($$);sprintf($$,"%s%s",$1,$2);}}
	| CASE constant_expression ':' statement
	| DEFAULT ':' statement {$$ = $3;}
	;

compound_statement
	: '{' '}'
        | '{' statement_list '}' {$$ = $2;}
        | '{' declaration_list '}' {$$ = $2;}
	| '{' declaration_list statement_list '}' {NEWSTR($$); sprintf($$,"%s%s",$2, $3);}
	;

declaration_list
	: declaration
        | declaration_list declaration {P2 {NEWSTR($$); sprintf($$,"%s%s", $1, $2);}}
	;

statement_list
	: statement
        | statement_list statement {P2 {NEWSTR($$); sprintf($$,"%s%s", $1, $2);}}
	;

expression_statement
        : ';' {$$ = "";}
        | expression ';' {P2 {
          NEWSTR($$);
	  sprintf($$,"%s %s\n",$1,E_EACHOMP);}}
	;

selection_statement
        : IF '(' expression ')' statement {P2 {NEWSTR($$);
	  sprintf($$,"%s $ea.chomp\n eif($e.pop){\n%s}\n",$3,$5);}}
	| IF '(' expression ')' statement ELSE statement {P2 {NEWSTR($$);
	  sprintf($$,"%s $ea.chomp\n eif($e.pop){\n%s}\n eelse{\n%s}\n",$3,$5,$7);}}
        | SWITCH '(' expression ')' statement {NOTIMP("switch");}
	;

iteration_statement
        : WHILE '(' expression ')' statement {P2 {NEWSTR($$);
          sprintf($$,"lr=$p.linenumber\n %s $ea.chomp\n brk=cewhile($e.pop,lr,brk,false){|brk|\n %s}\n",$3,$5);}}
        | DO statement WHILE '(' expression ')' ';' {P2 {NEWSTR($$);
 	  sprintf($$, "brk=cdowhile_wrap(brk){|brk| %s lr=$p.linenumber\n $p.complete_forward_xfer($cont[-2])\n %s $ea.chomp\n cdowhile($e.pop,lr,brk){\n%s}}\n",$2,$5,$2);}}
	| FOR '(' expression_statement ';' ')' statement {P2 {NEWSTR($$);
 	  sprintf($$, "%s lr=$p.linenumber\n brk=cewhile(true,lr,brk,false){|brk|\n %s}\n", $3, $6);}}
	| FOR '(' expression_statement expression ';' ')' statement {P2 {NEWSTR($$);
	  sprintf($$, "%s lr=$p.linenumber\n %s $ea.chomp\n brk=cewhile($e.pop,lr,brk,false){|brk|\n %s}\n", $3, $4, $7);}}
	| FOR '(' expression_statement ';' expression ')' statement {P2 {NEWSTR($$);
	  sprintf($$, "%s lr=$p.linenumber\n brk=cewhile(true,lr,brk,true){|brk|\n %s $p.complete_forward_xfer($cont[-2])\n %s %s\n}\n", $3, $7, $5, E_EACHOMP);}}
	| FOR '(' expression_statement expression ';' expression ')' statement {P2 {NEWSTR($$);
	  sprintf($$, "%s lr=$p.linenumber\n %s $ea.chomp\n brk=cewhile($e.pop,lr,brk,true){|brk|\n %s $p.complete_forward_xfer($cont[-2])\n %s %s\n}\n", $3, $4, $8, $6, E_EACHOMP);}}
	;

jump_statement
        : GOTO IDENTIFIER ';' {P2 $$=gotolabel(yylval);}
        | CONTINUE ';' {P2 {SNEWSTR($$); sprintf($$, "if ($cont[-1]!='FX') then goto($cont[-1])\n else\n write('a')\n $p.repeat_forward_xfer($cont[-2])\n end\n");}}
        | BREAK ';' {P2 {SNEWSTR($$); sprintf($$, "write('a')\n $p.repeat_forward_xfer(brk)\n");}}
        | RETURN ';' {P2 {SNEWSTR($$); strcpy($$,funcreturn());}}
        | RETURN expression ';' {P2 {NEWSTR($$); sprintf($$,"%s%s",$2,funcreturnval());}}
	;

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

external_declaration
	: function_definition
	| declaration
	;

function_definition
	: declaration_specifiers function_declarator declaration_list compound_statement 
{P2 {printf("%s%s",$3,$4);finishfunc($2);}; funccnt++; strcpy(currentfunc, "");curtype=INTSYM; FREE;}
	| declaration_specifiers function_declarator compound_statement 
{P2 {printf("%s",$3);finishfunc($2);}; funccnt++; strcpy(currentfunc, "");curtype=INTSYM; FREE;}
	| function_declarator declaration_list compound_statement 
{P2 {printf("%s%s",$2,$3);finishfunc($1);}; funccnt++; strcpy(currentfunc, ""); FREE;}
        | function_declarator compound_statement 
{P2 {printf("%s",$2);finishfunc($1);}; funccnt++; strcpy(currentfunc, ""); FREE;}
	;

%%

extern int column;
extern int lineno;

yyerror(s)
char *s;
{
	fprintf(stderr,"%s Line %d\n", s, lineno);
}



/******************************************************/

char *globalsymtab[GLOBALMAX];  /* globals: gets 128 names */
int globalpointers[GLOBALMAX];  /* pointer to each var in the global area */
int globalsizeof[GLOBALMAX];  /* sizeof each in global area */
int globalinitvals[GLOBALMAX]; /* not used */
int globalarrayflags[GLOBALMAX];
int globalsymtab_cnt; /* counter for number of symbols */
int globalsize; /* size of the global table for calculating table position from (negative) pointer */

char *strings[STRINGMAX];  /* can have up to 512 strings */
int stringpointers[STRINGMAX]; /* can have up to 512 string pointers */
int last_str_len; /* length of the last string encountered - used to size char array initialisers */

int string_cnt;    /* count strings */
char funcs[FUNCMAX][64]; /* can have FUNCMAX functions of 64 name length */
char prefuncs[FUNCMAX][64]; /* functions we haven't seen the definition for yet */
int prefuncscnt;
int func_arity[FUNCMAX]; /* number of args to each function */

char *localsymtab[FUNCMAX][LOCALMAX]; /* each function can have up to 64 local variable names */
int localsizeof[FUNCMAX][LOCALMAX]; /* sizeof each local */
int localsymcnt[FUNCMAX];
int localsize[FUNCMAX];
int localpointers[FUNCMAX][LOCALMAX]; /* pointer to each var in the local area */
int localinitvals[FUNCMAX][LOCALMAX];
int *local_arr_inits[FUNCMAX][LOCALMAX]; /* init values for internal array pointers on local stack */

char *labels[FUNCMAX][64]; /* each function has its own labels */
int labelcnt[FUNCMAX];

int main_arity; /* need this for call to main */

int initpos;  /* array initpos */
int addlocalarr(int dim, int dimcnt, int *size) {
  int i, rsize=0;
  if (dim < dimcnt) {
    if (dim == 0) localsize[funccnt] += size[dim];
    if (dim < dimcnt-1) {
      for (i=0; i<size[dim]; i++) {
	local_arr_inits[funccnt][localsymcnt[funccnt]][initpos++] = localsize[funccnt];
	local_arr_inits[funccnt][localsymcnt[funccnt]][initpos] = 0;  /* add end marker each time */
	localsize[funccnt] += size[dim+1];
      }
      for (i=0; i<size[dim]; i++) {
	rsize += addlocalarr(dim+1, dimcnt, size);
      }
    } else rsize += size[dim];
  }
  return rsize;
}

void sym_add(int *size, char *name, int initflag) {
  int i;
  if (!strlen(currentfunc)) {
    globalsymtab[globalsymtab_cnt] = (char *)malloc(strlen(name) + 1);
    strcpy(globalsymtab[globalsymtab_cnt], name);
    globalpointers[globalsymtab_cnt] = globalsize;
    globalsize++;
    globalsizeof[globalsymtab_cnt] = 1;
    if (arr_dim_cnt) {
      globalarrayflags[globalsymtab_cnt] = 1; /* so we know to assign the pointer whilst writing the sym tab */
      if (*size > 0) globalsize += *size;
      globalsizeof[globalsymtab_cnt] = *size; /* size is -1 and initflag is set in the case a[] = "hello" */
      if (*size == -1 && initflag) globalsizeof[globalsymtab_cnt] = last_str_len;
    }
    globalsymtab_cnt++;
  } else {
    for (i=0; i<localsymcnt[funccnt]; i++) if (!strcmp(name, localsymtab[funccnt][i])) return; /* ignore old K&R param decls */
    localsymtab[funccnt][localsymcnt[funccnt]] = (char *)malloc(strlen(name) + 1);
    strcpy(localsymtab[funccnt][localsymcnt[funccnt]], name);
    localpointers[funccnt][localsymcnt[funccnt]] = localsize[funccnt];
    localsize[funccnt]++;
    localsizeof[funccnt][localsymcnt[funccnt]] = 1;
    if (arr_dim_cnt) {
      localinitvals[funccnt][localsymcnt[funccnt]] = localsize[funccnt]; /* no null pointer adjustment */
      local_arr_inits[funccnt][localsymcnt[funccnt]] = (int *)malloc(4096*sizeof(int));  /* MAX array size is 4096 */
      if (*size > -1) {
	initpos = 0;
	localsizeof[funccnt][localsymcnt[funccnt]] = addlocalarr(0, arr_dim_cnt, size);
      } else {
        /* *size is 0 in the case a[] = "hello" */
	if (initflag) localsizeof[funccnt][localsymcnt[funccnt]] = last_str_len;
	else localsizeof[funccnt][localsymcnt[funccnt]] = 1; /* function param, size is 1 */
      }
    }
    localsymcnt[funccnt]++;
  }
  /*  fprintf (stderr, "[%s] added %s, size %d\n", currentfunc, name, size); */
}

void addfuncargs() {
  int i, z=-1;
  for(i=0; i<arg_list_cnt; i++) {
    sym_add(&z, arg_list[i], 0);
  }
}

void addfixed_string(char *value) {
  /* remove \", \n, \t, \\ here */
  int i, j;
  char c;
  j = 0;
  c = -1;
  strings[string_cnt] = (char *)malloc(strlen(value)+1);
  for (i = 1; i < strlen(value) - 1; i++) {
    if (value[i] == '\\' && value[i+1] == '"') c = '"';
    if (value[i] == '\\' && value[i+1] == 'n') c = '\n';
    if (value[i] == '\\' && value[i+1] == 't') c = '\t';
    if (value[i] == '\\' && value[i+1] == 'r') c = '\r';
    if (value[i] == '\\' && value[i+1] == '\\') c = '\\';
    if (c != -1) {
      strings[string_cnt][j++] = c;
      i++;
      c = -1;
    } else strings[string_cnt][j++] = value[i];
  }
  strings[string_cnt][j] = '\0';
  last_str_len = strlen(strings[string_cnt]) + 1; /* space used, not lenght */
  string_cnt++;
}

char *lookup(char *name) {
  int i;
  char *result;
  for (i=0; i<localsymcnt[funccnt]; i++) {
    if (strcmp(name, localsymtab[funccnt][i]) == 0) {
      result = (char *)malloc(64);
      sprintf(result, "$l[$l.local2abs(%d)]", localpointers[funccnt][i]);
      return result;
    }
  }
  for(i=0; i<globalsymtab_cnt; i++) {
    if (strcmp(name, globalsymtab[i]) == 0) {
      result = (char *)malloc(24);
      sprintf(result, "$globals[%d]", globalpointers[i]);
      return result;
    }
  }
  return NULL;
}

char *lookup_addressof(char *name) {
  int i;
  char *r;
  r = (char *)malloc(32);
  for (i=0; i<localsymcnt[funccnt]; i++) {
    if (strcmp(name, localsymtab[funccnt][i]) == 0) {
      sprintf(r,"$l.local2abs(%d)",localpointers[funccnt][i]); /* no null pointer adj */
      return r;
    }
  }
  /* global namespace is indicated by negative address = address - globalsymtab_cnt */
  for(i=0; i<globalsymtab_cnt; i++) {
    if (strcmp(name, globalsymtab[i]) == 0) {
      sprintf(r,"%d",globalpointers[i] - globalsize);
      return r;
    }
  }
  return IMPOSSIBLE_S;
}

char *lookup_string(int n) {
  char *r;
  r = (char *)malloc(16);
  sprintf(r,"%d",stringpointers[n] - globalsize);
  return r;
}

int lookup_size(char *name) {
  int i;
  for (i=0; i<localsymcnt[funccnt]; i++) {
    if (strcmp(name, localsymtab[funccnt][i]) == 0) {
      return localsizeof[funccnt][i];
    }
  }
  for(i=0; i<globalsymtab_cnt; i++) {
    if (strcmp(name, globalsymtab[i]) == 0) {
      return globalsizeof[i];
    }
  }
  return 1; /* everything is 1 except arrays, so default to this */
}


void write_table() {
  int totsize, k, m, p;

  totsize = globalsize;  /* vars go at bottom of array, followed by fixed strings */
  for(k=0; k<string_cnt; k++) {
    totsize += strlen(strings[k]) + 1; /* plus 1 for null term */
  }
  if (totsize) {
    printf("$globals = EtaArray.new(%d)\n", totsize);
    for(k=0; k<globalsymtab_cnt; k++) {
      if (globalinitvals[k]) printf("$globals.set(%d, %d)\n", globalpointers[k], globalinitvals[k]);
      else if (globalarrayflags[k]) printf("$globals.set(%d, %d)\n", globalpointers[k], globalpointers[k] + 1 - totsize);
    }
    p = globalsize;
    for(k=0; k<string_cnt; k++) {
      stringpointers[k] = p;
      for(m=0; m<strlen(strings[k]); m++) {
	printf("$globals.set(%d, %d)\n", p, strings[k][m]);
	p++;
      }
      printf("$globals.set(%d, 0)\n", p);
      p++;
    }
    globalsize = totsize;
  }
}

char *addlabel(char *name) {
  int i;
  char *r;
  SNEWSTR(r);
  strcpy(r,"next_line\n");
  for (i=0; i<labelcnt[funccnt]; i++) {
    if (!strcmp(labels[funccnt][i],name)) break;
  }
  if (labelcnt[funccnt]>0 && i < labelcnt[funccnt]) { /* already seen this label in a goto */
    sprintf(r,"%s $p.complete_forward_xfer($labels_%d_%s)\n", r, i, name);
  } else { /* new label */
    labels[funccnt][labelcnt[funccnt]] = (char *)malloc(strlen(name) + 1);
    strcpy(labels[funccnt][labelcnt[funccnt]++],name);
  }
  sprintf(r,"%s $labellines_%d_%s = $p.linenumber\n", r, i, name);
  return r;
}

char *gotolabel(char *name) {
  int i;
  char *r;
  SNEWSTR(r);
  for (i=0; i<labelcnt[funccnt]; i++) {
    if (!strcmp(labels[funccnt][i],name)) break;
  }
  if (i < labelcnt[funccnt]) { /* already seen this label */
    sprintf(r,"if ($labellines_%d_%s)\n goto($labellines_%d_%s)\n else\n write('a')\n $p.repeat_forward_xfer($labels_%d_%s)\n end\n", i, name, i, name, i, name);
  } else { /* new label */
    labels[funccnt][labelcnt[funccnt]] = (char *)malloc(strlen(name) + 1);
    strcpy(labels[funccnt][labelcnt[funccnt]++],name);
    sprintf(r,"write('a')\n $labels_%d_%s = $p.add_forward_xfer\n", i, name);
  }
  return r;
}

/*
 * Func calling convention:
 * push args onto estack, return addr is pushed onto cstack
 * return value is returned main stack
 */

#define STACKCHECK(n) printf("$stderr.print \"STACKCHECK: %s depth=#{$p.stackdepth}, should be #{$stackcheck} [%s]\\n\" if ($stackcheck != $p.stackdepth)\n", n, name)

void addfuncdef(char *name) {
  int i,j;
  int offset = 0;
  /*  fprintf(stderr, "Declaring %s()\n", name); */
  strcpy(funcs[funccnt], name);
  printf("#### FUNCTION %s, arity: %d\n", name, arg_list_cnt);
  if (funccnt == 0) printf("$stackcheck = $p.stackdepth\n");
  printf("write('a')\n");
  printf("func_jump = $p.add_forward_xfer\n"); /* jump over each function */
  printf("next_line\n");
  if (!strcmp(name, "main")) {
    main_arity = arg_list_cnt; /* save arity of main */
    localsize[funccnt]++; /* save space for null bottom element of lstack */
    offset = 1;
  }
  printf("function_address_%d = $p.linenumber\n", funccnt);
  for(i=0; i<prefuncscnt; i++) { /* fix up any previous calls to this function */
    if (!strcmp(prefuncs[i],name)) {
      printf("$p.complete_forward_xfer($prefuncs_%d)\n",i);
      break;
    }
  }
  printf("$l.newframe(%d)\n", localsize[funccnt]); /* new stack frame */
  for(i=0; i<localsymcnt[funccnt]; i++) {
    localpointers[funccnt][i] += offset;  /* in main, adjust for null bottom */
    if (localinitvals[funccnt][i]) { /* only array pointers */
      printf("$l[$l.local2abs(%d)] = $l.local2abs(%d)\n", localpointers[funccnt][i], localinitvals[funccnt][i] + offset); 
      for (j=0; local_arr_inits[funccnt][i][j]; j++) {
	printf("$l[$l.local2abs(%d)] = $l.local2abs(%d)\n", localpointers[funccnt][i] + 1 + j, 
	       local_arr_inits[funccnt][i][j] + offset);
      }
    }
  }
  for (i=arg_list_cnt -1; i>-1; i--) {
    printf("%s=$e.pop\n", lookup(arg_list[i]));
    printf("$ea.chomp\n");
  }
  printf("$p.write_literal('aat')\nreturn_xfer_%d = $p.add_forward_xfer\n$p.next_line\n", funccnt);
  STACKCHECK("post_fdef");
  func_arity[funccnt] = arg_list_cnt;
}

void finishfunc(char *name) {
  printf("write('ne')\n"); /* default return value is 0 */
  printf("next_line\n");
  printf("$p.complete_forward_xfer(return_xfer_%d)\n", funccnt);
  printf("$l.popframe\n");  /* end stack frame */
  printf("goto($c.pop)\n"); /* transfer to return addr */
  printf("$p.stackdepth -= 1\n");  /* nullify effect of return value for next fn def */
  printf("next_line\n");
  printf("$p.complete_forward_xfer(func_jump)\n"); /* function was jumped in global pass */
  STACKCHECK("post_func");
}

char *funccall(char *name, int arity) {
  int i;
  char *r;
  char n[64];
  SNEWSTR(r);
  strcpy(n,name);
  sprintf(r,"# CALL %s\n", name);
  for (i=0; i<num_library_functions; i++) { /* built-in library call? */
    if (!strcmp(name, library_functions[i])) break;
  }
  if (i < num_library_functions) {
    *n = *n - ('a' - 'A'); /* upper case first letter */
    sprintf(r,"%s%s.do(%d)\n", r, n, arity);
  } else {
    sprintf(r,"%s $c.push_next_line\n",r);    /* put return addr on call stack */
    for (i=0; i<funccnt+1; i++) { /* +1 because funcs[funccnt] is the current function */
      if (!strcmp(name, funcs[i])) break;
    }
    if (i == funccnt+1) { /* no def yet */
      for (i=0; i<prefuncscnt; i++) { /* previously seen a call to this? */
	if (!strcmp(prefuncs[i],name)) break;
      }
      if (i==prefuncscnt) { /* new undefined func */
	sprintf(r,"%s write('a')\n $prefuncs_%d = $p.add_forward_xfer\n",r,prefuncscnt);
	strcpy(prefuncs[prefuncscnt++],name);
      } else { /* previously seen undefined func */
	sprintf(r,"%s write('a')\n $p.repeat_forward_xfer($prefuncs_%d)\n",r,i);
      }
    } else { /* previously defined function */
      sprintf(r,"%s goto(function_address_%d)\n",r,i);  /* jump to func */
    }
    sprintf(r,"%s next_line\n",r);
    sprintf(r,"%s $p.stackdepth += 1\n",r); /* correct stackdepth, return value received */
    sprintf(r,"%s $e.push(EtaImmediate.instance)\n",r); /* return val came back on the stack */
    sprintf(r,"%s $ea.push(%d)\n", r, IMPOSSIBLE); /* no address for func return value */
  }
  sprintf(r,"%s# END CALL %s\n", r, name);
  return r;
}

char *funcreturn() {
  char *r;
  SNEWSTR(r);
  sprintf(r,"write('ne')\n"); /* default return value is 0 */
  sprintf(r,"%s write('a')\n",r);
  sprintf(r,"%s $p.repeat_forward_xfer(return_xfer_%d)\n", r,funccnt);
  sprintf(r,"%s $p.stackdepth -= 1\n",r); /* correct stackdepth, return value doesn't affect further down */
  return r;
}

char *funcreturnval() {
  char *r;
  SNEWSTR(r);
  sprintf(r,"$e.pop\n"); /* return value on regular stack */
  sprintf(r,"%s $ea.chomp\n",r);
  sprintf(r,"%s write('a')\n",r);
  sprintf(r,"%s $p.repeat_forward_xfer(return_xfer_%d)\n",r,funccnt);
  sprintf(r,"%s $p.stackdepth -= 1\n",r); /* correct stackdepth, return value doesn't affect further down */
  return r;
}
