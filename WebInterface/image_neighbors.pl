#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;

use Chart::Gnuplot;
use CGI;

# ===================== parameters =====================

my $q=CGI->new;
$q->import_names('GET');

my $dataset=$GET::dataset;

# ===================== initialize =====================

my $dir="/home/adam/git/wordtime/diagrams-big/frequency/$dataset";
my @timescale=get_dataset_timescale();
my $timescale=(scalar @timescale)-1;

my $interval_start=0;
my $interval_end=int($timescale/2);

if ($GET::showall == 1) {
	$interval_end*=2;
}

my $word_curve=wordset_load("$dir/wordtime-words.txt", $interval_start, $interval_end);

print "Content-type: image/png\n\n";

my @self_curve=normalize_sum(@{$word_curve->{$GET::word}});
my $tmpfile=temp_file_create(\@self_curve);
my $neighbors_file;

if ($GET::showneighbors > 0) {
	my $neighbors_data=neighbors_data($GET::word, $GET::showneighbors);
	$neighbors_file=temp_file_create($neighbors_data);
}

my $plot="set terminal png\n";

$plot.="plot '$tmpfile' with linespoints title '${GET::word}'";

if ($GET::showneighbors > 0) {
	$plot.=", \\\n'$neighbors_file' with linespoints title 'avg of ${GET::showneighbors} neighbors'";
}

open my $GP, '|-', 'gnuplot';
print {$GP} $plot;
close $GP;

#open OUT, ">>ezt.gnuplot";
#print OUT $plot;
#close OUT;

temp_file_remove($tmpfile);
if ($GET::showneighbors > 0) {
	temp_file_remove($neighbors_file);
}

# ===================== functions =====================

sub get_dataset_timescale {
	return split/\n/, `cut -d" " -f1 $dir/record-count.txt`;
}

sub show_num {
	return map { sprintf("%.5f", $_) } @_;
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
	
	@sum_curve=normalize_sum(@sum_curve);
	return \@sum_curve;
}

sub temp_file_create {
	my @dx;
	my @dy;
	
	if (@_ == 1) {
		my $dy=shift;
		@dy=@$dy;
		@dx=(0..$#dy);
	} elsif (@_ == 2) {
		my ($dx, $dy)=@_;
		$dx=@$dx;
		$dy=@$dy;
	}
	
	my $filename=generate_random_string(7).".tmp";
	
	open OUT, ">$filename";
	for my $i (0..$#dx) {
		print OUT "$dx[$i] $dy[$i]\n";
	}
	close OUT;
	
	return $filename;
}

sub temp_file_remove {
	my $filename=shift;
	unlink $filename;
}

sub generate_random_string {
	my $length_of_randomstring=shift;

	my @chars=('a'..'z','A'..'Z','0'..'9','_');
	my $random_string;
	for (1..$length_of_randomstring) {
		$random_string.=$chars[rand @chars];
	}
	
	return $random_string;
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

sub normalize_sum {
	my $max=my_sum(@_);
	if ($max == 0) { return @_; }
	
	my @a;
	for (@_) {
		push @a, $_/$max;
	}
	return @a;
}

sub my_min {
	my $min=100000;
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

sub my_sum {
	my $sum=0;
	for (@_) {
		$sum+=$_;
	}
	return $sum;
}
