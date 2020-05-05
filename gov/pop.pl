#!/usr/bin/perl
#
#	WHO のデータ(pdf)をWHOからダウンロードして、CSVを生成する
#
use strict;
use warnings;

my $popf = "COV/pop.csv";

my %JHU_CN = ();
my %WHO_CN = ();
my %CNT_POP = ();
open(FD, $popf) || die "cannot open $popf\n";
<FD>;
while(<FD>){
	chop;
	
	my($jhu, $who, $un, $pn, @w) = split(",", $_);

	$JHU_CN{$jhu}++;
	$WHO_CN{$who}++;
	$CNT_POP{$un} = $pn;
	foreach my $sn (@w){
		$CNT_POP{$sn} = $pn;
	}
}
close(FD);

foreach my $c (sort keys %JHU_CN){
	if(defined $CNT_POP{$c}){
		#print "$c\t" . $CNT_POP{$c}, "\n";
	}
	else {
		print $c , "\n";
	}
}
foreach my $c (sort keys %WHO_CN){
	if(defined $CNT_POP{$c}){
		#print "$c\t" . $CNT_POP{$c}, "\n";
	}
	else {
		print $c , "\n";
	}
}
