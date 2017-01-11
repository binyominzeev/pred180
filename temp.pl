#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use List::Util qw/max/;

use TopinavBig::Wordtime;
use Chart::Gnuplot;

use Term::ProgressBar::Simple;
use Statistics::Basic qw(:all);

my %lines=(
	"so" => 11203031,
	"patent" => 4992224,
	"nyt" => 123761,
	"wos" => 16310187,
	"zeit" => 891431,
	"aps" => 463347
);

#my $wt=new TopinavBig::Wordtime(dataset => "so");
#$wt->{workdir}="../".$wt->{workdir};
#$wt->load_words();
#$wt->save_words();

#unify_components();
#nytimes_stat();
#generate_word_histories();
#wordtime_numbering();
#exit;

#filter_words_by_xywin(1000, 10000, 100, 1000);

#my @pos=qw/preventing chair selective particles ball surgical agents box ring chemical television/;
#my @neg=qw/aqueous fishing microwave tube novel preparing/;

#my @pos=qw/acid adhesive adjustable agents article articles attachment automatic automobile bag ball bar bearing bed belt bicycle blood box cap carrier catalyst catheter chain chair chemical coated coating combination compact composite compressor controlled coupling cutting derivatives dispenser dispensing door double electrically electromagnetic fabric fastener fiber food glass guide hand heating holder injection joint linear lock locking membrane modified molded mounted nozzle particles pharmaceutical pipe powder preventing protective pump rack release removal removing ring roller safety seal sealing selective separation shaft shoe solid speed stand steering surgical suspension tank television tray ultrasonic useful vacuum valve vehicles wall water window wire/;
#my @neg=qw/alloy aluminum aqueous aromatic automotive brake cassette ceramic construction containing continuous conveyor dental disposable feeding fibers fishing hot hydraulic microwave molding novel oil plastic polymers preparing press resin rod rotary similar steel strip tape telephone thermoplastic toy tube waste/;

#filter_records_by_words(\@pos, \@neg);

#records_yearly_history();

#year_edge_register();
#words_to_records();
#records_yearly_indegree();

#records_to_sorted_classified_files();
#choose_n_from_k(2, 10000, 1000);

#record_histories_to_word_histories();

#word_halftime_connections();

#word_halftime_connections_by_size("wordlist-intersection-np");
#word_halftime_connections_by_size("wordlist-intersection-pn");

#wordlist_intersection("words-so-1st-n.txt", "words-so-2nd-p.txt");
#wordlist_intersection("words-so-1st-p.txt", "words-so-2nd-n.txt");

#similar_curves();

#my $twitter="+++++--++++++++++-++--++++++-----+++------+---++++--------";
#my $refseq="+++++++++++++++++++++++++++++-----------------------------";
#print word_intersection($twitter, $refseq);

# click		+++++++-+++++++++-+++++++-+++----+++----------++++++-----+
# ref		+++++++++++++++++++++++++++++-----------------------------
# twitter	+++++--++++++++++-++--++++++-----+++------+---++++--------

#word_halftime_prediction();
#word_halftime_prediction_count_sort();
#word_halftime_self_vs_neighbors();

#pattern_comparison("011-110");

#diffseq_comparison("+++++++++++++++++++++++++++++");
#exit;

neighbors_traffic_collect_all();
exit;
#neighbors_traffic_collect("twitter", "perl");
#neighbors_traffic_collect("nodejs", "aws", "token");

#neighbor_stat("aws");
#neighbor_stat("nodejs");
#neighbor_stat("token");
#neighbor_stat("twitter");

my $interval_start=0;
my $interval_end=30;

my $word_curve=wordset_load("../diagrams-big/frequency/so/wordtime-words.txt", $interval_start, $interval_end);
my $word_curve_2=wordset_load("../diagrams-big/frequency/so/wordtime-words.txt", $interval_end+1, 2*$interval_end+1);

#my @inc_dec=qw/backbone displaying divs form image joomla knockout store/;
#my @dec_inc=qw/authentication config protocol schema security streaming unit/;
#my @inc=qw/series mongodb mysqli numpy route scope unexpected error neo/;

#for my $word (@inc_dec) { neighbor_stat_sum_curve($word, "neighbor-predict/inc-dec"); }
#for my $word (@dec_inc) { neighbor_stat_sum_curve($word, "neighbor-predict/dec-inc"); }
#for my $word (@inc) { neighbor_stat_sum_curve($word, "neighbor-predict/inc"); }

#print predict_plus_minus("++++++++++++++++++--++---------");
#print predict_plus("++++++++++++++++++--++---------");

print neighbor_stat_sum_curve("joomla", "neighbor-predict");
#neighbor_prediction();
#dec_prediction_evaluate();
exit;

# =============== dec_prediction eloallitasa (globalis) ===============

my $threshold=0.67;

my $thresholdr=$threshold*100;
print "$thresholdr\n";

my $progress=new Term::ProgressBar::Simple(scalar keys %$word_curve);

open my $fh, ">dec-prediction-$thresholdr.txt";
for my $word (sort keys %$word_curve) {
	#print STDERR "$word\n";
	neighbor_stat($word, $fh);
	$progress++;
}
close $fh;

# =============== functions ===============

sub neighbor_prediction {
	my $pattern_fit=pattern_comparison("01110-11011");
	my $progress=new Term::ProgressBar::Simple(scalar keys %$pattern_fit);
	
	open OUT, ">neighbor-prediction.txt";
	for my $word (sort keys %$pattern_fit) {
		print OUT "$word $pattern_fit->{$word} ";
		print OUT neighbor_stat_sum_curve($word);
		print OUT "\n";
		$progress++;
	}
	close OUT;
}

sub predict_plus_minus {
	my $diffseq=shift;
	
	my $plus=predict_plus($diffseq);
	my $minus=predict_minus($diffseq);
	
	if ($minus > $plus) {
		return -$minus;
	}
	
	return $plus;
}

sub predict_minus {
	my $diffseq=shift;
	
	my $leftpos=0;
	my $rightpos=length $diffseq;
	
	if ($diffseq =~ /^\++/) { $leftpos=length($&); }
	if ($diffseq =~ /-+$/) { $rightpos-=length($&); }
	
	my $min_inversion=length $diffseq;
	
	for my $pos ($leftpos-1..$rightpos-1) {
		my $inversion=0;
		for my $i ($leftpos..$rightpos-1) {
			my $char=substr($diffseq, $i, 1);
			my $expected="+";

			if ($i > $pos) { $expected="-"; }
			if ($char ne $expected) { $inversion++; }
			
#			print "<$char$expected> ";
		}
		if ($inversion < $min_inversion) {
			$min_inversion=$inversion;
		}
	}

	my $accuracy=$min_inversion/(length $diffseq);
	return 1-$accuracy;
}

