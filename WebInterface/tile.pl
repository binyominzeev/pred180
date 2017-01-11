#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;

use GD::Simple;
use Chart::Gnuplot;
use CGI;

# ===================== parameters =====================

my $box_size=30;
my $margin_size=5;

# ===================== initialize =====================

my $q=CGI->new;
$q->import_names('GET');

print "Content-type: image/png\n\n";

my @tiles=split/,/, $GET::tile;
my $tiles=scalar @tiles;

my @ht=split/-/, $tiles[0];
my $ht=scalar @ht;
my @wd=split//, $ht[0];
my $wd=scalar @wd;

my $small_wd=$box_size/$wd;
my $small_ht=$box_size/$ht;

my $img_wd=$tiles*($margin_size+$box_size) + $margin_size;
my $img_ht=$box_size + 2*$margin_size;

my $img=GD::Simple->new($img_wd, $img_ht);
$img->bgcolor('white');
$img->fgcolor('black');

my $x=$margin_size;
my $y=$margin_size;

my $this_box_x=$margin_size;

for my $tile (@tiles) {
	my @lines=split/-/, $tile;
	for my $line (@lines) {
		my @cells=split//, $line;
		for my $cell (@cells) {
			if ($cell == "1") {
				$img->bgcolor("lightblue");
			} else {
				$img->bgcolor("white");
			}
			
			$img->rectangle($x,$y,$x+$small_wd,$y+$small_ht);
			print STDERR "($x,$y,$x+$small_wd,$y+$small_ht)\n";
			$x+=$small_wd;
		}
		$x=$this_box_x;
		$y+=$small_ht;
	}
	
	$this_box_x+=$box_size+$margin_size;
	$x=$this_box_x;
	$y=$margin_size;
}

print $img->png;
