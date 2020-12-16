#!/usr/bin/perl
#
#
#
use strict;
use warnings;
use confg.pm:

#my $dir = "/mnt/f/cov/plussum.github.io/PNG";
my $dir = $config::PNG_PATH;
if($#ARGV < 0){
	print "USAGE: $0 file_name\n";
	exit 1;
}
my $fn = $ARGV[0];

my $full = join("/", $dir, $fn);
print "[$fn][$full]\n";

if(! -f $full){
	print "Cannto find $full\n";
}
else {
	my $csvf = $full;
	$csvf =~ s/\.txt//;
	print $csvf . "\n";
	system("cp $full $csvf");
	system("ls -lt $dir | head -5");
}