sub predict_plus {
	my $diffseq=shift;
	
	my $leftpos=0;
	my $rightpos=length $diffseq;
	
	if ($diffseq =~ /^-+/) { $leftpos=length($&); }
	if ($diffseq =~ /\++$/) { $rightpos-=length($&); }
	
	my $min_inversion=length $diffseq;
	
	for my $pos ($leftpos-1..$rightpos-1) {
		my $inversion=0;
		for my $i ($leftpos..$rightpos-1) {
			my $char=substr($diffseq, $i, 1);
			my $expected="-";

			if ($i > $pos) { $expected="+"; }
			if ($char ne $expected) { $inversion++; }
			
#			print "<$char$expected> ";
		}
		if ($inversion < $min_inversion) {
			$min_inversion=$inversion;
		}
	}
		
	#print "$min_inversion\n";

	my $accuracy=$min_inversion/(length $diffseq);
	return 1-$accuracy;
}

sub pattern_comparison {
	my $pattern=shift;
	
	# ========== create and prepare pattern ==========

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
		}
	}
	
	#print Dumper \@pattern;
	
	# ========== fit words to pattern ==========
	
	my %pattern_fit;
	
	open IN, "<../diagrams-big/frequency/so/wordtime-words.n.txt";
	#open OUT, ">../diagrams-big/frequency/so/wordtime-pattern.n.txt";
	while (<IN>) {
		chomp;
		my @line=split/ /, $_;
		my $word=shift @line;
		
		@line=normalize_min_max(@line);
		my $length=scalar @line;
		my $point_x=0;
		my $x_step=1/$length;
		
		my $fit=0;
		
		for my $point_y (@line) {
			my $x_box=point_box($point_x, $wd);
			my $y_box=point_box($point_y, $ht);

			if ($pattern[$x_box]->[$y_box] == 1) {
				$fit++;
			}
			
			$point_x+=$x_step;
		}
		
		$pattern_fit{$word}=$fit/$length;
		#print "$word $pattern_fit{$word} $fit $length\n";
		#print OUT "$word $pattern_fit{$word}\n";
	}
	close IN;
	#close OUT;
	
	# ========== select top elements ==========
	
	#my $i=1;
	#for my $word (sort { $pattern_fit{$b} <=> $pattern_fit{$a} } keys %pattern_fit) {
	#	if ($i++ > 50) { last; }
	#	#print "$word $pattern_fit{$word}\n";
	#	print "$word ";
	#}
	#print "\n";
	
	return \%pattern_fit;
}

sub point_box {
	my ($point, $boxes)=@_;
	if ($point == 1) {
		return $boxes-1;
	}
	return int($point*$boxes);
}

sub dec_prediction_evaluate {
	my @files=split/\n/, `ls dec-prediction-*.txt`;
	for my $file (@files) {
		my @dx;
		my @dy;
		
		open IN, "<$file";
		while (<IN>) {
			chomp;
			my ($word, $x, $y)=split/ /, $_;
			
			push @dx, $x;
			push @dy, $y;
		}
		close IN;
		
		my $chart = Chart::Gnuplot->new(
			"terminal" => "png",
			"output" => "$file.png",
			"title" => "Prediction of turning of increasing words",
			"xlabel" => "rank of first nearest decreasing neighbor",
			"ylabel" => "proportion of decreasing years in 2nd half time",
		);

		my $dataset=Chart::Gnuplot::DataSet->new(
			xdata => \@dx,
			ydata => \@dy,
			style => "points",
		);
		
		$chart->plot2d($dataset);
		print "$file ".correlation(@dx, @dy)."\n";
	}
}

