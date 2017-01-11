#!/usr/bin/perl
use strict;
use warnings;

use Pred180;

my $pred=new Pred180(dataset => "so");

$pred->load_neighbors();
$pred->save_neighbors();



