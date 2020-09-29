#!/usr/bin/perl
#
#
#
#   SRC: https://mobaku.jp/covid-19/download/%E5%A2%97%E6%B8%9B%E7%8E%87%E4%B8%80%E8%A6%A7.csv
#
#
use strict;
use warnings;
use utf8;
use Encode 'decode';
use config;
use csvlib;

my $SRC_URL = "https://mobaku.jp/covid-19/download/%E5%A2%97%E6%B8%9B%E7%8E%87%E4%B8%80%E8%A6%A7.csv";
my $SRC_CSVF =  "$config::WIN_PATH/docomo/docomo.csv.txt";

my @PARAMS = (
{	
		src => "$SRC_CSVF",
		dst => "tky_pr",
		title => "DoCoMo-Data",
		ylabel => "比較",
		dt_start => "0000-00-00",
		plot => [
			{colm => '($2+$3)', axis => "x1y1", graph => "boxes fill",  item_title => "test total"},
			{colm => '2', axis => "x1y1", graph => "boxes fill",  item_title => "positive count"},
			{colm => '4', axis => "x1y2", graph => "lines linewidth 2",  item_title => "positive rate"},
		],
	},
);

#
#	Down Load CSV 
#
my $DOWN_LOAD = 0;


if($DOWN_LOAD){
	my $wget = "wget $SRC_URL -O $SRC_CSVF";
	dp::dp $wget ."\n";
	system($wget);
}

#
#	Lpad CSV File
#
my %AREA = ();
my %MESH = ();
my %KIND = ();
open(FD, $SRC_CSVF) || die "Cannot open $SRC_CSVF";

<FD>;
chop;
$_ = decode('Shift_JIS', $_);
my @LAVEL = split(/,/, $_);

my $ln = 0;
while(<FD>){
	last if($ln++ > 20);
	chop;
	$_ = decode('Shift_JIS', $_);
	my ($area, $mesh, $zouka, @data) = split(/,/, $_);
	$DOCOMO{$area}{$mesh}{$kind} = [@data];
	$AREA{$area}++;
	$MESH{$mesh}++;
	$KIND{$kind}++;

	dp::dp join(",", "前年同月比", @w) . "\n";
}
close(FD);
foreach my $area (sort keys %AREA){
	foreach my $mesh (sort keys %MESH){
		foreach my $kind (sort keys %KIND){
			dp::dp join(",",  $area, $mesh, $kind $DOCOMO{$area}{$mesh}{$kind}) . "\n";
		}
	}
}



