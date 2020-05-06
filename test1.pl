#!/usr/bin/perl


use strict;
use warnings;
use Data::Dumper;

use params;

my $std = {start_day => 0,  lank =>[0, 19] , exclusion => "Others", target => "", label_skip => 3, graph => "lines"} ;

my $join = {ext => "#KIND# all with US(#LD#) #SRC#", each %$std};

print Dumper $std;
print Dumper $join;

