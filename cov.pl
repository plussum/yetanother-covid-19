#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、CSVとグラフを生成する
#
#	beoutbreakprepared
#	https://github.com/beoutbreakprepared/nCoV2019
#
#
use strict;
use warnings;
use lib qw(../gsfh);

my $DEBUG = 0;
my $download = 0;

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$download = 1 if(/-DL/);
}

system("(cd ../COVID-19; git pull origin master)") if($download);
system("./ccse.pl");

my $gwflag = ($download) ? "-dl" : "";
system("./getwho.pl $gwflag");




