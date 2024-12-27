#!/usr/bin/perl -w

# eta -- Interpreter for the ETA language.
# SCCSID("%Z%%P%%I%")
#
# Debugging flags may be set by the "-d <number>" command-line option.
# <number> is interpreted as a set of bitwise components:
#1Print summary of compiled program size.
#2Print "Done." message at end of run.
#4Print execution trace: operation and stack.
#8Disassemble.
# All debugging output is to the STDERR stream.
#
# Still to be done:
#Bring minimal n-liner up to date (-T option.)
#Robustness, particularly for jump past end.

use strict;
use integer;
use Getopt::Std;

sub lineof($);
	   sub f_divide();
	   sub f_transfer();
	   sub f_address();
	   sub f_output();
	   sub f_input();
	   sub f_number($);# the only instruction that takes an argument
			sub f_subtract();
			sub f_halibut();
			sub tidy();
			sub quit(@);
			sub disassemble();


			my %opts = ( d => 0 );# we want this defined for &-checks below
			getopts("d:OT", \%opts);

# Compile program into array of characters, together with an dope
# vector of indexes into that array indicating the start of each line.
			my @chars;
			my @lines;
while (<>) {
    if ($opts{"O"}) {
	tr/etaoinsh//;
	tr/ETAOINSH//;
	tr/OILoil01/etaoinsh/;
    } else {
	tr/ETAOINSH/etaoinsh/;
    }
    s/[^etaoinsh]//g;
    if ($opts{"T"}) {
	tr/etaoinsh/netaoshi/;
    }
    push(@lines, scalar(@chars));
    push(@chars, split(/x*/, $_));
}

if ($opts{"d"} & 1) {
    print STDERR "ETA: got ", scalar(@chars), " chars in ",
    scalar(@lines), " lines\n";
}
if ($opts{"d"} & 8) {
    disassemble();
}

my @stack;
my $pc = 0;
### It's worth considering some optimisation here
for (; $pc < @chars; $pc++) {
    my $op = $chars[$pc];
    if ($opts{"d"} & 4) {
	### warning: this is slow because of all the calls to lineof()
	print $pc, "/", lineof($pc), ": ", join(" ", @stack), "  $op\n";
	### would be nice to print the argument if it's an N
    }

    if ($op eq "e") {
	f_divide();
    } elsif ($op eq "t") {
	my $tmp = f_transfer();
	$pc = $lines[$tmp]-1 if defined $tmp;
    } elsif ($op eq "a") {
	f_address();
    } elsif ($op eq "o") {
	f_output();
    } elsif ($op eq "i") {
	f_input();
    } elsif ($op eq "n") {
	my $acc = 0;
	while ((my $digit = $chars[++$pc]) ne "e") {
	    $acc = $acc*7 + index("htaoins", $digit);
	}
	f_number($acc);
    } elsif ($op eq "s") {
	f_subtract();
    } elsif ($op eq "h") {
	f_halibut();
    } else {
	quit "unrecognised instruction '$op'\n";
    }
}

tidy();


# e.g. lines = (0 4 22)
#0-3 => 1
#4-21 => 2
#22- => 3
#
#   ###This should use binary search.
#
sub lineof($) {
    my $where = shift();
    my $which = 0;
    while (defined $lines[$which] && $where >= $lines[$which]) {
	$which++;
    }
    return $which;
}


sub f_divide() {
    my $b = pop(@stack);
    defined $b or quit "dividE from empty stack";
    my $a = pop(@stack);
    defined $a or quit "dividE from shallow stack";
    push(@stack, $a / $b);
    push(@stack, $a % $b);
}

sub f_transfer() {
    my $addr = pop(@stack);
    defined $addr or quit "Transfer with empty stack";
    my $cond = pop(@stack);
    defined $cond or quit "Transfer with shallow stack";
    return undef unless $cond;
    if ($addr == 0) {
	# special case: jump to zero => stop
	tidy();
    } elsif ($addr < 0) {
	quit "Transfer to negative address $addr!";
    }

    return $addr-1;# $addr is 1-based; $lines is 0-based.
    }

sub f_address() {
    push(@stack, lineof($pc)+1);
}

sub f_output() {
    my $val = pop(@stack);
    defined $val or quit "Output from empty stack";
    print(chr($val));
}

sub f_input() {
    my $val;
    my $res = read(STDIN, $val, 1);
    defined $res or quit "Input error: $!";
    if ($res == 0) {
	# read zero chars => end of file: hard-code the value
	push(@stack, -1);
    } else {
	# read a character: push its code
	push(@stack, ord($val));
    }
}

sub f_number($) {
    my $arg = shift();
    push(@stack, $arg);
}

sub f_subtract() {
    my $b = pop(@stack);
    defined $b or quit "Subtract from empty stack";
    my $a = pop(@stack);
    defined $a or quit "Subtract from shallow stack";
    push(@stack, $a-$b);
}

sub f_halibut() {
    my $copy = 0;
    my $which = pop(@stack);
    defined $which or quit "Halibut on empty stack";
    if ($which <= 0) {
	$which = -$which;
	$copy = 1;
    }
    if ($which >= @stack) {
	quit "Halibut from beneath bottom of stack";
    }
    my $val = $stack[@stack-($which+1)];
    splice(@stack, @stack-$which-1, 1) unless $copy;
    push(@stack, $val);
}


sub tidy() {
    print STDERR "Finished.\n" if $opts{"d"} & 2;
    if (@stack != 0) {
	print STDERR ("Warning: ", scalar(@stack), " elements left on stack: ",
		      join(" ", @stack), "\n");
    }
    exit 0;
}


sub quit(@) {
    print "$ARGV: ", lineof($pc), ": ", @_, "\n";
    exit (1);
}


sub disassemble() {
    my $c = 0;# index into @chars
	my $l = 0;# index into @lines

	while ($c < @chars) {
	    my $ch = $chars[$c++];
	    print STDERR uc $ch;
	    if ($ch eq "n") {
		    # It's a "Number" instruction: generate its argument
		my $acc = 0;
		while ((my $digit = $chars[$c++]) ne "e") {
		    $acc = $acc*7 + index("htaoins", $digit);
		}
		print STDERR $acc;
	    }

	    if ($l < @lines-1 && $c >= $lines[$l+1]) {
		print STDERR "\n";
		$l++;
	    } else {
		print STDERR " ";
	    }
	}
    print STDERR "\n";
    exit 1;
}

