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

my $VERBOSE = 0;

my $SUMMARY_HTML = $config::HTML_PATH . "/summary.html";
my $PNG_DIR = $config::PNG_PATH;

my @summary = (
	{
		index => "Japan information",
		htmlf => "summary_japan.html",
		params => [		
			"<H1>JAPAN BASIC INFORMATION</H1>",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_Japan_[0-9]{4}_rl_avr",
			"[0-9]{2}_jhccse_NEW_CASES_ERN_DAY_Japan_03_01",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_Japan_[0-9]{4}_rl_avr",
			#"[0-9]{2}_jhccse_NEW_CASES_ERN_DAY_Japan[_0-9]+ip_[0-9]+_lp_[0-9]+_rl_avr_[0-9]+",
			#"[0-9]{2}_jhccse_NEW_CASES_ERN_DAY_Japan_2m[_0-9]+ip_[0-9]+_lp_[0-9]+_rl_avr_[0-9]+",

			"docomoPEサマリ主要地域avrrl",
			"docomoPE東京_ALLrlavr__maxval",

			"<H1>NEW CASES/DEATHS by REAGION</H1>",
			"[0-9]{2}_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_",
			"[0-9]{2}_tko_NEW_CASES_COUNT_DAY_Japan_01_10_1m_rl_avr",
			"[0-9]{2}_tko_NEW_CASES_COUNT_POP_Japan_TOP20_rl_avr_",
			"[0-9]{2}_tko_NEW_CASES_COUNT_POP_Japan_01_10_1m_rl_avr_",

			"[0-9]{2}_tko_NEW_DEATHS_COUNT_DAY_Japan_TOP20_rl_avr_",
			"[0-9]{2}_tko_NEW_DEATHS_COUNT_DAY_Japan_01_10_1m_rl_avr",
			"[0-9]{2}_tko_NEW_DEATHS_COUNT_POP_Japan_TOP20_rl_avr_",
			"[0-9]{2}_tko_NEW_DEATHS_COUNT_POP_Japan_01_10_1m_rl_avr_",


			"<H1>TOKYO </H1>",
			"nonetky_pr_avr[1-9]",
			#"nonetky_st_avr[1-9]",
			"nonetky_st_avr0",
			#"[0-9]{2}_tko_NEW_CASES_COUNT_DAY_Tokyo_.* rl_avr_[0-9]",
			#"[0-9]{2}_tko_NEW_DEATHS_COUNT_DAY_Tokyo_.* rl_avr_[0-9]",
			"[0-9]{2}_tko_NEW_CASES_COUNT_DAY_Tokyo_",
			"[0-9]{2}_tko_NEW_DEATHS_COUNT_DAY_Tokyo_",
			"[0-9]{2}_tkoage_NEW_CASES_COUNT_DAY_Tokyo_Age_ruiseki02_rl_avr_",
			"[0-9]{2}_tkoage_NEW_CASES_COUNT_POP_Tokyo_Age_ruiseki02_rl_avr_",
			"[0-9]{2}_tkoage_NEW_CASES_COUNT_DAY_Tokyo_Age_rl_avr_",
			"[0-9]{2}_tko_NEW_CASES_ERN_DAY_Tokyo_from[_0-9]+ip_[0-9]+_lp_[0-9]+_rl_avr_",
			"[0-9]{2}_tko_NEW_CASES_ERN_DAY_Tokyo_2m_ip_[0-9]+_lp_[0-9]+_rl_avr_",

			"[0-9]{2}_tkoage_NEW_CASES_COUNT_DAY_Tokyo_Age_ruiseki03_Percent_rl_avr_",
			"[0-9]{2}_tkoage_NEW_CASES_COUNT_POP_Tokyo_Age_ruiseki03_Percent_rl_avr_",

			"<H1>TOKYO REAGION</H1>",
			"[0-9]{2}_tkoku_NEW_CASES_COUNT_DAY_Tokyo_TOP20_rl_avr_",
			"[0-9]{2}_tkoku_NEW_CASES_COUNT_DAY_Tokyo_TOP01_10_2m",
			"[0-9]{2}_tkoku_NEW_CASES_COUNT_DAY_Tokyo_TOP11_20_2m",
			"[0-9]{2}_tkoku_NEW_CASES_COUNT_POP_Tokyo_TOP20_rl_avr_",
			"[0-9]{2}_tkoku_NEW_CASES_COUNT_POP_Tokyo_TOP01_10_2m",

			"<H1>TOKYO OTHER</H1>",
			"[0-9]{2}_tkoku_NEW_CASES_COUNT_DAY_Tokyo_TOP20_rl_avr_",
			"[0-9]{2}_tkoku_NEW_CASES_COUNT_DAY_Tokyo_TOP20_ruiseki_rl_avr_",
			"[0-9]{2}_tkoku_NEW_CASES_COUNT_DAY_Tokyo_TOP20_ruiseki_rl_avr_",
			"[0-9]{2}_tkoage_NEW_CASES_COUNT_DAY_Tokyo_Age_ruiseki02_rl_avr_7",
			"[0-9]{2}_tkoage_NEW_CASES_COUNT_DAY_Tokyo_Age_rl_avr_",
			"[0-9]{2}_tkoage_NEW_CASES_COUNT_POP_Tokyo_Age_rl_avr_",
		],
	},
	{
		index => "World Wilde information",
		htmlf => "summary_ww01.html",
		params => [		
			"<H1>Johns Hopkins CCSE World wide</H1>",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_all_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_all_rl_avr_",

			"<H1>Europe</H1>",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_Europe_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_Europe_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_Europe_2month_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_Europe_2month_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_ERN_DAY_Forcus_area_01_1month_ip_",
 
			"<H1>TOP 1-10 NEW CASES from 03/01</H1>",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_01_05_from_0301_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_06_10_from_0301_rl_avr_",

			"<H1>TOP 1-10 NEW DEATHS from 03/01</H1>",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_01_05_from_0301_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_06_10_from_0301_rl_avr_",

			"<H1>TOP 11-40 NEW CASES from 03/01</H1>",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_11_20_from_0301_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_21_30_from_0301_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_31_40_from_0301_rl_avr_",

			"<H1>NEW CASES 2 months</H1>",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_2month_01_05_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_2month_06_10_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_2month_11_20_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_2month_21_30_rl_avr_",

			"<H1>NEW DEATHS 2 months</H1>",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_2month_01_05_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_2month_06_10_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_2month_11_20_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_2month_21_30_rl_avr_",

			"<H1>Forcusing area</H1>",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_ASIA_0301_rl_avr",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_ASIA_0301_rl_avr",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_DAY_Sweden_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_DAY_Sweden_rl_avr_",
		],
	},
	{
		index => "World Wilde POP information",
		htmlf => "summary_ww02.html",
		params => [		
			"<H1>NEW CASES/DEATHS </H1>",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_all_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_POP_all_rl_avr_",

			"<H1>NEW CASES from 03/01</H1>",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_01_05_from_0301_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_06_10_from_0301_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_11_20_from_0301_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_21_30_from_0301_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_31_40_from_0301_rl_avr_",


			"<H1>NEW CASES 2months</H1>",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_2month_01_05_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_2month_06_10_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_2month_11_20_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_2month_21_30_rl_avr_",
			"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_2month_31_40_rl_avr_",
			#"[0-9]{2}_jhccse_NEW_CASES_COUNT_POP_2month_41_50_rl_avr_",

			"<H1>NEW DEATHS 2months</H1>",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_POP_2month_01_05_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_POP_2month_06_10_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_POP_2month_11_20_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_POP_2month_21_30_rl_avr_",
			"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_POP_2month_31_40_rl_avr_",
			#"[0-9]{2}_jhccse_NEW_DEATHS_COUNT_POP_2month_41_50_rl_avr_",
		],
	},
	{
		index => "United State information",
		htmlf => "summary_US01.html",
		params => [		
			"<H1>NEW CASES/DEATHS </H1>",
			"[0-9]{2}_usast_NEW_CASES_COUNT_DAY_TOP_10_rl_avr_",
			"[0-9]{2}_usast_NEW_DEATHS_COUNT_DAY_TOP_10_rl_avr_",

			"<H1>NEW CASES 2months</H1>",
			"[0-9]{2}_usast_NEW_CASES_COUNT_DAY_TOP_10_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_CASES_COUNT_DAY_TOP_11_20_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_CASES_COUNT_DAY_TOP_21_30_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_CASES_COUNT_DAY_TOP_41_50_2month_rl_avr_",

			"<H1>NEW DEATHS 2months</H1>",
			"[0-9]{2}_usast_NEW_DEATHS_COUNT_DAY_TOP_10_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_DEATHS_COUNT_DAY_TOP_11_20_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_DEATHS_COUNT_DAY_TOP_21_30_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_DEATHS_COUNT_DAY_TOP_41_50_2month_rl_avr_",

			"<H1>NEW CASES/DEATHS POP </H1>",
			"[0-9]{2}_usast_NEW_CASES_COUNT_POP_TOP_10_rl_avr_",
			"[0-9]{2}_usast_NEW_DEATHS_COUNT_POP_TOP_10_rl_avr_",

			"<H1>NEW CASES POP </H1>",
			"[0-9]{2}_usast_NEW_CASES_COUNT_POP_TOP_10_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_CASES_COUNT_POP_TOP_11_20_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_CASES_COUNT_POP_TOP_21_30_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_CASES_COUNT_POP_TOP_41_50_2month_rl_avr_",

			"<H1>NEW DEATHS POP </H1>",
			"[0-9]{2}_usast_NEW_DEATHS_COUNT_POP_TOP_10_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_DEATHS_COUNT_POP_TOP_11_20_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_DEATHS_COUNT_POP_TOP_21_30_2month_rl_avr_",
			"[0-9]{2}_usast_NEW_DEATHS_COUNT_POP_TOP_41_50_2month_rl_avr_",
		],
	},
	{
		index => "United State cities information",
		htmlf => "summary_US02.html",
		params => [		
			"<H1>NEW CASES/DEATHS </H1>",
			"[0-9]{2}_usa_NEW_CASES_COUNT_DAY_TOP_10_rl_avr_",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_DAY_TOP_10_rl_avr_",

			"<H1>NEW CASES 2months</H1>",
			"[0-9]{2}_usa_NEW_CASES_COUNT_DAY_TOP_10_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_CASES_COUNT_DAY_TOP_11_20_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_CASES_COUNT_DAY_TOP_21_30_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_CASES_COUNT_DAY_TOP_31_40_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_CASES_COUNT_DAY_TOP_41_50_2month_rl_avr_",


			"<H1>NEW DEATHS 2months</H1>",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_DAY_TOP_10_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_DAY_TOP_11_20_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_DAY_TOP_21_30_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_DAY_TOP_31_40_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_DAY_TOP_41_50_2month_rl_avr_",

			"<H1>NEW CASES/DEATHS POP </H1>",
			"[0-9]{2}_usa_NEW_CASES_COUNT_POP_TOP_10_rl_avr_",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_POP_TOP_10_rl_avr_",

			"<H1>NEW CASES 2months POP</H1>",
			"[0-9]{2}_usa_NEW_CASES_COUNT_POP_TOP_10_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_CASES_COUNT_POP_TOP_11_20_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_CASES_COUNT_POP_TOP_21_30_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_CASES_COUNT_POP_TOP_31_40_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_CASES_COUNT_POP_TOP_41_50_2month_rl_avr_",


			"<H1>NEW DEATHS 2months POP</H1>",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_POP_TOP_10_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_POP_TOP_11_20_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_POP_TOP_21_30_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_POP_TOP_31_40_2month_rl_avr_",
			"[0-9]{2}_usa_NEW_DEATHS_COUNT_POP_TOP_41_50_2month_rl_avr_",
		],
	}
);


