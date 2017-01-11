#!/usr/bin/perl
use strict;
use warnings;

use CGI;
use Term::ProgressBar::Simple;

# ===================== parameters =====================

my $dataset="patent";
my $dir="/home/adam/git/wordtime/diagrams-big/frequency/$dataset";
my $neighbor_count=20;

print STDERR "$dataset, $neighbor_count\n";

# ===================== initialize =====================

my @timescale=get_dataset_timescale();

my $interval_start=0;
my $interval_end=int(@timescale/2);

my $word_curve=wordset_load("$dir/wordtime-words.txt", $interval_start, $interval_end);
my $progress=new Term::ProgressBar::Simple(scalar keys %$word_curve);

open OUT, ">neighbors-$neighbor_count-$dataset.txt";
for my $word (keys %$word_curve) {
	my ($diffseq, $radius)=neighbors_data($word, $neighbor_count);
	print OUT "$word $diffseq $radius\n";
	
	$progress++;
}
close OUT;

# ===================== functions =====================

sub get_dataset_timescale {
	return split/\n/, `cut -d" " -f1 $dir/record-count.txt`;
}

sub neighbors_data {
	my $central_word=shift;
	my $neighbor_count=shift;
	
	my $intersection_curve=wordset_load("neighbors/$dataset/neighbors-$central_word.txt", $interval_start, $interval_end);
	
	my %word_sum;
	
	for my $word (keys %$word_curve) {
		$word_sum{$word}=0;
		for my $i (0..$#{$intersection_curve->{$word}}) {
			if ($word_curve->{$word}->[$i] > 0) {
				my $prop=$intersection_curve->{$word}->[$i]/$word_curve->{$word}->[$i];
				$word_sum{$word}+=$prop;
			}
		}
	}
	
	my @sum_curve;
	my $i=0;
	
	my $base=6;
	
	my $word_count=scalar keys %word_sum;
	
	for my $word (sort { $word_sum{$b} <=> $word_sum{$a} } keys %word_sum) {
		$i++;
		if ($i >= $neighbor_count) { last; }

		my @this_curve=@{$word_curve->{$word}};
		for my $j (0..$#this_curve) {
			$sum_curve[$j]+=$this_curve[$j]/$word_count;
		}
	}
	
	my @self_curve=@{$word_curve->{$central_word}};
	@self_curve=normalize_sum(@self_curve);
	@sum_curve=normalize_sum(@sum_curve);

	my $diffseq="";
	my $radius=0;
	
	for my $i (0..$#self_curve) {
		if ($sum_curve[$i] > $self_curve[$i]) {
			$diffseq.="+";
		} else {
			$diffseq.="-";
		}
		$radius+=abs($sum_curve[$i]-$self_curve[$i]);
		#print "$sum_curve[$i] $self_curve[$i]\n";
	}

	return ($diffseq, $radius);
}

sub normalize_min_max {
	my $min=my_min(@_);
	my $max=my_max(@_);
#	if ($max == 0) { return @_; }
	
	my @a;
	for (@_) {
		push @a, ($_-$min)/($max-$min);
	}
	return @a;
}

sub my_min {
	my $min=1;
	for (@_) {
		if ($_ < $min) { $min=$_; }
	}
	return $min;
}

sub my_max {
	my $max=0;
	for (@_) {
		if ($_ > $max) { $max=$_; }
	}
	return $max;
}

sub wordset_load {
	my ($filename, $interval_start, $interval_end)=@_;
	
	my %word_curve;
	
	open IN, "<$filename";
	while (<IN>) {
		chomp;
		my @line=split/ /, $_;
		my $word=shift @line;
		
		@line=@line[$interval_start..$interval_end];
		$word_curve{$word}=\@line;
	}
	close IN;
	
	return \%word_curve;
}

sub normalize_sum {
	my $max=my_sum(@_);
	if ($max == 0) { return @_; }
	
	my @a;
	for (@_) {
		push @a, $_/$max;
	}
	return @a;
}

sub my_sum {
	my $sum=0;
	for (@_) {
		$sum+=$_;
	}
	return $sum;
}
