#!/usr/bin/perl -w
use strict;use integer;
my($i,@l,@s,@c);
sub o{my($x,$j)=(shift,0);$j++ while defined $l[$j] && $x>=$l[$j];$j;}
sub d{print "$ARGV: ",o$i,": ",@_,"\n";exit 1}
sub p{defined(my $r=pop @s) or d"stack underflow";$r}
while(<>) {
    tr/ETAOINSH/etaoinsh/;s/[^etaoinsh]//g;
    push @l,scalar @c;push @c,split /x*/,$_;
}
for($i=0;$i<@c;$i++) {
    $_=$c[$i];
    if(/a/){push @s,(o$i)+1}
    elsif(/o/){print chr p()}
    elsif(/s/){push @s,-(p()- p())}
    elsif(/e/){my($b,$a)=(p(),p());push @s,$a/$b;push @s,$a%$b}
    elsif(/t/){
	my($addr,$cond)=(p(),p());
	if ($cond){
	    exit 0 if !$addr;
	    d"Transfer to negative address $addr!" if $addr < 0;
	    $i=$l[$addr-1]-1;
	}
    } elsif(/i/){
	my $v;defined(my $r=read(STDIN,$v,1)) or d"Input error: $!";
	push @s,$r?ord $v:-1;
    } elsif(/n/){
	my $a=0;while((my $d=$c[++$i]) ne "e"){
	    $a=$a*7+index("htaoins",$d);
	}
	push @s,$a;
    } elsif(/h/){
	my($k,$w)=(0,p());
	$w*=-1,$k=1 if $w<=0;
	d"stack underflow" if $w>=@s;
	my $val=$s[@s-($w+1)];
	splice @s,@s-$w-1,1 unless $k;
	push @s,$val;
    } else{d"unrecognised instruction '$_'\n"}
}

