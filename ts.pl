#!/usr/bin/perl
#
#
#
use strict;
use warnings;

use config;
use csvlib;
use tkoage;

my $BASE_DIR = "$config::WIN_PATH/tokyo-ku/content";
my $fn = "$BASE_DIR/000292957.pdf.txt";
tkoage::pdf2data($fn);
exit;

foreach my $v( 3, 11, 14, 99, 101, 525, 377, 3475, 441111) {
	my $vv = csvlib::max_val($v, 4);
	print "$v -> $vv\n";
}
