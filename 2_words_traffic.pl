#!/usr/bin/perl
use strict;
use warnings;

use Pred180;

my $pred=new Pred180(dataset => "so");

$pred->load_word_traffic();
$pred->save_word_traffic();


