/*
 *	"DHRYSTONE" Benchmark Program
 *
 */
#ifndef __GNUC__
#include "libeta.h"
#define LOOPS	50		/* Use this for ETA machines */
#else
#include <stdio.h>
#define LOOPS	25000000	/* Use this for faster machines */
#endif


#define	TRUE		1
#define	FALSE		0

/*
 * Package 1
 */
int		IntGlob;
int		BoolGlob;
char		Char1Glob;
char		Char2Glob;
int	Array1Glob[51];

Proc2(IntParIO)
int	*IntParIO;
{
	int		IntLoc;
	int		EnumLoc;

	IntLoc = *IntParIO + 10;
	for(;;)
	{
		if (Char1Glob == 'A')
		{
			--IntLoc;
			*IntParIO = IntLoc - IntGlob;
			EnumLoc = 1;
		}
		if (EnumLoc == 1)
			break;
	}
}

Proc4()
{
	int	BoolLoc;

	BoolLoc = Char1Glob == 'A';
	BoolLoc |= BoolGlob;
	Char2Glob = 'B';
}

Proc5()
{
	Char1Glob = 'A';
	BoolGlob = FALSE;
}

Proc7(IntParI1, IntParI2, IntParOut)
int	IntParI1;
int	IntParI2;
int	*IntParOut;
{
	int	IntLoc;

	IntLoc = IntParI1 + 2;
	*IntParOut = IntParI2 + IntLoc;
}

Proc8(Array1Par, IntParI1, IntParI2)
int	Array1Par[];
int	IntParI1;
int	IntParI2;
{
	int	IntLoc;
	int	IntIndex;

	IntLoc = IntParI1 + 5;
	Array1Par[IntLoc] = IntParI2;
	Array1Par[IntLoc+1] = Array1Par[IntLoc];
	Array1Par[IntLoc+30] = IntLoc;
	for (IntIndex = IntLoc; IntIndex <= (IntLoc+1); ++IntIndex)
		;
	IntGlob = 5;
}

int Func1(CharPar1, CharPar2)
char	CharPar1;
char	CharPar2;
{
	char	CharLoc1;
	char	CharLoc2;

	CharLoc1 = CharPar1;
	CharLoc2 = CharLoc1;
	if (CharLoc2 != CharPar2)
		return (1);
	else
		return (2);
}

int Func2(StrParI1, StrParI2)
char 	*StrParI1;
char	*StrParI2;
{
	int		IntLoc;
	char	CharLoc;

	IntLoc = 1;
	while (IntLoc <= 1)
		if (Func1(StrParI1[IntLoc], StrParI2[IntLoc+1]) == 1)
		{
			CharLoc = 'A';
			++IntLoc;
		}
	if (CharLoc >= 'W' && CharLoc <= 'Z')
		IntLoc = 7;
	if (CharLoc == 'X')
		return(TRUE);
	else
	{
		if (strcmp(StrParI1, StrParI2) > 0)
		{
			IntLoc += 7;
			return (TRUE);
		}
		else
			return (FALSE);
	}
}

Proc0()
{
	int		IntLoc1;
	int		IntLoc2;
	int		IntLoc3;
	char		CharLoc;
	char		CharIndex;
	char		String1Loc[31];
	char		String2Loc[31];
	int             i;

for (i = 0; i < LOOPS; ++i)
{

	Proc5();
	Proc4();
	IntLoc1 = 2;
	IntLoc2 = 3;
	strcpy(String2Loc, "DHRYSTONE PROGRAM, 2'ND STRING");
	BoolGlob = ! Func2(String1Loc, String2Loc);
	while (IntLoc1 < IntLoc2)
	{
		IntLoc3 = 5 * IntLoc1 - IntLoc2;
		Proc7(IntLoc1, IntLoc2, &IntLoc3);
		++IntLoc1;
	}
	Proc8(Array1Glob, IntLoc1, IntLoc3);
	for (CharIndex = 'A'; CharIndex <= Char2Glob; ++CharIndex)
		if (Func1(CharIndex, 'C'))
			;
	IntLoc3 = IntLoc2 * IntLoc1;
	IntLoc2 = IntLoc3 / IntLoc1;
	IntLoc2 = 7 * (IntLoc3 - IntLoc2) - IntLoc1;
	Proc2(&IntLoc1);

}

}



main()
{
  printf("**** etastone test ****\n");
  Proc0();
  printf("%d loops done\n", LOOPS);
}

