#!/usr/bin/perl
#
#	サマリの HTMLファイルを生成する
#		./PNG フォルダーからPNGファイルを検索し、指定されたグラフをHTMLとしてまとめる。
#
#
package summary;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(summary);

use strict;
use warnings;
use Data::Dumper;
use config;
use csvlib;
use dp;

my $SUMMARY_HTML = $config::HTML_PATH . "/summary.html";
my $PNG_DIR = $config::PNG_PATH;

my @summary_list = (
	"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_Japan_[0-9]{4}_rl_avr",
	"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_Japan_[0-9]{4}_rl_avr",
	"[0-9]{2}_jhccse_NEW_CASES_ERN_DAY_Japan[_0-9]+ip_[0-9]+_lp_[0-9]+_rl_avr_[0-9]+",
	"docomoPEサマリ主要地域avrrl",
	"docomoPE東京_ALLrlavr__maxval",

	"[0-9]{2}_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_",
	"[0-9]{2}_tko_NEW_CASES_COUNT_POP_Japan_TOP20_rl_avr_",
	"[0-9]{2}_tko_NEW_DEATHS_COUNT_DAY_Japan_TOP20_rl_avr_",
	"[0-9]{2}_tko_NEW_DEATHS_COUNT_POP_Japan_TOP20_rl_avr_",

	"nonetky_pr_avr[1-9]",
	"nonetky_st_avr[1-9]",
	"[0-9]{2}_tko_NEW_CASES_COUNT_DAY_Tokyo_01_05_rl_avr_[0-9]+_rl_avr_",
	"[0-9]{2}_tko_NEW_DEATHS_COUNT_DAY_Tokyo_01_05_rl_avr_[0-9]+_rl_avr_",
	"[0-9]{2}_tkoage_NEW_CASES_COUNT_DAY_Tokyo_Age_ruiseki02_rl_avr_",
	"[0-9]{2}_tkoage_NEW_CASES_COUNT_DAY_Tokyo_Age_rl_avr_",
	"[0-9]{2}_tko_NEW_CASES_ERN_DAY_Tokyo_from[_0-9]+ip_[0-9]+_lp_[0-9]+_rl_avr_",

	"[0-9]{2}_tkoku_NEW_CASES_COUNT_DAY_Tokyo_TOP20_rl_avr_",
	"[0-9]{2}_tkok>u_NEW_CASES_COUNT_POP_Tokyo_TOP20_rl_avr_",

	"<h3>############# 参考 ############</h3>",
	"[0-9]{2}_tkoku_NEW_CASES_COUNT_DAY_Tokyo_TOP20_rl_avr_",
	"[0-9]{2}_tkoku_NEW_CASES_COUNT_DAY_Tokyo_TOP20_ruiseki_rl_avr_",
	"[0-9]{2}_tkoage_NEW_CASES_COUNT_DAY_Tokyo_Age_ruiseki02_rl_avr_7",
	"[0-9]{2}_tkoage_NEW_CASES_COUNT_DAY_Tokyo_Age_rl_avr_",
	"[0-9]{2}_tkoage_NEW_CASES_COUNT_POP_Tokyo_Age_rl_avr_",

#
);

my @PNG_FILES = ();
my @SUMMARY_PNG = ();
opendir my $DIRH, $config::PNG_PATH || die "Cannot open $config::PNG_PATH";
while(my $file = readdir($DIRH)){
	if($file =~ /\.png$/){
		my $png_file = $file;
		push(@PNG_FILES, $png_file);
		#dp::dp $png_file . "\n" ;
	}
}
closedir($DIRH);

foreach my $target (@summary_list){
	if($target =~ /\</){
		push(@SUMMARY_PNG, $target);
		next;
	}
	my $skn = csvlib::search_key_p($target, \@PNG_FILES);
	if($skn > 0){
		my $png = $PNG_FILES[$skn-1];
		push(@SUMMARY_PNG, $png);
		dp::dp $png . "\n";
	}
}

#######
#
#
my $IMG_PATH = $config::PNG_REL_PATH;
my $class = $config::CLASS;

my $now = csvlib::ut2d4(time, "/") . " " . csvlib::ut2t(time, ":");
open(HTML, "> $SUMMARY_HTML") || die "Cannot create file $SUMMARY_HTML";
print HTML "<HTML>\n";
print HTML "<HEAD>\n";
print HTML "<TITLE> Yet another COVID-19 data ($now) </TITLE>\n";
print HTML $config::CSS;
print HTML "</HEAD>\n";
print HTML "<BODY>\n";

my $img_path = $config::PNG_REL_PATH;
dp::dp "#### $img_path\n";
foreach my $png (@SUMMARY_PNG){
	if($png =~ /\</){
		print HTML $png . "\n";
		dp::dp "### " . $png . "\n";
		next;
	}
	my $csv = my $plot = $png;
	$csv =~ s/\.png/-plot.csv.txt/;
	$plot =~ s/\.png/-plot.txt/;
	print HTML "<img src=\"$IMG_PATH/$png\">\n";
	print HTML "<br>\n";
	print HTML "<hr>\n";
	print HTML "<TABLE>";

	print HTML "<span $class>";
	print HTML "REF <a href=\"$img_path/$csv\" target=\"blank\">$csv</a><br>\n"; 
	print HTML "REF <a href=\"$img_path/$plot\" target=\"blank\">$plot</a><br>\n"; 
	print HTML "</span>\n";
	print HTML "<br><hr>\n\n";
}
print HTML "</BODY>\n";
print HTML "</HTML>\n";
close(HTML);
