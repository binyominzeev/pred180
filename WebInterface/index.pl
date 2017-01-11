#!/usr/bin/perl
use strict;
use warnings;

use CGI;

# ===================== parameters =====================

my @dirs=qw/aps nyt patent so wos zeit/;
my @patterns=qw/0110-1001,0010-1101,0100-1011 1001-0110,1101-0010,1011-0100 01-10, 10-01,/;
my @pattern=split/,/, $patterns[0];

my $dir="/home/adam/git/wordtime/diagrams-big/frequency/so";

# ===================== initialize =====================

my @first_patterns=map { /,/; $` } @patterns;

my $q=CGI->new;
$q->import_names('GET');

if ($GET::neighbors) {
	open OUT, ">>parameters.txt";
	my $dataset=$dirs[$GET::dataset];
	print OUT "$dataset\t$GET::pattern\t$GET::neighbors\t$GET::radius\t$GET::intolerance\t$GET::outtolerance\n";
	close OUT;
}

my $last_row=`wc -l parameters.txt`;
$last_row=~/ /;
$last_row=$`;
$last_row=$last_row-1;

print "Content-type: text/html\n\n";

print `cat header.html`;

# ===================== parameters table =====================

print "<div id=\"container\">\n".
	"<form method=\"get\" action=\"?\">\n".
	"<div id=\"parameters\">".
	"<table id=\"parameters_table\" width=\"100%\" border=\"1\">\n".
	"<thead><tr>\n".
	"<th>Dataset</th>\n".
	"<th>Pattern (first)</th>\n".
	"<th>Neighbors</th>\n".
	"<th>Radius tolerance</th>\n".
	"<th>In-score tolerance</th>\n".
	"<th>Out-score tolerance</th>\n".
	"<th>True Positive</th>\n".
	"<th>True Negative</th>\n".
	"<th>False Positive</th>\n".
	"<th>False Negative</th>\n".
	"<th>Accuracy</th>\n".
	"<th>Sensitivity (TPR)</th>\n".
	"</tr></thead>\n<tbody>";

my $i=1;
my @parameters=split/\n/, `cat parameters.txt`;
for my $param_line (@parameters) {
	my @param_line=split/\t/, $param_line;
	print "<tr value=\"$i\" class=\"clickable\">";
	
	#$param_line[1]=$first_patterns[$param_line[1]];
	$param_line[1]="<img src=\"tile.pl?tile=$patterns[$param_line[1]]\" />";
	
	for my $param (@param_line) {
		print "<td>$param</td>\n";
	}
	
	my ($tp, $tn, $fp, $fn)=@param_line[-4..$#param_line];
	
	my $acc=show_num(($tp+$tn)/($tp+$tn+$fp+$fn));
	print "<td>$acc</td>\n";
	
	if ($tp + $fn == 0) {
		print "<td>0</td>\n";
	} else {
		my $tpr=show_num($tp/($tp+$fn));
		print "<td>$tpr</td>\n";
	}
	
	print "</tr>\n";
	$i++;
}

print "<tr>\n".
	"<td>".html_select_array("dataset", \@dirs)."</td>\n".
	"<td>".html_select_array("pattern", \@first_patterns)."</td>\n".
	"<td><input type=\"text\" name=\"neighbors\" size=\"5\"></td>\n".
	"<td><input type=\"text\" name=\"radius\" size=\"5\"></td>\n".
	"<td><input type=\"text\" name=\"intolerance\" size=\"8\"></td>\n".
	"<td><input type=\"text\" name=\"outtolerance\" size=\"8\"></td>\n".
	"<td>&nbsp;</td>\n".
	"<td>&nbsp;</td>\n".
	"<td>&nbsp;</td>\n".
	"<td>&nbsp;</td>\n".
	"<td>&nbsp;</td>\n".
	"<td>&nbsp;</td>\n".
	"</tr>\n".
	"</tbody></table></form></div><br />\n";

# ===================== records table =====================

print "<div id=\"records\">";
if ($GET::neighbors) {
	my $records_output=`./records.pl row=$last_row`;
	print $records_output;
} else {
	print "<table id=\"records_table\" width=\"100%\" border=\"1\">\n".
		"<thead><tr>\n".
		"<th>Word</th>\n".
		"<th>Diffseq</th>\n".
		"<th>Neighbor radius</th>\n".
		"<th>In-score</th>\n".
		"<th>In-class</th>\n".
		"<th>Out-score</th>\n".
		"<th>Out-class</th>\n".
		"</tr></thead>\n<tbody>\n".
		"</tbody></table>";
}

print "</div>\n";

print "<div id=\"show\">\n".
	"</div></div></body>\n</html>";

# ===================== functions =====================

sub html_select_array {
	my ($name, $array)=@_;
	
	my $out="<select name=\"$name\">";
	my $i=0;
	
	for my $val (@$array) {
		$out.="<option value=\"".($i++)."\">$val\n";
	}
	
	$out.="</select>";
	
	return $out;
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

sub show_num {
	my $val=shift;
	return sprintf("%.3f", $val);
}
