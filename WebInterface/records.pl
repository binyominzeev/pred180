#!/usr/bin/perl
use strict;
use warnings;

use CGI qw/ :standard -debug /;
use Data::Dumper;

# ===================== parameters =====================

my @dirs=qw/aps nyt patent so wos zeit/;
my @patterns=qw/0110-1001,0010-1101,0100-1011 1001-0110,1101-0010,1011-0100 01-10, 10-01,/;

# ===================== initialize =====================

my $q=CGI->new;
my $row=$q->param('row');

print "Content-type: text/html\n\n";

# ===================== parameters table =====================

my $i=1;
my @param_line;
my @parameters=split/\n/, `cat parameters.txt`;

for my $param_line (@parameters) {
	if ($i == $row) {
		@param_line=split/\t/, $param_line;
	}
	$i++;
}

my ($dataset, $pattern_i, $neighbors, $radius_tolerance, $in_tolerance, $out_tolerance)=@param_line;

my @pattern=split/,/, $patterns[$pattern_i];

my $dir="/home/adam/git/wordtime/diagrams-big/frequency/$dataset";

print "<script>neighborCount=$neighbors;</script>\n".
	"<script>dataset='$dataset';</script>\n";

# ===================== records table =====================

my @timescale=get_dataset_timescale();
my $timescale=(scalar @timescale)-1;

my $interval_start=0;
my $interval_end=$timescale;

my $word_curve;

print "<table id=\"records_table\" width=\"100%\" border=\"1\">\n".
	"<thead><tr>\n".
	"<th>Word</th>\n".
	"<th>Diffseq</th>\n".
	"<th>Average distance</th>\n".
	"<th>In-score</th>\n".
	"<th>In-class</th>\n".
	"<th>Out-score</th>\n".
	"<th>Out-class</th>\n".
	"</tr></thead>\n<tbody>";

$word_curve=wordset_load("$dir/wordtime-words.txt", $interval_start, $interval_end);
my ($diffseq, $radius)=diffseq_load("neighbors-$neighbors-$dataset.txt");

my $pattern_fit=pattern_comparison_multiple(@pattern);

my $tp=0;
my $tn=0;
my $fp=0;
my $fn=0;

for my $word (sort { $pattern_fit->{$b} <=> $pattern_fit->{$a} } keys %$pattern_fit) {
	my $this_radius=$radius->{$word};
	
	my $in_score=in_score($diffseq->{$word});
	
	if ($pattern_i == 1) { $in_score=1-$in_score; }
	
	my $in_class=in_class($in_score, $this_radius);
	my $out_score=$pattern_fit->{$word};
	my $out_class=out_class($out_score);
	
	if ($in_class == 1 && $out_class == 1) { $tp++; }
	if ($in_class == 0 && $out_class == 0) { $tn++; }
	if ($in_class == 1 && $out_class == 0) { $fp++; }
	if ($in_class == 0 && $out_class == 1) { $fn++; }
	
	($this_radius, $in_score, $out_score)=show_num($this_radius, $in_score, $out_score);
	
	print "<tr value=\"$word\" class=\"clickable\">\n".
		"<td>$word</td>\n".
		"<td class=\"diffseq\">".$diffseq->{$word}."</td>\n".
		"<td>$this_radius</td>\n".
		"<td>$in_score</td>\n".
		"<td>$in_class</td>\n".
		"<td>$out_score</td>\n".
		"<td>$out_class</td>\n".
		"</tr>\n";
}

print "</tbody></table>\n";

save_fp_fn($tp, $tn, $fp, $fn);

# ===================== functions =====================

sub get_dataset_timescale {
	return split/\n/, `cut -d" " -f1 $dir/record-count.txt`;
}

sub save_fp_fn {
	my ($tp, $tn, $fp, $fn)=@_;
	
	my $i=1;
	my @parameters=split/\n/, `cat parameters.txt`;

	open OUT, ">parameters.txt";
	for my $param_line (@parameters) {
		if ($i == $row) {
			my @param_line=split/\t/, $param_line;
			my @new_param_line=@param_line[0..5];
			
			push @new_param_line, $tp;
			push @new_param_line, $tn;
			push @new_param_line, $fp;
			push @new_param_line, $fn;
			
			$param_line=join "\t", @new_param_line;
		}
		print OUT "$param_line\n";
		$i++;
	}
	close OUT;
}

sub in_score {
	my $diffseq=shift;
	
	my $fel=int($timescale/2);
	my $negyed=int($timescale/4);
	
	my $left=substr($diffseq, 0, $negyed);
	my $right=substr($diffseq, -$negyed);
	
	$left=~s/\-//g;
	$right=~s/\+//g;
	
	return length($left.$right)/$fel;
}

