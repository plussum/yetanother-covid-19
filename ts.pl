#!/usr/bin/perl
#
#
#
use strict;
use warnings;

use csvlib;

foreach my $v( 3, 11, 14, 99, 101, 525, 377, 3475, 441111) {
	my $vv = csvlib::max_val($v, 4);
	print "$v -> $vv\n";
}