#foreach my $ss (@summary){
#	print join(",", $ss->{index}, $ss->{htmlf}, @{$ss->{params}}) . "\n";
#}
#exit;

my @PNG_FILES = ();
opendir my $DIRH, $config::PNG_PATH || die "Cannot open $config::PNG_PATH";
while(my $file = readdir($DIRH)){
	if($file =~ /\.png$/){
		my $png_file = $file;
		push(@PNG_FILES, $png_file);
		#dp::dp $png_file . "\n" ;
	}
}
closedir($DIRH);


if($#PNG_FILES < 0){
	dp::dp "ERROR no data  in the list\n";
	exit 1;
}

my $last_ctime = time;

foreach my $ss (@summary){
	my @SUMMARY_PNG = ();
	dp::dp "\n" . "-" x 20 . "\n" if($VERBOSE);
	dp::dp join(",", $ss->{index}, $ss->{htmlf}). "\n" if($VERBOSE);
	foreach my $target (@{$ss->{params}}){
		next if(! $target);
		if($target =~ /\</){
			push(@SUMMARY_PNG, $target);
			next;
		}
		my $skn = csvlib::search_key_p($target, \@PNG_FILES);
		if($skn && $skn > 0){
			my $png = $PNG_FILES[$skn-1];
			push(@SUMMARY_PNG, $png);
			#dp::dp $png . "\n";
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
				$atime,$mtime,$ctime,$blksize,$blocks) = stat("$config::PNG_PATH/$png");
			$last_ctime = $ctime if($ctime > $last_ctime);
		}
		else {
			dp::dp "### Not found " . $target . "\n";
			push(@SUMMARY_PNG, "<h2>not found $target</h2><hr>");

		}
	}

	if($#SUMMARY_PNG < 0){
		dp::dp "Error no png file muched\n";
		next;
	}

	#
	my $IMG_PATH = $config::PNG_REL_PATH;
	my $class = $config::CLASS;

	my $htmlf = $config::HTML_PATH . "/" . $ss->{htmlf};
	my $now = csvlib::ut2d4(time, "/") . " " . csvlib::ut2t(time, ":");

	dp::dp $htmlf . "\n" if($VERBOSE);

	open(HTML, "> $htmlf") || die "Cannot create file $htmlf";
	print HTML "<HTML>\n";
	print HTML "<HEAD>\n";
	print HTML "<TITLE> " . $ss->{index} . " ($now) </TITLE>\n";
	print HTML $config::CSS;
	print HTML "</HEAD>\n";
	print HTML "<BODY>\n";

	print HTML "" . csvlib::ut2dt($last_ctime) . "\n";
	my $img_path = $config::PNG_REL_PATH;
	foreach my $png (@SUMMARY_PNG){
		if($png =~ /\</){
			print HTML $png . "\n";
			#dp::dp "### " . $png . "\n";
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
}