sub in_class {
	my $score=shift;
	my $radius=shift;
	
	#if ($score > 0.8) {
	if ($score >= 1 - $in_tolerance && $radius >= $radius_tolerance) {
		return 1;
	} else {
		return 0;
	}
}

sub out_class {
	my $score=shift;
	#if ($score > 0.75) {
	if ($score >= 1 - $out_tolerance) {
		return 1;
	} else {
		return 0;
	}
}

sub peakiness {
	my $word_curve=shift;
	my @word_curve=normalize_min_max(@$word_curve);
	
	my $avg=my_avg(@word_curve);
	my $max=0;
	
	for my $val (@word_curve) {
		my $x=($val-$avg)/$avg;
		if ($x > $max) { $max=$x; }
	}
	
	return $max;
}

sub show_num {
	return map { sprintf("%.3f", $_) } @_;
}

sub diffseq_load {
	my $filename=shift;
	
	my %diffseq;
	my %radius;
	
	open IN, "<$filename";
	while (<IN>) {
		chomp;
		my ($word, $diffseq, $radius)=split/ /, $_;
		$diffseq{$word}=$diffseq;
		$radius{$word}=$radius;
	}
	close IN;
	
	return (\%diffseq, \%radius);
}

sub pattern_comparison_multiple {
	my @patterns=@_;
	
	my @fits;
	for my $pattern (@patterns) {
		push @fits, pattern_comparison($pattern);
	}
	
	my %fits;
	for my $word (keys %{$fits[0]}) {
		$fits{$word}=my_max(map { $fits[$_]->{$word} } (0..$#fits));
	}
	
	return \%fits;
}

sub pattern_comparison {
	my $pattern=shift;
	
	# ========== create and prepare pattern ==========

	my $pattern_elements=0;
	my @pattern_lines=split/\-/, $pattern;
	@pattern_lines=reverse @pattern_lines;
	
	my @pattern;
	
	my $wd=0;
	my $ht=scalar @pattern_lines;
	
	for my $i (0..$#pattern_lines) {
		my @line=split//, $pattern_lines[$i];
		$wd=scalar @line;
		
		for my $j (0..$#line) {
			$pattern[$j]->[$i]=$line[$j];
			if ($line[$j] == 1) { $pattern_elements++; }
		}
	}
	
	# ========== fit words to pattern ==========
	
	my %pattern_fit;
	my $debug=0;
	
	open IN, "<$dir/wordtime-words.txt";
	while (<IN>) {
		chomp;
		my @line=split/ /, $_;
		my $word=shift @line;
		
		#if ($pattern eq "1001-0110" && ($word eq "photoneutron")) {
		#	$debug=1;
		#	open OUT, ">debug-$word.txt";
		#} else {
		#	$debug=0;
		#}
		
		my @orig_line=@line;
		@line=normalize_min_max(@line);
		my $length=scalar @line;
		my $point_x=0;
		my $x_step=1/$length;
		
		my @box_counts;
		
		my $i=0;
		
		for my $point_y (@line) {
			my $x_box=point_box($point_x, $wd);
			my $y_box=point_box($point_y, $ht);

			if ($pattern[$x_box]->[$y_box] == 1) {
				$box_counts[$x_box]->[$y_box]++;
			}
			
			if ($debug == 1) {
				print OUT "$i $point_y $x_box $y_box $pattern[$x_box]->[$y_box]\n";
			}
			
			$point_x+=$x_step;
			$i++;
		}
		
		my $fit=0;
		my $box_max=int($length/$pattern_elements);
		
		for my $x_box (0..$#pattern) {
			for my $y_box (0..$#{$pattern[$x_box]}) {
				if ($pattern[$x_box]->[$y_box] == 1) {
					$fit+=my_min($box_max, $box_counts[$x_box]->[$y_box]);
					#$fit+=$box_counts[$x_box]->[$y_box];
					
					if ($debug == 1) {
						print OUT "\n$x_box $y_box $fit my_min($box_max, $box_counts[$x_box]->[$y_box])";
					}
				}
			}
		}

		if ($debug == 1) {
			close OUT;
		}
		
		$pattern_fit{$word}=$fit/$length;
	}
	close IN;
	
	return \%pattern_fit;
}

sub point_box {
	my ($point, $boxes)=@_;
	if ($point == 1) {
		return $boxes-1;
	}
	return int($point*$boxes);
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

sub normalize_max {
	my $max=my_max(@_);
#	if ($max == 0) { return @_; }
	
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

sub my_avg {
	my $sum=my_sum(@_);
	if ($sum == 0) { return 0; }
	return $sum/(scalar @_);
}