sub neighbor_stat_sum_curve {
	my $central_word=shift;
	my $dir=shift;
	
	my $intersection_curve=wordset_load("neighbors/neighbors-$central_word.txt", $interval_start, $interval_end);
	
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
	
	my @self_curve=@{$word_curve->{$central_word}};
	
	my @sum_curve;
	my $i=0;
	
	my $base=6;
	
	my $word_count=scalar keys %word_sum;
	
	for my $word (sort { $word_sum{$b} <=> $word_sum{$a} } keys %word_sum) {
		$i++;
		
		if ($i >= 30) { last; }
		#print "$word $word_sum{$word}\n";

		my @this_curve=@{$word_curve->{$word}};
		for my $j (0..$#this_curve) {
			$sum_curve[$j]+=$this_curve[$j]/$word_count;
		}
	}
	
	my @dx=(0..$#self_curve);
	@self_curve=normalize_sum(@self_curve);
	@sum_curve=normalize_sum(@sum_curve);
	
	my $diffseq="";
	
	for my $i (0..$#self_curve) {
		if ($sum_curve[$i] > $self_curve[$i]) {
			$diffseq.="+";
		} else {
			$diffseq.="-";
		}
		#print "$sum_curve[$i] $self_curve[$i]\n";
	}
	
	print "$diffseq\n";
	#return predict_plus_minus($diffseq);

	my $chart = Chart::Gnuplot->new(
		"terminal" => "svg",
		"output" => "$dir/$central_word.svg",
#		"yrange" => [0, 1]
	);
	
	my $dataset_a=Chart::Gnuplot::DataSet->new(
		xdata => \@dx,
		ydata => \@self_curve,
		style => "line",
	);

	my $dataset_b=Chart::Gnuplot::DataSet->new(
		xdata => \@dx,
		ydata => \@sum_curve,
		style => "line",
	);

	$chart->plot2d($dataset_a, $dataset_b);
}

sub neighbor_stat {
	my $central_word=shift;
	my $fh=shift;
	
	print $fh "$central_word ";
	
	my $diffseq=diffseq(@{$word_curve_2->{$central_word}});
	my $length=length $diffseq;
	my $pc=my_plus_count($diffseq)/$length;
	
	print $fh 1-$pc;
	print $fh "\n";
}

sub curve_direction {
	my $curve=shift;
	
	# ======= by proportion of decreasing years =======
	
	my $diffseq=diffseq(@$curve);
	my $length=length $diffseq;
	my $pc=my_plus_count($diffseq)/$length;
	
	if ($pc > $threshold) {
		return "+";
	} else {
		return "-";
	}
	
	# ======= by comparing first 5 and last 5 =======
	my $window_size=5;
	
	my $eleje=my_sum(@$curve[0..$window_size]);
	my $vege=my_sum(@$curve[$#$curve-$window_size..$#$curve]);
	
	if ($eleje > $vege) {
		return "-";
	} else {
		return "+";
	}
}

sub wordset_load {
	my ($filename, $interval_start, $interval_end)=@_;
	
	#my @lines=split/\n/, `cat $filename`;
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

sub neighbors_traffic_collect {
	my @words_to_watch=@_;
	my $words_to_watch=my_hash_array(@words_to_watch);
	
	# ============ processing titles ============
	
	my $maindir="../diagrams-big/frequency";
	my $dataset="so";
	
	print STDERR "processing titles...\n";
	
	my %neighbor_count;

	my %relevant_words;
	my @relevant_words=split/\n/, `cat $maindir/$dataset/wordtime-words.txt`;
	map { / /; $relevant_words{$`}="" } @relevant_words;
	
	my %records_count;
	my @records_count=split/\n/, `cat $maindir/$dataset/record-count.txt`;
	#map { / /; $records_count{$`}=$' } @records_count;
	map { $records_count{substr($_, 0, 7)}="" } @records_count;
	
	my $progress_2=new Term::ProgressBar::Simple($lines{$dataset});
	
	open IN, "<../../topinav/$dataset-id-title.txt";
	while (<IN>) {
		chomp;
		
		# osszes tobbi
		my ($id, $date, $title)=split/\t/, $_;
		if (!$id || !$date || !$title) { next; }

		my $year=substr($date, 0, 7);
		if (exists $records_count{$year}) {
			my $words=string_to_words($title);
			$words=my_hash_array(@$words);
			
			my $intersection=my_intersection($words, $words_to_watch);
			my $relevant_neighbors=my_intersection($words, \%relevant_words);
			
			if (scalar keys %$intersection > 0) {
				for my $this_word (keys %$intersection) {
					for my $neighbor (keys %$relevant_neighbors) {
						$neighbor_count{$this_word}->{$neighbor}->{$year}++;
					}
				}
			}
		}

		$progress_2++;
	}
	close IN;
	
	for my $this_word (keys %neighbor_count) {
		open OUT, ">neighbors-$this_word.txt";
		delete $neighbor_count{$this_word}->{$this_word};	# self-links
		for my $neighbor (sort keys %{$neighbor_count{$this_word}}) {
			my $this_data=$neighbor_count{$this_word}->{$neighbor};
			
			my @this_data;
			for my $year (sort keys %records_count) {
				if (exists $this_data->{$year}) {
					push @this_data, $this_data->{$year};
				} else {
					push @this_data, 0;
				}
			}
				
			print OUT "$neighbor ";
			print OUT join " ", @this_data;
			print OUT "\n";
		}
		close OUT;
	}
}

sub neighbors_traffic_collect_all {
	# ============ processing titles ============
	
	#my $maindir="../diagrams-big/frequency";
	my $maindir="diagrams-big";
	my $dataset="wos";
	
	print STDERR "processing titles ($dataset)...\n";
	
	my %neighbor_count;

	my %relevant_words;
	my @relevant_words=split/\n/, `cat $maindir/$dataset/wordtime-words.txt`;
	map { / /; $relevant_words{$`}="" } @relevant_words;
	
	my %records_count;
	my @records_count=split/\n/, `cat $maindir/$dataset/record-count.txt`;
	#map { / /; $records_count{$`}=$' } @records_count;
	#map { $records_count{substr($_, 0, 7)}="" } @records_count;
	map { $records_count{substr($_, 0, 4)}="" } @records_count;
	
	my $progress_2=new Term::ProgressBar::Simple($lines{$dataset});
	
	#open IN, "<../../topinav/$dataset-id-title.txt";
	open IN, "<$dataset-id-title.txt";
	while (<IN>) {
		chomp;
		
		# osszes tobbi
		my ($id, $date, $title)=split/\t/, $_;
		if (!$id || !$date || !$title) { next; }

		#my $year=substr($date, 0, 7);
		#my $year=substr($date, 0, 4);
		my $year=$date;
		
		if (exists $records_count{$year}) {
			my $words=string_to_words($title);
			$words=my_hash_array(@$words);
			
			my $relevant_words=my_intersection($words, \%relevant_words);
			@relevant_words=keys %$relevant_words;
			
			for my $i (0..$#relevant_words) {
				for my $j ($i+1..$#relevant_words) {
					my ($word_a, $word_b)=sort ($relevant_words[$i], $relevant_words[$j]);
					$neighbor_count{$word_a}->{$word_b}->{$year}++;
					$neighbor_count{$word_b}->{$word_a}->{$year}++;
				}
			}
		#} else {
		#	print Dumper \%records_count;
		#	print "\n\n$year\n\n";
		#	exit;
		}

		$progress_2++;
	}
	close IN;
	
	for my $this_word (keys %neighbor_count) {
		open OUT, ">neighbors/$dataset/neighbors-$this_word.txt";
		delete $neighbor_count{$this_word}->{$this_word};	# self-links
		for my $neighbor (sort keys %{$neighbor_count{$this_word}}) {
			my $this_data=$neighbor_count{$this_word}->{$neighbor};
			
			my @this_data;
			for my $year (sort keys %records_count) {
				if (exists $this_data->{$year}) {
					push @this_data, $this_data->{$year};
				} else {
					push @this_data, 0;
				}
			}
				
			print OUT "$neighbor ";
			print OUT join " ", @this_data;
			print OUT "\n";
		}
		close OUT;
	}
}

sub word_halftime_self_vs_neighbors {
	my %predictions;
	my @predictions=split/\n/, `cat word-halftime-prediction-p.txt`;
	map { / /; $predictions{$`}=$' } @predictions;
	
	my %word_plus;
	
	open IN, "<../diagrams-big/frequency/so/wordtime-words.txt";
	while (<IN>) {
		chomp;
		my @line=split/ /, $_;
		my $word=shift @line;
		
		my $diffseq=substr(diffseq(@line), 0, 30);  # remelem, tenyleg annyi
		$word_plus{$word}=my_plus_count($diffseq);
	}
	close IN;
	
	my %word_neighbors_plus;
	my %word_diff;
	
	for my $word (keys %predictions) {
		$word_neighbors_plus{$word}=my_plus_count($predictions{$word});
		$word_diff{$word}=$word_plus{$word}-$word_neighbors_plus{$word};
	}
	
	my $i=1;
	for my $word (sort { $word_diff{$b} <=> $word_diff{$a} } keys %word_diff) {
		if ($i++ >= 30) { last; }
		#print "$word $word_diff{$word}\n";
		print "$word ";
	}
}

sub my_plus_count {
	my $seq=shift;
	$seq=~s/\-//g;
	return length $seq;
}

sub word_halftime_prediction_count_sort {
	my %predictions;
	my @predictions=split/\n/, `cat word-halftime-prediction-n.txt`;
	map { / /; $predictions{$`}=$' } @predictions;
	
	my %prediction_count;
	
	for my $word (keys %predictions) {
		$prediction_count{$word}=my_plus_count($predictions{$word});
	}
	
	my $i=1;
	for my $word (sort { $prediction_count{$b} <=> $prediction_count{$a} } keys %prediction_count) {
		#if ($i++ >= 87) { last; }
		if ($i++ >= 29) { last; }
		#print "$word $prediction_count{$word}\n";
		print "$word ";
	}
}

sub word_halftime_prediction {

	# ============ processing titles ============
	
	my $maindir="../diagrams-big/frequency";
	my $dataset="so";

	my @words_to_watch=split/\n/, `cat $maindir/$dataset/wordtime-words.txt`;
	@words_to_watch=map { / /; $` } @words_to_watch;
	my $words_to_watch=my_hash_array(@words_to_watch);
	
	my $words_inc=my_hash_array_from_file("words-so-1st-p.txt");
	my $words_dec=my_hash_array_from_file("words-so-1st-n.txt");
	
	print STDERR "processing titles...\n";
	
	my %dec_count;
	my %inc_count;

	my %records_count;
	my @records_count=split/\n/, `cat $maindir/$dataset/record-count.txt`;
	#map { / /; $records_count{$`}=$' } @records_count;
	map { $records_count{substr($_, 0, 7)}="" } @records_count;
	
	my $progress_2=new Term::ProgressBar::Simple($lines{$dataset});
	
	open IN, "<../../topinav/$dataset-id-title.txt";
	#open LOG, ">log";
	while (<IN>) {
		chomp;
		
		# osszes tobbi
		my ($id, $date, $title)=split/\t/, $_;
		if (!$id || !$date || !$title) { next; }

		my $year=substr($date, 0, 7);
		if (exists $records_count{$year}) {
			my $words=string_to_words($title);
			$words=my_hash_array(@$words);
			
			my $intersection=my_intersection($words, $words_to_watch);
			
			if (scalar keys %$intersection > 0) {
				my $inc=my_intersection($words, $words_inc);
				my $dec=my_intersection($words, $words_dec);
				
				if (scalar keys %$dec > 0) {
					for my $this_word (keys %$intersection) {
						$dec_count{$this_word}->{$year}++;
					}
				}

				if (scalar keys %$inc > 0) {
					for my $this_word (keys %$intersection) {
						$inc_count{$this_word}->{$year}++;
					}
				}
			}
		}

		$progress_2++;
	}
	close IN;
	#close LOG;
	
	open OUT, ">word-halftime-prediction-p-detailed.txt";
	for my $word (sort keys %inc_count) {
		my @this_data=map { $inc_count{$word}->{$_} }
			sort keys %{$inc_count{$word}};
		
		print OUT "$word ";
		print OUT join " ", @this_data;
		print OUT "\n";
	}
	close OUT;

	open OUT, ">word-halftime-prediction-n-detailed.txt";
	for my $word (sort keys %dec_count) {
		my @this_data=map { $dec_count{$word}->{$_} }
			sort keys %{$dec_count{$word}};
		
		print OUT "$word ";
		print OUT join " ", @this_data;
		print OUT "\n";
	}
	close OUT;
	
	open OUT, ">word-halftime-prediction-p.txt";
	for my $word (sort keys %inc_count) {
		my @this_data=map { $inc_count{$word}->{$_} }
			sort keys %{$inc_count{$word}};
		
		@this_data=@this_data[0..30];
		print OUT "$word ";
		print OUT diffseq(@this_data);
		print OUT "\n";
	}
	close OUT;

	open OUT, ">word-halftime-prediction-n.txt";
	for my $word (sort keys %dec_count) {
		my @this_data=map { $dec_count{$word}->{$_} }
			sort keys %{$dec_count{$word}};
		
		@this_data=@this_data[0..30];
		print OUT "$word ";
		print OUT diffseq(@this_data);
		print OUT "\n";
	}
	close OUT;
}

sub diffseq_comparison {
	my $refseq=shift;
	my %word_diffseq;
	my %word_distances;
	
	my $length=length($refseq);
	
	open IN, "<../diagrams-big/frequency/so/wordtime-words.n.txt";
	open OUT, ">../diagrams-big/frequency/so/wordtime-diffseq.n.txt";
	while (<IN>) {
		chomp;
		my @line=split/ /, $_;
		my $word=shift @line;
		
		my $diffseq=diffseq(@line);
		$word_diffseq{$word}=substr($diffseq, 0, $length);
		$word_distances{$word}=word_intersection($refseq, $word_diffseq{$word});

		print OUT "$word $diffseq\n";
	}
	close IN;
	close OUT;
	
	#print $word_diffseq{"click"};
	#return;
	
	my $i=1;
	for my $word (sort { $word_distances{$b} <=> $word_distances{$a} } keys %word_distances) {
		if ($i++ > 80) { last; }
		#print "$word $word_distances{$word}\n";
		print "$word ";
	}
	print "\n";
}

sub word_intersection {
	my ($s1, $s2)=@_;
	
	my $intersection=0;
	for my $i (0..length($s1)) {
		my $letter1=substr($s1, $i, 1);
		my $letter2=substr($s2, $i, 1);
		
		if ($letter1 eq $letter2) {
			$intersection++;
		}
	}
	
	return $intersection;
}

sub diffseq {
	my @seq=my_smoothing(@_);
	@seq=my_smoothing(@seq);
	@seq=my_smoothing(@seq);
	
	my $diffseq="";
	my $last_element=shift @seq;
	
	for my $this_element (@seq) {
		if ($this_element >= $last_element) {
			$diffseq.="+";
		} else {
			$diffseq.="-";
		}
		$last_element=$this_element;
	}
	
	return $diffseq;
}

sub my_smoothing {
	my $last_element=shift;
	my @smooth;
	for my $this_element (@_) {
		push @smooth, ($this_element+$last_element)/2;
		$last_element=$this_element;
	}
	
	return @smooth;
}

sub similar_curves {
	my @up=map { $_/30 } (0..30);
	my @down=reverse @up;
	my @basic=(@down, @up);
	
	my %word_distances;
	
	open IN, "<../diagrams-big/frequency/so/wordtime-words.n.txt";
	while (<IN>) {
		chomp;
		my @line=split/ /, $_;
		my $word=shift @line;
		
		@line=normalize_min_max(@line);
		
		#if ($word eq "hover") {
		#	print join "\n", @line;
		#	exit;
		#}

		my @distance;
		@distance=map { abs($line[$_]-$basic[$_]) } (0..$#basic);
		#my $distance=my_sum(@distance);
		my $distance=max(@distance);
		
		$word_distances{$word}=$distance;
	}
	close IN;
	
	#print "twitter $word_distances{twitter}\n";
	
	my $i=1;
	for my $word (sort { $word_distances{$a} <=> $word_distances{$b} } keys %word_distances) {
		if ($i++ > 40) { last; }
		#print "$word $word_distances{$word}\n";
		print "$word ";
	}
	print "\n";
}

sub wordlist_intersection {
	my ($file_a, $file_b)=@_;
	
	open OUT, ">wordlist-intersection-np.txt";
	open INA, "<$file_a";
	open INB, "<$file_b";
	
	my $line_a=<INA>;
	my $line_b=<INB>;
	
	my $word_a=wordlist_chomp($line_a);
	my $word_b=wordlist_chomp($line_b);
	
	while ($word_a && $word_b) {
		if ($word_a lt $word_b) {
			#print "1 ($word_a lt $word_b)\n";
			
			my $line_a=<INA>;
			$word_a=wordlist_chomp($line_a);
		} elsif ($word_b lt $word_a) {
			#print "2 ($word_b lt $word_a)\n";
			
			my $line_b=<INB>;
			$word_b=wordlist_chomp($line_b);
		} else {
			#print "3 $word_a";
			print OUT "$word_b\n";
			
			my $line_a=<INA>;
			my $line_b=<INB>;
			
			$word_a=wordlist_chomp($line_a);
			$word_b=wordlist_chomp($line_b);
		}
	}
	close INA;
	close INB;
	close OUT;
}

sub wordlist_chomp {
	my $word=shift;
	if ($word) {
		$word=~/ /;
		return $`;
	} else {
		return 0;
	}
}

sub word_halftime_connections_by_size {
	my $file=shift;
	my @words=split/\n/, `cat $file.txt`;
	
	my %sizes;
	my @sizes=split/\n/, `cat words-so-1st.txt`;
	map {
		my ($word, $size, $end)=split/ /, $_;
		$sizes{$word}=$size;
	} @sizes;
	
	open OUT, ">$file.2.txt";
	for my $word (@words) {
		print OUT "$word $sizes{$word}\n";
	}
	close OUT;
}

sub word_halftime_connections {

	# ============ processing titles ============
	
	my $maindir="../diagrams-big/frequency";
	my $dataset="so";

	my @words_to_watch=qw/services/;
	my $words_to_watch=my_hash_array(@words_to_watch);
	
	#my @words_inc=qw/add api array button change data error file function getting google image list method multiple object select string table text time using value values variable/;
	#my @words_dec=qw/asp mvc net rails server sql web xml/;
	
	#my $words_inc=my_hash_array(@words_inc);
	#my $words_dec=my_hash_array(@words_dec);
	
	my $words_inc=my_hash_array_from_file("words-so-1st-p.txt");
	my $words_dec=my_hash_array_from_file("words-so-1st-n.txt");
	
	print STDERR "processing titles...\n";
	
	my %inc_count;
	my %dec_count;

	my %records_count;
	my @records_count=split/\n/, `cat $maindir/$dataset/record-count.txt`;
	#map { / /; $records_count{$`}=$' } @records_count;
	map { $records_count{substr($_, 0, 7)}="" } @records_count;
	
	#print sort join " ", keys %records_count;
	#exit;
	
	my $progress_2=new Term::ProgressBar::Simple($lines{$dataset});
	
	open IN, "<../../topinav/$dataset-id-title.txt";
	#open LOG, ">log";
	while (<IN>) {
		chomp;
		
		# osszes tobbi
		my ($id, $date, $title)=split/\t/, $_;
		if (!$id || !$date || !$title) { next; }

		my $year=substr($date, 0, 7);
		if (exists $records_count{$year}) {
			my $words=string_to_words($title);
			$words=my_hash_array(@$words);
			
			my $intersection=my_intersection($words_to_watch, $words);
			#my $intersection=my_intersection($words, $words_to_watch);
			
			if (scalar keys %$intersection > 0) {
				#my $inc=my_intersection($words, $words_inc);
				my $dec=my_intersection($words, $words_dec);
				
				for my $this_word (keys %$intersection) {
					#$inc_count{$this_word}->{$year}+=scalar keys %$inc;
					#$dec_count{$this_word}->{$year}+=scalar keys %$dec;
					#if (scalar keys %$inc > 0) {
					#	$inc_count{$this_word}->{$year}++;
					#}
					
					if (scalar keys %$dec > 0) {
						$dec_count{$this_word}->{$year}++;
					}
				}
			}
		}

		$progress_2++;
	}
	close IN;
	#close LOG;
	
	for my $word (keys %inc_count) {
		open OUT, ">word-halftime-connections-$word.txt";
		for my $year (sort keys %{$inc_count{$word}}) {
			print OUT "$year $inc_count{$word}->{$year} $dec_count{$word}->{$year}\n";
		}
		close OUT;
	}
}

sub my_intersection {
	my ($a, $b)=@_;
	
	#my $intersection=0;
	my %intersection;
	for my $elem (keys %$a) {
		if (exists $b->{$elem}) {
			#$intersection++;
			$intersection{$elem}=""
		}
	}
	
	return \%intersection;
}

sub my_hash_array {
	my %hash;
	map { $hash{$_}="" } @_;
	return \%hash;
}

sub my_hash_array_from_file {
	my $file=shift;
	my @lines=split/\n/, `cat $file`;
	
	my %hash;
	map { $hash{wordlist_chomp($_)}="" } @lines;
	
	return \%hash;
}

sub record_histories_to_word_histories {
	# ============ loading record histories ============
	my %record_history;
	
	print STDERR "loading record histories...\n";
	my $progress=new Term::ProgressBar::Simple(972530);
	
	open IN, "<record-yearly-history.csv";
	<IN>;
	while (<IN>) {
		chomp;
		
		my @indeg=split/,/, $_;
		my $id=shift @indeg;
		pop @indeg;
		
		@{$record_history{$id}}=@indeg;
		$progress++;
	}
	close IN;

	# ============ processing titles ============
	
	my %word_history;
	my @word_history=qw/acid adhesive adjustable agents article articles attachment automatic automobile bag ball bar bearing bed belt bicycle blood box cap carrier catalyst catheter chain chair chemical coated coating combination compact composite compressor controlled coupling cutting derivatives dispenser dispensing door double electrically electromagnetic fabric fastener fiber food glass guide hand heating holder injection joint linear lock locking membrane modified molded mounted nozzle particles pharmaceutical pipe powder preventing protective pump rack release removal removing ring roller safety seal sealing selective separation shaft shoe solid speed stand steering surgical suspension tank television tray ultrasonic useful vacuum valve vehicles wall water window wire alloy aluminum aqueous aromatic automotive brake cassette ceramic construction containing continuous conveyor dental disposable feeding fibers fishing hot hydraulic microwave molding novel oil plastic polymers preparing press resin rod rotary similar steel strip tape telephone thermoplastic toy tube waste/;
	map { @{$word_history{$_}}=() } @word_history;
	
	print STDERR "processing titles...\n";
	
	my $maindir="../diagrams-big/frequency";
	my $dataset="patent";

	my %records_count;
	my @records_count=split/\n/, `cat $maindir/$dataset/record-count.txt`;
	map { / /; $records_count{$`}=$' } @records_count;
	
	my $progress_2=new Term::ProgressBar::Simple($lines{$dataset});
	
	open IN, "<../../topinav/$dataset-id-title.txt";
	#open LOG, ">log";
	while (<IN>) {
		chomp;
		
		# osszes tobbi
		my ($id, $date, $title)=split/\t/, $_;
		if (!$id || !$date || !$title) { next; }

		my $year=substr($date, 0, 4);
		if (exists $records_count{$year}) {
			my $words=string_to_words($title);
			
			for my $word (@$words) {
				if (exists $word_history{$word} && exists $record_history{$id}) {
					my @record_history=@{$record_history{$id}};
					for my $i (0..$#record_history) {
						#print LOG "$word $id $i\n";
						$word_history{$word}->[$i]+=$record_history{$id}->[$i];
					}
				}
			}
		}

		$progress_2++;
	}
	close IN;
	#close LOG;
	
	# ============ saving word histories ============
	
	my %pos;
	my @pos=qw/acid adhesive adjustable agents article articles attachment automatic automobile bag ball bar bearing bed belt bicycle blood box cap carrier catalyst catheter chain chair chemical coated coating combination compact composite compressor controlled coupling cutting derivatives dispenser dispensing door double electrically electromagnetic fabric fastener fiber food glass guide hand heating holder injection joint linear lock locking membrane modified molded mounted nozzle particles pharmaceutical pipe powder preventing protective pump rack release removal removing ring roller safety seal sealing selective separation shaft shoe solid speed stand steering surgical suspension tank television tray ultrasonic useful vacuum valve vehicles wall water window wire/;
	map { $pos{$_}="" } @pos;
	
	open OUT, ">word-histories.txt";
	for my $word (sort keys %word_history) {
		my $stat=(exists $pos{$word} ? 1 : 2);
		print OUT "$word $stat ".(join " ", @{$word_history{$word}})."\n";
	}
	close OUT;
}

sub choose_n_from_k {
	my ($type, $n, $k)=@_;
	print `head -n$n record-yearly-history-$type.txt | shuf | head -n$k`;
}

sub records_to_sorted_classified_files {
	# ============ loading record types  ============
	my %id_type;
	
	print STDERR "loading record types...\n";
	my $progress=new Term::ProgressBar::Simple(1435170);
	
	open IN, "<records-plus-minus.txt";
	while (<IN>) {
		chomp;
		my ($id, $type)=split/ /, $_;
		$id_type{$id}=$type;
		$progress++;
	}
	close IN;
	
	# ============ loading indegs ============
	my %type_id_sum;
	
	print STDERR "loading indegs...\n";
	my $progress_2=new Term::ProgressBar::Simple(972530);
	
	open IN, "<record-yearly-history.csv";
	<IN>;
	while (<IN>) {
		chomp;
		
		my @indeg=split/,/, $_;
		my $id=shift @indeg;
		pop @indeg;
		
		@{$type_id_sum{$id_type{$id}}->{$id}}=@indeg;
		$progress_2++;
	}
	close IN;
	
	# ============ writing separate, ordered files ============
	
	for my $type (sort keys %type_id_sum) {
		print STDERR "writing type $type...\n";
		my $id_indeg=$type_id_sum{$type};

		open OUT, ">record-yearly-history-$type.txt";
		for my $id (sort { my_sum(@{$id_indeg->{$b}}) <=> my_sum(@{$id_indeg->{$a}}) } keys %$id_indeg) {
			print OUT "$id,".(join ",", @{$id_indeg->{$id}})."\n";
		}
		close OUT;
	}
}

sub records_yearly_indegree {
	my %records;
	my @records=split /\n/, `cat input-recordlist.txt`;
	map { %{$records{$_}}=(); } @records;
	
	my $maindir="../diagrams-big/frequency";
	my $dataset="patent";

	my %records_count;
	my @records_count=split/\n/, `cat $maindir/$dataset/record-count.txt`;
	map { / /; $records_count{$`}=$' } @records_count;
	
	my @years=sort { $a <=> $b } keys %records_count;
	
	my $progress=new Term::ProgressBar::Simple(78611249);
	
	open IN, "<patent_edges.txt";
	while (<IN>) {
		chomp;
		my ($from, $to, $year)=split/ /, $_;
		
		if (exists $records{$to}) {
			$records{$to}->{$year}++;
		}
		$progress++;
	}
	close IN;
	
	open OUT, ">record-yearly-history.txt";
	for my $id (keys %records) {
		print OUT "$id ";
		for my $year (@years) {
			if (exists $records{$id}->{$year}) {
				print OUT "$records{$id}->{$year} ";
			} else {
				print OUT "0 ";
			}
		}
		print OUT "\n";
	}
	close OUT;
}

sub words_to_records {
	my @words=qw/alloy aluminum aqueous aromatic automotive brake cassette ceramic construction containing continuous conveyor dental disposable feeding fibers fishing hot hydraulic microwave molding novel oil plastic polymers preparing press resin rod rotary similar steel strip tape telephone thermoplastic toy tube waste acid adhesive adjustable agents article articles attachment automatic automobile bag ball bar bearing bed belt bicycle blood box cap carrier catalyst catheter chain chair chemical coated coating combination compact composite compressor controlled coupling cutting derivatives dispenser dispensing door double electrically electromagnetic fabric fastener fiber food glass guide hand heating holder injection joint linear lock locking membrane modified molded mounted nozzle particles pharmaceutical pipe powder preventing protective pump rack release removal removing ring roller safety seal sealing selective separation shaft shoe solid speed stand steering surgical suspension tank television tray ultrasonic useful vacuum valve vehicles wall water window wire/;
	my %words;
	map { $words{$_}="" } @words;

	my $maindir="../diagrams-big/frequency";
	my $dataset="patent";

	my %records_count;
	my @records_count=split/\n/, `cat $maindir/$dataset/record-count.txt`;
	map { / /; $records_count{$`}=$' } @records_count;
	
	my $progress=new Term::ProgressBar::Simple($lines{$dataset});
	
	open IN, "<../../topinav/$dataset-id-title.txt";
	open OUT, ">input-recordlist.txt";
	while (<IN>) {
		chomp;
		
		# osszes tobbi
		my ($id, $date, $title)=split/\t/, $_;
		if (!$id || !$date || !$title) { next; }

		my $year=substr($date, 0, 4);
		if (exists $records_count{$year}) {
			my $words=string_to_words($title);
			my $stat=0;
			
			for my $word (@$words) {
				if (exists $words{$word}) {
					print OUT "$id\n";
					last;
				}
			}
		}

		$progress++;
	}
	close IN;
	close OUT;
}

sub year_edge_register {
	my $dataset="patent";
	#my $progress=new Term::ProgressBar::Simple($lines{$dataset});
	
	my %yearly_min_id;
	my %yearly_max_id;
	
	# ============ load year-monotonity.txt table ============
	
	my @year_monotonity=split/\n/, `cat year-monotonity.txt`;
	
	for my $line (@year_monotonity) {
		my @line=split/ /, $line;
		my $year=shift @line;
		
		for my $i (0..$#line/2) {
			my $min=$line[2*$i];
			my $max=$line[2*$i+1];
			
			my ($prefix, $id)=id_prefix($min);
			$yearly_min_id{$year}->{$prefix}=$id;
			
			($prefix, $id)=id_prefix($max);
			$yearly_max_id{$year}->{$prefix}=$id;
			
			if (exists $yearly_max_id{$year-1}->{$prefix} && $yearly_max_id{$year-1}->{$prefix} > $yearly_min_id{$year}->{$prefix}) {
			#	print "$year $prefix $yearly_max_id{$year-1}->{$prefix} > $yearly_min_id{$year}->{$prefix}\n";
				$yearly_min_id{$year}->{$prefix}=$yearly_max_id{$year-1}->{$prefix}+1;
			}
		}
	}
	
	my %yearly_id_min;
	for my $year (keys %yearly_min_id) {
		for my $prefix (keys %{$yearly_min_id{$year}}) {
			my $id=$yearly_min_id{$year}->{$prefix};
			$yearly_id_min{$prefix}->{$id}=$year;
		}
	}
	
	# ============ load exceptions from ID - title record list ============
	
	my $progress=new Term::ProgressBar::Simple($lines{$dataset});
	my %exceptions;
	
	open IN, "<../../topinav/$dataset-id-title.txt";
	while (<IN>) {
		chomp;
		
		# osszes tobbi
		my ($id_prefix, $date, $title)=split/\t/, $_;
		if (!$id_prefix || !$date || !$title) { next; }
		
		my ($prefix, $id)=id_prefix($id_prefix);
		my $year=substr($date, 0, 4);
		
		if (exists $yearly_min_id{$year}) {
			if ($id < $yearly_min_id{$year}->{$prefix}) {
				$exceptions{$id_prefix}=$year;
			}
		}

		$progress++;
	}
	close IN;
	
	print "exceptions: ".(scalar keys %exceptions)."\n";
	exit;
	
	# ============ add year field to edge list ============
	
	my $progress_2=new Term::ProgressBar::Simple(108993629);
	
	open IN, "zcat ../../../work/17-haromszogek/data/patent_edges.gz|";
	open OUT, ">patent_edges.txt";
	while (<IN>) {
		chomp;
		
		my ($from, $to)=split/\t/, $_;
		
		my ($prefix_a, $id_a)=id_prefix($from);
		my ($prefix_b, $id_b)=id_prefix($to);
		
		my $year_a=select_year_by_id($id_a, $yearly_id_min{$prefix_a});
		my $year_b=select_year_by_id($id_b, $yearly_id_min{$prefix_b});
		
		if (exists $yearly_min_id{$year_a} && exists $yearly_min_id{$year_b}) {
			# kulonben nincsen a kijelolt intervallumban az el valamelyik vegpontja
			print OUT "$from $to ";
			if (exists $exceptions{$from}) {
				print OUT "$exceptions{$from}\n";
			} else {
				print OUT "$year_a\n";
			}
		}

		$progress_2++;
	}
	close IN;
	close OUT;
}

sub select_year_by_id {
	my ($id, $yearly_id_min)=@_;
	
	# szukseg eseten gyorsabb: binaris kereses
	
	my $elozo_year=0;
	for my $min_id (sort { $a <=> $b } keys %$yearly_id_min) {
		my $year=$yearly_id_min->{$min_id};
		
		if ($min_id > $id) { last; }
		$elozo_year=$year;
	}
	
	return $elozo_year;
}

sub year_monotonity {
	my $dataset="patent";
	my $progress=new Term::ProgressBar::Simple($lines{$dataset});
	
	my %yearly_min_id;
	my %yearly_max_id;
	
	open IN, "<../../topinav/$dataset-id-title.txt";
	while (<IN>) {
		chomp;
		
		# osszes tobbi
		my ($id_prefix, $date, $title)=split/\t/, $_;
		if (!$id_prefix || !$date || !$title) { next; }
		
		my ($prefix, $id)=id_prefix($id_prefix);

		my $year=substr($date, 0, 4);
		
		if (!exists $yearly_min_id{$year}->{$prefix}) {
			$yearly_min_id{$year}->{$prefix}=$id;
			$yearly_max_id{$year}->{$prefix}=$id;
		}
		
		if ($id < $yearly_min_id{$year}->{$prefix}) { $yearly_min_id{$year}->{$prefix}=$id; }
		if ($id > $yearly_max_id{$year}->{$prefix}) { $yearly_max_id{$year}->{$prefix}=$id; }

		$progress++;
	}
	close IN;

	open OUT, ">year-monotonity.txt";
	for my $year (sort { $a <=> $b } keys %yearly_min_id) {
		print OUT "$year ";
		for my $prefix (sort keys %{$yearly_min_id{$year}}) {
			#print OUT "(prefix:$prefix) (min:$yearly_min_id{$year}->{$prefix}) (max:$yearly_max_id{$year}->{$prefix}) ";
			print OUT "$prefix$yearly_min_id{$year}->{$prefix} $prefix$yearly_max_id{$year}->{$prefix} ";
		}
		print OUT "\n";
	}
	close OUT;
}

sub filter_records_by_words {
	my ($pos, $neg)=@_;
	
	my %pos;
	my %neg;
	
	map { $pos{$_}="" } @$pos;
	map { $neg{$_}="" } @$neg;
	
	my $dataset="patent";
	
	my $progress=new Term::ProgressBar::Simple($lines{$dataset});
	
	open IN, "<../../topinav/$dataset-id-title.txt";
	open OUT, ">temp.txt";
	while (<IN>) {
		chomp;
		
		# osszes tobbi
		my ($id, $date, $title)=split/\tmy_intersection/, $_;
		if (!$id || !$date || !$title) { next; }
		
		my $words=string_to_words($title);
		my $stat=0;
		
		for my $word (@$words) {
			if (exists $pos{$word} && exists $neg{$word}) {
				$stat=3;
			} elsif (exists $pos{$word}) {
				$stat=1;
			} elsif (exists $neg{$word}) {
				$stat=2;
			}
		}
		
		if ($stat > 0) {
			print OUT "$id $stat\n";
		}
		
		#if ($i++ > 1000) { last; }
		$progress++;
	}
	close IN;
	close OUT;
}

sub filter_words_by_xywin {
	my ($x1, $x2, $y1, $y2)=@_;
	
	my @words;
	
	open IN, "<../diagrams-big/frequency/patent/wordtime-words-all.txt";
	while (<IN>) {
		chomp;
		
		my @line=split/ /, $_;
		my $word=shift @line;
		
		my @eleje=@line[0..4];
		my @vege=@line[$#line-4..$#line];
		
		my $eleje_sum=my_sum(@eleje);
		my $vege_sum=my_sum(@vege);
		
		my $x=$eleje_sum;
		my $y=$vege_sum-$eleje_sum;
		
		if ($x1 <= $x && $x <= $x2 && $y1 <= $y && $y <= $y2) {
			push @words, "$word $x $y";
		}
	}
	close IN;
	
	print join " ", map { / /; $` } sort @words;

	open OUT, ">temp.txt";
	print OUT join "\n", sort @words;
	close OUT;
}

sub wordtime_numbering {
	my $dir="../diagrams-big/frequency/so";
	my @words=split/\n/, `cut -f1 -d" " $dir/wordtime-words.txt | sort`;
	open OUT, ">$dir/wordtime-num.txt";
	for my $i (0..$#words) {
		print OUT ($i+1)." $words[$i]\n";
	}
	close OUT;
}


sub unify_components {
	my $basedir="../diagrams-big/random";
	my $dataset="so";
	
	my @ls=sort split/\n/, `ls $basedir/$dataset/components-*.txt`;
	
	#print Dumper \@ls;
	
	my @pos;
	my @neg;
	my $i=1;
	
	for my $ls (@ls) {
		my @file=split/\n/, `cat $ls`;
		
		my $pos_i=1;
		my $neg_i=2;
		
#		if (($i == 1) || ($i == 2)) {
#			$pos_i=2;
#			$neg_i=1;
#		}
		
		my @this_pos=split/ /, $file[$pos_i];
		my @this_neg=split/ /, $file[$neg_i];
		my $pos=shift @this_pos;
		my $neg=shift @this_neg;
		
		$pos/=200;
		$neg/=200;
		
		print "$i $pos $neg\n";
		$i++;
		
		@pos=(@pos, @this_pos);
		@neg=(@neg, @this_neg);
	}
	
	open OUT, ">$basedir/$dataset/components.txt";
	print OUT scalar @pos;
	print OUT " ";
	print OUT join " ", sort @pos;
	print OUT "\n";

	print OUT scalar @neg;
	print OUT " ";
	print OUT join " ", sort @neg;
	print OUT "\n";
	close OUT;
}

sub nytimes_stat {
	my %histo;
	
	#my $dataset="patent";
	my $dataset="so";
	#my $dataset="nyt";
	#my $dataset="wos";
	#my $dataset="aps";
	
	my $i=1;
	
	my $progress=new Term::ProgressBar::Simple($lines{$dataset});
	
	open IN, "<../../topinav/$dataset-id-title.txt";
	#open IN, "</home/adam/work/11-node-weights/archive/aps/aps_doi_year_title.txt";
	while (<IN>) {
		chomp;
		#my @row=split/ /, $_;
		my @row=split/\t/, $_;
		
		my $id=shift @row;
		my $date=shift @row;
		my $title=join " ", @row;
		#my ($id, $date, $title)=split/\t/, $_;
		
		my $my_date=substr($date, 0, 7);
		$histo{$my_date}++;
		#$histo{$date}++;
		$progress++;
		
		#if ($i++ > 1000) { last; }
	}
	close IN;
	
	open OUT, ">../diagrams-big/frequency/$dataset/record-count-orig.txt";
	for my $date (sort { $a cmp $b } keys %histo) {
		#print "$date $histo{$date}\n";
		print OUT "$date $histo{$date}\n";
	}
	close OUT;
}

sub show_min_limit {
	my @records_count=split/\n/, `cat diagrams-big/patent/record-count.txt`;
	@records_count=map { / /; $' } @records_count;

	my @min_limit=map { int($_ * 0.001) } @records_count;

	print join "\n", @min_limit;
}

sub show_word_maxes {
	my %word_max;

	my @lines=split/\n/, `cat diagrams-big/patent/wordtime-words.n.txt`;
	for my $line (@lines) {
		my @line=split/ /, $line;
		my $word=shift @line;
		
		$word_max{$word}=max(@line);
	}

	my $i=1;
	print join "\n", 
		map { ($i++)." $_ $word_max{$_}" } 
		sort { $word_max{$b} <=> $word_max{$a} }
		keys %word_max;
}

sub generate_word_histories {
	#my $dataset="patent";
	#my $dataset="nyt";
	#my $dataset="so";
	my $dataset="wos";
	#my $dataset="aps";
	#my $dataset="zeit";
	print STDERR "$dataset\n";
	
	my $maindir="../diagrams-big/frequency";

	my %lines=(
		"so" => 11203031,
		"patent" => 4992224,
		"nyt" => 123761,
		"wos" => 16310187,
		"zeit" => 891431,
		"aps" => 463347
	);
	# === get min_limit ===

	my %records_count;
	my @records_count=split/\n/, `cat $maindir/$dataset/record-count.txt`;
	map { / /; $records_count{$`}=$' } @records_count;

	my %min_limit;
	map { $min_limit{$_}=int(0.001 * $records_count{$_}) } keys %records_count;

	# === stopwords ===
	
	my %stopwords;
	my @stopwords=split/\n/, `cat ../../topinav/stopwords-en.txt`;
	#my @stopwords=split/\n/, `cat ../../topinav/stopwords-de.txt`;
	map { $stopwords{$_}="" } @stopwords;
	
	# === load %word_year_count ===
	
	my %word_year_count;
	my $i=1;
	
	my $progress=new Term::ProgressBar::Simple($lines{$dataset});
	
	#print Dumper \%records_count;

	#open IN, "</home/adam/work/11-node-weights/archive/aps/aps_doi_year_title.txt";
	open IN, "<../../topinav/$dataset-id-title.txt";
	while (<IN>) {
		chomp;
		
		# APS preprocess
		#my @row=split/ /, $_;
		#my $id=shift @row;
		#my $date=shift @row;
		#my $title=join " ", @row;

		# osszes tobbi
		my ($id, $date, $title)=split/\t/, $_;
		
		if (!$id || !$date || !$title) { next; }
		
		$date=substr($date, 0, 4);
		#print STDERR "$date ";
		#my $year_month=substr($date, 0, 7);
		#$date="$year_month-01";
		my $words=string_to_words($title);
		
		#if ($year >= 1990) {
		if (exists $records_count{$date}) {
			map { $word_year_count{$_}->{$date}++ }
				grep { !exists $stopwords{$_} }
				@$words;
		}
		
		#if ($i++ > 1000) { last; }
		$progress++;
	}
	close IN;
	
	# === save %word_year_count ===
	my $j=0;
	
	open OUT, ">$maindir/$dataset/wordtime-words.txt";
	for my $word (keys %word_year_count) {
		my %year_vals=%{$word_year_count{$word}};
		my @year_vals;
		my $save=0;
		
		for my $year (sort keys %min_limit) {
		#for my $year (1990..2011) {
			if (exists $year_vals{$year}) {
				push @year_vals, $year_vals{$year};
				if ($year_vals{$year} >= $min_limit{$year}) {
					$save=1;
				}
			} else {
				push @year_vals, 0;
			}
		}
		
		if ($save == 1) {
			print OUT "$word ".(join " ", @year_vals)."\n";
			$j++;
		}
	}
	close OUT;
	
	print "$j\n";
}

sub string_to_words {
	my $string=shift;
	
	$string=~s/\&[a-z]+\;/ /g;
	
	# wikipedia regexp - : elotti namespace, . utani extension kiszurese
	#$string=~s/^\s*\S+?://g;
	#$string=~s/\.\S+\s*$//g;
	
	my @szavak=$string=~/[\-a-zA-ZáéíóöőúüűÁÉÍÓÖŐÚÜŰ']+/g;
	@szavak=map { lc $_ } @szavak;
	return \@szavak;
}

# =========== functions ===========

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

sub id_prefix {
	my $prefixed_num=shift;
	
	my $prefix="";
	my $retnum=$prefixed_num;
	if ($prefixed_num =~ /^([A-Z]+)/) {
		$prefix=$1;
		$retnum=$';
	}
	
	return ($prefix, $retnum);
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
