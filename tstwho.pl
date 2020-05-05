#!/usr/bin/perl
#
#
#

use strict;
use warnings;

use who;


my @files = (
	"./COV/whodata/20200504-covid-19-sitrep-105.txt",
#	"./COV/whodata/20200501-covid-19-sitrep.txt",
#	"./COV/whodata/20200430-sitrep-101-covid-19.txt",
);

my $date = 20200501;			# format
my $txtd = "who$date.txt";

foreach my $txtf (@files){
	who::molding($txtf, $txtd, $date);
	print "#" x 20 . "\n";
}

exit(0)

