#! /usr/bin/perl

use strict;
use warnings 'all';
no warnings 'recursion';
use GD;

#
# Begin of configurable part
#

my $font = gdLargeFont;		# gdGiantFont
my $W = 80;
my $H = 25;
my $rw = 4;
my $rh = 5;
my %colors = (
	bg	=> [255, 255, 255],
	text	=> [  0,   0,   0],
	flows	=> [
		[255, 153, 255], [255, 153, 204],
		[255, 153, 153], [255, 204, 153],
		[255, 255, 153], [204, 255, 153],
		[153, 255, 153], [153, 255, 204],
		[153, 255, 255], [153, 204, 255],
		[153, 153, 255], [204, 153, 255],
	],
);

#
# End of configurable part
#

my ($w, $h, $im, @page, @vpage, $WW, $HH, $color_bg, $color_text, @color);
my @dir = ([1, 0], [0, 1], [-1, 0], [0, -1]);	# ">v<^"
my $color_cur = 1;

sub	bef_parse
{
	my ($file) = @_;
	my $max_W = 0;

	open F, $file	or die "error open $file: $!";
	while (<F>) {
		chomp;
		die "line $. too long"		if length > $W;
		$max_W = length			if length > $max_W;
		push @page, [ split // ];
		die "too many lines"		if @page > $H;
	}
	close F		or die "error close $file: $!";
	($WW, $HH) = ($W, $H);
	$W = $max_W;
	$H = @page;
}

sub	rec
{
	my ($x, $y, $dir, $out, $str, $newcolor) = (@_, 0, 0, 0, 0, 0, 0);
	my $c;

	$color_cur++	if $newcolor;
	if ($out) {
		return	if $vpage[$y][$x][($dir + 2) & 3]{o};
		$vpage[$y][$x][($dir + 2) & 3]{o} = $color_cur;
		$x += $dir[$dir][0] + $WW; $x %= $WW;
		$y += $dir[$dir][1] + $HH; $y %= $HH;
	}
	return	if $vpage[$y][$x][$dir]{i};
	$vpage[$y][$x][$dir]{i} = $color_cur;
                             
	$c = $page[$y][$x] || 0;
	if ($str) {
		rec ($x, $y, $dir, 1, $c ne '"');
	} elsif ($c eq '#') {
		$x += 2 * $dir[$dir][0] + $WW; $x %= $WW;
		$y += 2 * $dir[$dir][1] + $HH; $y %= $HH;
		rec ($x, $y, $dir, 0, 0);
	} elsif ($c =~ /[>v<^]/) {
		$dir = index ">v<^", $c;
		rec ($x, $y, $dir, 1, 0);
	} elsif ($c eq '|') {
		rec ($x, $y, $_, 1, 0, 1)	for (1, 3);
	} elsif ($c eq '_') {
		rec ($x, $y, $_, 1, 0, 1)	for (0, 2);
	} elsif ($c eq '?') {
		rec ($x, $y, $_, 1, 0, 1)	for 0 .. 3;
	} elsif ($c eq '"') {
		rec ($x, $y, $dir, 1, 1);
	} elsif ($c ne '@') {
		rec ($x, $y, $dir, 1, 0);
	}
}

sub	vis_init
{
	($w, $h) = ($font->width, $font->height);
	$im = new GD::Image ($W * $w, $H * $h)	or die;
	
	$color_bg	= $im->colorAllocate (@{ $colors{bg} });
	$color_text	= $im->colorAllocate (@{ $colors{text} });
	$color[$_]	= $im->colorAllocate (@{ $colors{flows}[$_] })
		for 0 .. $#{ $colors{flows} };
}
 
sub	vis_draw
{
	my ($x, $y, $dir, $c);

	for $y (0 .. $H) { for $x (0 .. $W) { for $dir (0 .. 3) {
		$c = $vpage[$y][$x][$dir]{o} || $vpage[$y][$x][$dir]{i};
		if (defined $c) {
			$im->filledRectangle (
				$w * $x + ($dir != 0) * $w / $rw,
				$h * $y + ($dir != 1) * $h / $rh,
				$w * $x + ($rw - ($dir != 2)) * $w / $rw,
				$h * $y + ($rh - ($dir != 3)) * $h / $rh,
				$color[$c % @color]);
		}
	} } }
	for $y (0 .. $H) {
		for $x (0 .. $W) {
			$im->string ($font, $x * $w, $y * $h,
				$page[$y][$x], $color_text)
				if defined $page[$y][$x];
		}
	}
}

sub	vis_out
{
	my ($file) = @_;

	open F, ">$file"	or die;
	binmode F;
	print F $im->png;
	close F			or die;
}

die "Usage: $0 source.bef output.png\n"		if @ARGV < 1;

bef_parse $ARGV[0];
vis_init;
rec;
vis_draw;
vis_out $ARGV[1];