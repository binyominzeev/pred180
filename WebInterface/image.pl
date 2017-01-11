#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;

use Chart::Gnuplot;
use CGI;

# ===================== parameters =====================

# ===================== initialize =====================

my $q=CGI->new;
$q->import_names('GET');

my $dir="/home/adam/git/wordtime/diagrams-big/frequency/".$GET::dataset;
my @timescale=get_dataset_timescale();
my $timescale=(scalar @timescale)-1;

my $interval_start=0;
my $interval_end=int($timescale/2);

if ($GET::showall == 1) {
	$interval_end*=2;
}

my $word_curve=wordset_load("$dir/wordtime-words.txt", $interval_start, $interval_end);

print "Content-type: image/png\n\n";

my @self_curve=normalize_min_max(@{$word_curve->{$GET::word}});
my $tmpfile=temp_file_create(\@self_curve);
my $neighbors_file;

my $egy=int($timescale/4);
my $ketto=int(2*$timescale/4);
my $harom=int(3*$timescale/4);

my $grid="set arrow from $egy, graph 0 to $egy, graph 1 nohead\n".
	"set arrow from $ketto, graph 0 to $ketto, graph 1 nohead\n".
	"set arrow from $harom, graph 0 to $harom, graph 1 nohead\n".
	"set arrow from graph 0, 0.5 to graph 1, 0.5 nohead\n";

#$grid="";
my $plot="set terminal png\n";

if ($GET::showneighbors == 0) {
	my $min=my_min(@self_curve);
	my $max=my_max(@self_curve);
	
	($min, $max)=show_num($min, $max);
	
	$plot.=$grid;
	$plot.="set yrange [$min:$max]\n";
}

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
