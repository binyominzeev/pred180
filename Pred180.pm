package Pred180;

use Chart::Gnuplot;

use Term::ProgressBar::Simple;
use Data::Dumper;

sub new {
	my $class=shift;
	my %param=@_;
	
	my $self = {};
	bless $self, $class;
	
	map { $self->{$_}=$param{$_} } keys %param;

	%{$self->{datasets}->{patent}}=(
		"lines" => 4992224,
		"date_length" => 4,
		"lang" => "en"
	);
	
	%{$self->{datasets}->{so}}=(
		"lines" => 11203031,
		"date_length" => 7,
		"lang" => "en"
	);
	
	%{$self->{datasets}->{wos}}=(
		"lines" => 16310187,
		"date_length" => 4,
		"lang" => "en"
	);
	
	%{$self->{datasets}->{zeit}}=(
		"lines" => 891431,
		"date_length" => 4,
		"lang" => "de"
	);
	
	my %records_count;

	if (-e "$self->{dataset}/records-count.txt") {
		my @records_count=split/\n/, `cat $self->{dataset}/records-count.txt`;
		map { / /; $records_count{$`}=$' } @records_count;
	}
	
	$self->{records_count}=\%records_count;
	
	return $self;
}


sub load_histogram {
	my $self=shift;
	my %histo;
	my $i=1;
	
	%{$self->{histogram}}=();
	
	my $progress=new Term::ProgressBar::Simple($self->{datasets}->{$self->{dataset}}->{lines});
	my $date_length=$self->{datasets}->{$self->{dataset}}->{date_length};
	
	open IN, "<$self->{dataset}/records.txt";
	while (<IN>) {
		chomp;
		my @row=split/\t/, $_;
		
		my ($id, $date, $title)=@row;
		
		my $my_date=substr($date, 0, $date_length);
		$self->{histogram}->{$my_date}++;
		$progress++;
	}
	close IN;
}

sub save_histogram {
	my $self=shift;
	
	open OUT, ">$self->{dataset}/records-count.txt";
	for my $date (sort { $a cmp $b } keys %{$self->{histogram}}) {
		print OUT "$date $self->{histogram}->{$date}\n";
	}
	close OUT;
}

sub load_word_traffic {
	my $self=shift;
	
	# === get min_limit ===

	my %min_limit;
	map { $min_limit{$_}=int(0.001 * $records_count{$_}) } keys %{$self->{records_count}};

	# === stopwords ===
	
	my $lang=$self->{datasets}->{$self->{dataset}}->{lang};
	
	my %stopwords;
	my @stopwords=split/\n/, `cat stopwords-$lang.txt`;
	map { $stopwords{$_}="" } @stopwords;

	# === load %word_year_count ===
	
	my %word_year_count;
	my $i=1;
	
	my $progress=new Term::ProgressBar::Simple($self->{datasets}->{$self->{dataset}}->{lines});
	my $date_length=$self->{datasets}->{$self->{dataset}}->{date_length};
	
	open IN, "<$self->{dataset}/records.txt";
	while (<IN>) {
		chomp;
		
		my ($id, $date, $title)=split/\t/, $_;
		if (!$id || !$date || !$title) { next; }
		
		$date=substr($date, 0, $date_length);
		my $words=$self->string_to_words($title);
		
		if (exists $self->{records_count}->{$date}) {
			map { $word_year_count{$_}->{$date}++ }
				grep { !exists $stopwords{$_} }
				@$words;
		}

		$progress++;
	}
	close IN;
	
	$self->{min_limit}=\%min_limit;
	$self->{word_year_count}=\%word_year_count;
}

sub save_word_traffic {
	my $self=shift;
	
	# === save %word_year_count ===
	my $j=0;
	
	open OUT, ">$self->{dataset}/words-traffic.txt";
	for my $word (keys %{$self->{word_year_count}}) {
		#if ($word eq "net") {
			#print Dumper $word_year_count{$word};
		#}
		
		my %year_vals=%{$self->{word_year_count}->{$word}};
		my @year_vals;
		my $save=0;
		
		for my $year (sort keys %{$self->{min_limit}}) {
			if (exists $year_vals{$year}) {
				push @year_vals, $year_vals{$year};
				if ($year_vals{$year} >= $self->{min_limit}->{$year}) {
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
	
	return $j;
}

sub load_neighbors {
	my $self=shift;
	
	my %neighbor_count;
	my $date_length=$self->{datasets}->{$self->{dataset}}->{date_length};

	my %relevant_words;
	my @relevant_words=split/\n/, `cat $self->{dataset}/words-traffic.txt`;
	map { / /; $relevant_words{$`}="" } @relevant_words;
	
	my $progress=new Term::ProgressBar::Simple($self->{datasets}->{$self->{dataset}}->{lines});
	
	open IN, "<$self->{dataset}/records.txt";
	while (<IN>) {
		chomp;
		
		my ($id, $date, $title)=split/\t/, $_;
		if (!$id || !$date || !$title) { next; }

		my $year=substr($date, 0, $date_length);
		
		if (exists $self->{records_count}->{$year}) {
			my $words=$self->string_to_words($title);
			$words=$self->my_hash_array(@$words);
			
			my $relevant_words=$self->my_intersection($words, \%relevant_words);
			@relevant_words=keys %$relevant_words;
			
			for my $i (0..$#relevant_words) {
				for my $j ($i+1..$#relevant_words) {
					my ($word_a, $word_b)=sort ($relevant_words[$i], $relevant_words[$j]);
					$neighbor_count{$word_a}->{$word_b}->{$year}++;
					$neighbor_count{$word_b}->{$word_a}->{$year}++;
				}
			}
		}

		$progress++;
	}
	close IN;
	
	$self->{neighbor_count}=\%neighbor_count;
}

sub save_neighbors {
	my $self=shift;
	
	#print Dumper $self->{neighbor_count};
	
	for my $this_word (keys %{$self->{neighbor_count}}) {
		open OUT, ">$self->{dataset}/neighbors/$this_word.txt";
		delete $self->{neighbor_count}->{$this_word}->{$this_word};	# self-links
		for my $neighbor (sort keys %{$self->{neighbor_count}->{$this_word}}) {
			my $this_data=$self->{neighbor_count}->{$this_word}->{$neighbor};
			
			my @this_data;
			for my $year (sort keys %{$self->{records_count}}) {
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

sub string_to_words {
	my $self=shift;
	my $string=shift;
	
	$string=~s/\&[a-z]+\;/ /g;
	
	my @szavak=$string=~/[\-a-zA-ZáéíóöőúüűÁÉÍÓÖŐÚÜŰ']+/g;
	@szavak=map { lc $_ } @szavak;
	return \@szavak;
}

sub my_hash_array {
	my $self=shift;
	
	my %hash;
	map { $hash{$_}="" } @_;
	return \%hash;
}

sub my_intersection {
	my $self=shift;
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

1;
