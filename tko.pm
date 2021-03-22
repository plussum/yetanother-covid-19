#!/usr/bin/perl
#
#	kaz-ogiwara / covid19
#	https://github.com/kaz-ogiwara/covid19
#
#
#
#

package tko;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(tko);

use strict;
use warnings;

use Data::Dumper;
use csvgpl;
use csvaggregate;
use csvlib;

#
#	Initial
#
my $WIN_PATH = $config::WIN_PATH;
my $CSV_PATH = $config::CSV_PATH;
my $DLM = $config::DLM;

my $TKO_PATH = "$WIN_PATH/tokyokeizai";

my $DEBUG = 1;


#
#	Parameter set
#
our $EXCLUSION = "";
my $MAIN_PREF = "東京,神奈川,埼玉,千葉,大阪,京都,兵庫,福岡,愛知,北海道";
my @jag_param = (
	{ext => "#KIND# Japan TOP20 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
#{ext => "EOD"},
	{ext => "#KIND# Japan TOP20 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines", avr_date => 7},
	{ext => "#KIND# Japan TOP20 2m (#LD#) #SRC#", start_day => -62,  lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "#KIND# Japan TOP20 2m (#LD#) #SRC#", start_day => -62,  lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines", avr_date => 7},

	{ext => "#KIND# Japan 2-10 4w (#LD#) #SRC#", start_day => -28,  lank =>[1, 9] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "#KIND# Japan 11-20 4w (#LD#) #SRC#", start_day => -28,  lank =>[10, 19] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "#KIND# Japan 2-10 4w (#LD#) #SRC#", start_day => -28,  lank =>[1, 9] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines", avr_date => 7},
	{ext => "#KIND# Japan 11-20 4w (#LD#) #SRC#", start_day => -28,  lank =>[10, 19] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines", avr_date => 7},

	{ext => "#KIND# 大阪、北海道 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 99] , exclusion => $EXCLUSION, target => "大阪,北海道", label_skip => 7, graph => "lines", avr_date => 7},
	{ext => "#KIND# 大阪、北海道 2m (#LD#) #SRC#", start_day => -62,  lank =>[0, 99] , exclusion => $EXCLUSION, target => "大阪,北海道", label_skip => 1, graph => "lines", avr_date => 7},

	{ext => "#KIND# 関西など (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[1, 99] , exclusion => $EXCLUSION, 
		target => "大阪,兵庫,京都,愛知,福岡", label_skip => 7, graph => "lines", avr_date => 7},
	{ext => "#KIND# 関西など 2m (#LD#) #SRC#", start_day => -62,  lank =>[1, 99] , exclusion => $EXCLUSION, 
		target => "大阪,兵庫,京都,愛知,福岡", label_skip => 1, graph => "lines", avr_date => 7},

	{ext => "#KIND# 一都三県 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => "東京,神奈川,千葉,埼玉", label_skip => 7, graph => "lines", avr_date => 7},
	{ext => "#KIND# 一都三県 2m (#LD#) #SRC#", start_day => -62,  lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => "東京,神奈川,千葉,埼玉", label_skip => 1, graph => "lines", avr_date => 7},

	{ext => "#KIND# Japan 01-05 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 4] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},

	{ext => "#KIND# Japan 01-05 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 4] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines", avr_date => 7},

	{ext => "#KIND# Tokyo 01-05 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 4] , exclusion => $EXCLUSION, 
		target => "東京", label_skip => 7, graph => "lines", avr_date => 7},

	{ext => "#KIND# Japan 01-10 (#LD#) #SRC#", start_day => "2020/05/20",  lank =>[0, 9] , exclusion => $EXCLUSION,
		 target => "", label_skip => 7, graph => "lines", avr_date => 7, additional_plot => 0.5},
	{ext => "#KIND# Japan 01-08 (#LD#) #SRC#", start_day => "2020/03/18",  lank =>[0, 7] , exclusion => $EXCLUSION,
		 target => "", label_skip => 7, graph => "lines", avr_date => 7, additional_plot => 0.5},
#	{ext => "#KIND# Japan 01-08 (#LD#) #SRC# ymax", start_day => "2020/03/18",  lank =>[0, 7] , exclusion => $EXCLUSION,
#		 target => "", label_skip => 7, graph => "lines", avr_date => 7, ymax => 2, additional_plot => 0.5},

	{ext => "#KIND# Japan 01-08 (#LD#) #SRC# 1m ymax", start_day => -31,  lank =>[0, 7] , exclusion => $EXCLUSION,
		 target => "", label_skip => 1, graph => "lines", ymax => 2, avr_date => 7, additional_plot => 0.5},
	{ext => "#KIND# Japan 01-08 (#LD#) #SRC# 1m", start_day => -31,  lank =>[0, 7] , exclusion => $EXCLUSION,
		 target => "", label_skip => 1, graph => "lines", additional_plot => 0.5},

	{ext => "#KIND# Japan 01-05 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 4] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
	{ext => "#KIND# Japan 06-10 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[5, 9] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
	{ext => "#KIND# Japan 11-15 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[10, 14] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
	{ext => "#KIND# Japan 16-20 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[15, 20] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
#	{ext => "#KIND# Japan 01-10 log (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 9] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines",
#		 logscale => "y", average_date => 7},

	{ext => "#KIND# Japan 01-10 1m (#LD#) #SRC#", start_day => -31,  lank =>[0, 9] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines",
			term_ysize => 300},
	{ext => "#KIND# Japan 01-10 1m (#LD#) #SRC#", start_day => -31,  lank =>[0, 9] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines",
			 avr_date => 7, term_ysize => 300},
	{ext => "#KIND# Japan 11-20 1m (#LD#) #SRC#", start_day => -31,  lank =>[10, 19] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines",
			 avr_date => 7, term_ysize => 300},

	{ext => "#KIND# Japan 01-05 2m (#LD#) #SRC#", start_day => -62,  lank =>[0, 4] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "#KIND# Japan 06-10 2m (#LD#) #SRC#", start_day => -62,  lank =>[5, 9] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "#KIND# Japan 11-15 2m (#LD#) #SRC#", start_day => -62,  lank =>[10, 14] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "#KIND# Japan 16-20 2m (#LD#) #SRC#", start_day => -62,  lank =>[15, 20] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},

	{ext => "#KIND# Japan 01-05 2m (#LD#) #SRC#", start_day => -62,  lank =>[0, 4] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines", avr_date => 7},
	{ext => "#KIND# Japan 06-10 2m (#LD#) #SRC#", start_day => -62,  lank =>[5, 9] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines", avr_date => 7},
	{ext => "#KIND# Japan 11-15 2m (#LD#) #SRC#", start_day => -62,  lank =>[10, 14] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines", avr_date => 7},
	{ext => "#KIND# Japan 16-20 2m (#LD#) #SRC#", start_day => -62,  lank =>[15, 20] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines", avr_date => 7},

	{ext => "#KIND# taget cities  (#LD#) #SRC# 02/01", start_day => "2020/03/12",  lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => $MAIN_PREF, label_skip => 7, graph => "lines"},
	{ext => "#KIND# taget cities  (#LD#) #SRC# 03/12", start_day => "2020/03/12",  lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => $MAIN_PREF, label_skip => 7, graph => "lines", avr_date => 7, term_ysize => 300},

	{ext => "#KIND# taget cities  (#LD#) #SRC# 2m", start_day => "-60",  lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => $MAIN_PREF, label_skip => 1, graph => "lines", avr_date => 7, term_ysize => 300},
	{ext => "#KIND# taget cities  (#LD#) #SRC# 2m", start_day => "-60",  lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => $MAIN_PREF, label_skip => 1, graph => "lines",  term_ysize => 300},

#	{ext => "#KIND# Fukuoka,Hokaido (#LD#) #SRC# 03/12", start_day => "2020/03/12",  lank =>[0, 99] , exclusion => $EXCLUSION, 
#		target => "福岡,北海道", label_skip => 7, graph => "lines", term_ysize => 300},
#	{ext => "#KIND# Fukuoka,Hokaido (#LD#) #SRC# 03/12", start_day => "2020/03/12",  lank =>[0, 99] , exclusion => $EXCLUSION, 
#		target => "福岡,北海道", label_skip => 7, graph => "lines", term_ysize => 300, avr_date => 7},
);

my $BASE_DIR = "$TKO_PATH/covid19/data";
our $transaction = "$BASE_DIR/prefectures.csv";
#our $transaction = "$CSV_PATH/gis-jag-japan.csv.txt",
#our $src_url = "https://dl.dropboxusercontent.com/s/6mztoeb6xf78g5w/COVID-19.csv";
our $src_url = "../tokyokeizai/prefecture.csv.txt";
our $PARAMS = {			# MODULE PARETER		$mep
    comment => "**** TOYO KEIZAI ONLINE ****",
    src => "TOYO KEIZAI ONLINE",
	src_url => $src_url,
	download_from => "https://toyokeizai.net/sp/visual/tko/covid19/csv/prefectures.csv",
    prefix => "tko_",
    src_file => {
		NC => $transaction,
		CC => $transaction,
		ND => $transaction,
		CD => $transaction,
    },
    base_dir => "",
	csv_aggr_mode => "", 	# "" or TOTAL

    new => \&new,
    aggregate => \&aggregate,
    download => \&download,
    copy => \&copy,


	AGGR_MODE => {DAY => 1, POP => 1},		# POP: 7 Days Total / POP
	#MODE => {NC => 1, ND => 1},

	COUNT => {			# FUNCTION PARAMETER	$funcp
		EXEC => "",
		graphp => [		# GPL PARAMETER			$gplp
				@jag_param, 
		],
		graphp_mode => {												# New version of graph pamaeter for each MODE
			NC => [
				@jag_param, 
			],
			CC => [
				{ext => "#KIND# Japan TOP20 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Japan 01-05 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 4] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Japan 06-10 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[5, 9] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Japan 11-15 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[10, 14] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Japan 16-20 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[15, 19] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Japan 21-30 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[20, 29] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Japan 31-40 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[30, 39] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Japan 40-50 (#LD#) #SRC#", start_day => "2020/03/12",  lank =>[40, 49] , exclusion => $EXCLUSION, target => "", label_skip => 7, graph => "lines"},
			],
		},
	},
	FT => {
		EXEC => "",
		average_date => 7,
		ymin => 10,
		graphp => [
			{ext => "#KIND# ALL Japan all FT (#LD#) #SRC#", start_day => 0,  lank =>[0, 20] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", 
				series => 1, average => 7, logscale => "y", term_ysize => 600, ft => 1},
		],
	},
	ERN => {
		EXEC => "",
        ip => 6, #$config::RT_IP,
		lp => 7, #$config::RT_LP,,
		average_date => 7,
		graphp => [	
			{ext => "#KIND# Tokyo from 3/12 #RT_TD#", start_day => "2020/03/12", lank =>[0, 99] , exclusion => $EXCLUSION, target => "東京", 
				label_skip => 7, graph => "lines", term_ysize => 300, ymax => 10},
			{ext => "#KIND# Tokyo from 3/12 #RT_TD# 2", start_day => "2020/03/12", lank =>[0, 99] , exclusion => $EXCLUSION, target => "東京", 
				label_skip => 7, graph => "lines", term_ysize => 300, ymax => ""},

			{ext => "#KIND# Tokyo 2m #RT_TD#", start_day => -61, lank =>[0, 99] , exclusion => $EXCLUSION, target => "東京", 
				label_skip => 2, graph => "lines", term_ysize => 300, ymax => ""},
			{ext => "#KIND# Tokyo 1m #RT_TD#", start_day => -31, lank =>[0, 99] , exclusion => $EXCLUSION, target => "東京", 
				label_skip => 2, graph => "lines", term_ysize => 300, ymax => ""},

			{ext => "#KIND# main pref from 3/12 #RT_TD#", start_day => "2020/03/12", lank =>[0, 99] , exclusion => $EXCLUSION, target => $MAIN_PREF, 
				label_skip => 7, graph => "lines", term_ysize => 300, ymax => 3},

			{ext => "#KIND# main pref 1m #RT_TD# ", start_day => -31, lank =>[0, 99] , exclusion => $EXCLUSION, target => $MAIN_PREF, 
				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 2.5},
			{ext => "#KIND# main pref 1m #RT_TD# ", start_day => -31, lank =>[0, 99] , exclusion => $EXCLUSION, target => $MAIN_PREF, 
				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 5},

			{ext => "#KIND# main pref 0312 #RT_TD#", start_day => "2020/03/12", lank =>[0, 99] , exclusion => $EXCLUSION, target => $MAIN_PREF, 
				label_skip => 7, graph => "lines", term_ysize => 300, ymax => 10},
			{ext => "#KIND# main pref 0401 #RT_TD#", start_day => "2020/04/01", lank =>[0, 99] , exclusion => $EXCLUSION, target => $MAIN_PREF, 
				label_skip => 7, graph => "lines", term_ysize => 300, ymax => 10},
			{ext => "#KIND# main pref 0401 Tokyo#RT_TD#", start_day => "2020/04/01", lank =>[0, 99] , exclusion => $EXCLUSION, target => $MAIN_PREF, 
				label_skip => 7, graph => "lines", term_ysize => 300, ymax => 10},

			{ext => "#KIND# Japan 0312 #RT_TD#", start_day => "2020/03/12", lank =>[0, 5] , exclusion => $EXCLUSION, taget => "",
				label_skip => 7, graph => "lines", term_ysize => 300, ymax => 10},

			{ext => "#KIND# TOP 5 2m #RT_TD#", start_day => -62, lank =>[0, 4] , exclusion => $EXCLUSION, target => "", 
				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 10},
			{ext => "#KIND# TOP10 2m #RT_TD#", start_day => -62, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 10},


#			{ext => "#KIND# Tokyo 0312 #RT_TD# 5,7", start_day => "2020/03/12", lank =>[0, 5] , exclusion => $EXCLUSION, target => "東京,大阪,神戸,北海道", 
#				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 10, ip => 5, lp => 7},
#			{ext => "#KIND# Tokyo 0312 #RT_TD# 5,8", start_day => "2020/03/12", lank =>[0, 5] , exclusion => $EXCLUSION, target => "東京,大阪,神戸,北海道", 
#				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 10, ip => 5, lp => 8},
#			{ext => "#KIND# Tokyo 0312 #RT_TD# 5,9", start_day => "2020/03/12", lank =>[0, 5] , exclusion => $EXCLUSION, target => "東京,大阪,神戸,北海道", 
#				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 10, ip => 5, lp => 9},
#
#			{ext => "#KIND# Tokyo 0312 #RT_TD# 4,8", start_day => "2020/03/12", lank =>[0, 5] , exclusion => $EXCLUSION, target => "東京,大阪,神戸,北海道", 
#				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 10, ip => 4, lp => 8},
#			{ext => "#KIND# Tokyo 0312 #RT_TD# 5,8", start_day => "2020/03/12", lank =>[0, 5] , exclusion => $EXCLUSION, target => "東京,大阪,神戸,北海道", 
#				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 10, ip => 5, lp => 8},
#			{ext => "#KIND# Tokyo 0312 #RT_TD# 6,8", start_day => "2020/03/12", lank =>[0, 5] , exclusion => $EXCLUSION, target => "東京,大阪,神戸,北海道", 
#				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 10, ip => 6, lp => 8},

		],
	},
	KV => {
		EXC => "Others",
		graphp => [
			{ext => "#KIND# from 03/18 (#LD#) #SRC#", start_day => "2020/03/18",  lank =>[0, 999], exclusion => $EXCLUSION, 
				target => $MAIN_PREF, label_skip => 7, graph => "lines"},
			{ext => "#KIND# from 4/1(#LD#) #SRC#", start_day => "2020/04/01",  lank =>[0, 999], exclusion => $EXCLUSION, 
				target => $MAIN_PREF, label_skip => 7, graph => "lines"},
			{ext => "#KIND# from 1m(#LD#) #SRC#", start_day => -31,  lank =>[0, 999], exclusion => $EXCLUSION, 
				target => $MAIN_PREF, label_skip => 1, graph => "lines"},

			{ext => "#KIND# from 03/18 Tokyo (#LD#) #SRC#", start_day => "2020/03/18",  lank =>[0, 999], exclusion => $EXCLUSION, 
				target => "東京", label_skip => 7, graph => "lines"},
			{ext => "#KIND# from 4/1(#LD#)  Tokyo#SRC#", start_day => "2020/04/01",  lank =>[0, 999], exclusion => $EXCLUSION, 
				target => "東京", label_skip => 7, graph => "lines"},
			{ext => "#KIND# from 1month(#LD#)  Tokyo#SRC#", start_day => -31,  lank =>[0, 999], exclusion => $EXCLUSION, 
				target => "東京", label_skip => 1, graph => "lines"},
#			{ext => "#KIND# from 03/12 log(#LD#) #SRC#", start_day => "2020/03/12",  lank =>[0, 999], exclusion => $EXCLUSION, 
#				target => "東京,大阪,神戸,北海道,神奈川,埼玉,福岡,千葉", label_skip => 3, graph => "lines", logscale => "y"},
		],
	},
};


#
#	For initial (first call from cov19.pl)
#
sub	new 
{
	#dp::dp "#### TKO ###\n";
	return $PARAMS;
}

#
#	Download data from the data source
#
sub	download
{
	my ($info_path) = @_;

#	system("(cd $TKO_PATH/covid19; git pull origin master)");
#	my $cmd = "(cd $BASE_DIR; pwd; ls; cp prefectures.csv ../../prefecture.csv.txt)";

	my $url = $info_path->{download_from};
	my $cmd = "wget $url -O $transaction";
	dp::dp $cmd . "\n";
	system($cmd);
}

#
#	Copy download data to Windows Path
#
sub	copy
{
	my ($info_path) = @_;

	system("cp $transaction $CSV_PATH/");
}

#
#	Aggregate J.A.G Japan  
#
sub	aggregate
{
	my ($fp) = @_;

	my $mode = $fp->{mode};
	my $aggr_mode = $fp->{aggr_mode};
	my $src_file = $fp->{src_file};
	my $report_csvf = $fp->{stage1_csvf};
	my $graph_html = $fp->{htmlf};
	my $csv_aggr_mode = csvlib::valdef($fp->{csv_aggr_mode}, "");

	dp::dp $transaction . "\n";
	my $agrp = {
		mode => $mode,
		input_file => $transaction,
		output_file => $fp->{stage1_csvf},
		delemiter => $fp->{dlm},
		exclude_keys => [],						# 動作未検証
		agr_total => 0,
		agr_count => 0,
		total_item_name => "",
	};

	return &tko_csv($agrp);		# 集計処理
	#system("more $aggregate");
}

sub	tko_csv
{
	my ($agp) = @_;

	my $src_file = $agp->{input_file};
	my $out_file = $agp->{output_file};

	#dp::dp "$src_file -> $out_file\n";
	my %DATES = ();
	my %PREFS = ();
	my %COUNT = ();
	my %TOTAL = ();

	open(FD, $src_file) || die "cannot open $src_file";
	<FD>;
	my @items = &csv($_);

	my $vn = ($agp->{mode} =~ /.C/) ? 0 : 5;	# 2020.08.24	 
	while(<FD>){
		my ($y, $m, $d, $pref, $prefe, @vals)  = &csv($_);
		#my $ymd = sprintf("%04d/%02d/%02d", $y, $m, $d);
		$y += 2000 if($y < 100);
		my $ymd = sprintf("%04d/%02d/%02d", $y, $m, $d);		# 2020/01/03 Y/M/D

		my $v = $vals[$vn];
		$v = 0 if(!$v || $v eq "-");
		#dp::dp "$vn:[$v]\n" if(!$v || $v =~ /[^0-9]/);

		$DATES{$ymd}++;
		$PREFS{$pref} = $v;
		$COUNT{$ymd}{$pref} += $v;
	}
	close(FD);

	#dp::dp "Tokyo: " . $PREFS{Tokyo} . "\n";
	my @PREF_ORDER = sort {$PREFS{$b} <=> $PREFS{$a}} keys %PREFS;
	my @DATE_ORDER = sort keys %DATES;

	open(CSV, "> $out_file") || die "cannto create $out_file\n";
	print CSV join($DLM, "# pref", "total", @DATE_ORDER) . "\n";
	my $RN = 0;
	foreach my $pref (@PREF_ORDER){
		my @data = ();
		my $lv = 0;
		my $tl = 0;
		for(my $i = 0; $i <= $#DATE_ORDER; $i++){
			my $ymd = $DATE_ORDER[$i];
			my $v = csvlib::valdef($COUNT{$ymd}{$pref}, 0);
			$v = 0 if(!$v);
			#dp::dp "$ymd: $v, $lv => " . ($v - $lv) . "\n";
			push(@data, $v - $lv);
			$tl += ($v - $lv);
			$lv= $v;
		}
		#dp::dp join(", ", $pref, $#DATE_ORDER, $lv, $DATE_ORDER[$#DATE_ORDER]) . "\n";
		print CSV join($DLM, $pref, $tl, @data) . "\n";
		$RN++;
	}
	close(CSV);
	#
	#	戻り値: カラム数、レコード数、最初の日付け、最後の日付
	#
	#return ($#date_list, $rn , $date_list[0], $date_list[$#date_list]) ;
	return ($#DATE_ORDER, $RN, $DATE_ORDER[0], $DATE_ORDER[$#DATE_ORDER]);
}

sub	csv
{
	my ($line) = @_;

	$line =~ s/"*[\r\n]+$//;
	$line =~ s/",/,/g;
	$line =~ s/,"/,/g;
	return (split(/,/, $line));
}

1;

