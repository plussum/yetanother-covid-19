#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、感染率のグラフを作成する
#
#	beoutbreakprepared
#	https://github.com/beoutbreakprepared/nCoV2019
#
#
use strict;
#use warnings;
use lib qw(../gsfh);
use csvgpl;
use jhccse;
use rate;
use csvlib;

#
#	初期化など
#
my $DEBUG = 0;
my $DLM = ",";


my $WIN_PATH = "/mnt/f/OneDrive/cov";
my $BASE_DIR = "/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series";
my $file = "";
my $MODE = "";
my $DT_S = 4;
my $DATA = "";

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$MODE = "ND" if(/-ND/);
	$MODE = "NC" if(/-NC/);
	$DATA = "JP" if(/-JP/);
	if(/-copy/){
		system("cp $BASE_DIR/*.csv $WIN_PATH");
		exit(0);
	}
}
if($MODE eq "NC"){
	if(! $DATA){
		$file = "$BASE_DIR/time_series_covid19_confirmed_global.csv";
	}
	else {
		$file = "$WIN_PATH/covPrefect.csv";
		$DT_S = 2;
	}
}
elsif($MODE eq "ND"){
	$file = "$BASE_DIR/time_series_covid19_deaths_global.csv";
}
else {
	system("$0 -NC");
	system("$0 -ND");
	exit(0);
}

#
#	 John Hopkins CCSEを標準のCSVに変換
#
my $IMF_CSVF = "$WIN_PATH/cov_daily_im_rate$MODE" . ".csv";
my $REPORT_CSVF = "$WIN_PATH/cov_daily_rate$MODE" . ".csv";
my $GRAPH_HTML = "$WIN_PATH/COVID-19_rate$MODE" . ".html";
my $PARAM = {
	input_file => $file,
	output_file => $IMF_CSVF,
	population	=> "",
	delimiter => ",",
};
my ($colum, $record , $start_day, $last_day) = jhccse::jhccse($PARAM);


#
#	定型のCSVから、再生産数 のデータを生成
#

my $RATE_PARAM = {
	input_file => $IMF_CSVF,
	output_file => $REPORT_CSVF,
	delimiter => $DLM,
	lp 		=> 5,	# 5 潜伏期間
	ip 		=> 8,	# 8 感染期間
};
rate::rate($RATE_PARAM);
dp::dp $REPORT_CSVF . "\n";

#
#	グラフとHTMLの作成
#

my $TD = "($last_day) src Johns Hopkins CSSE";
$TD =~ s#/#.#g;
my $mode = ($MODE eq "NC") ? "RATE NEW CASES" : "RATE NEW DEATHS" ;

my $EXCLUSION = "Others";
my $R0_LINE = "1 with lines dt \"-\" title 'R0=0'";
my @PARAMS = (
	{ext => "$mode Japan 0301 $TD", start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan", 
		label_skip => 2, graph => "lines", additional_plot => $R0_LINE},
	{ext => "$mode Japan 3weeks $TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan",
		 label_skip => 1, graph => "lines", additional_plot => $R0_LINE, ymin => 0},
	{ext => "$mode Germany 0301 $TD",   start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany",
		 label_skip => 2, graph => "lines", additional_plot => $R0_LINE},
	{ext => "$mode Germany 3weeks $TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany",
		 label_skip => 1, graph => "lines", additional_plot => $R0_LINE},
	{ext => "$mode Forcus area 01 3weeks $TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany,US,Italy,Spain,France",
		 label_skip => 1, graph => "lines", additional_plot => $R0_LINE},
	{ext => "$mode Focusing area from 0301 $TD",   start_day => 39, lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => "Russia,Canada,Ecuador,Brazil,India", label_skip => 3, graph => "lines", ymax => 10, additional_plot => $R0_LINE},
	{ext => "$mode TOP 01-05 from 0301 $TD",   start_day => 39, lank =>[0, 4] , exclusion => $EXCLUSION, target => "", 
		label_skip => 3, graph => "lines", ymax => 10, additional_plot => $R0_LINE},
	{ext => "$mode TOP 06-10 from 0301 $TD",   start_day => 39, lank =>[5, 9] , exclusion => $EXCLUSION, target => "", 
		label_skip => 3, graph => "lines", ymax => 10, additional_plot => $R0_LINE},
	{ext => "$mode TOP 10 3w $TD",   start_day => -21, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
		label_skip => 1, graph => "lines", ymax => "", additional_plot => $R0_LINE},
	{ext => "$mode TOP 10 2w $TD",   start_day => -14, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
		label_skip => 1, graph => "lines", ymax => "", additional_plot => $R0_LINE},
	{ext => "$mode TOP 10 1w $TD",   start_day => -7, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
		label_skip => 1, graph => "lines", ymax => "", additional_plot => $R0_LINE},
);
my $src_url = "https://github.com/beoutbreakprepared/nCoV2019";
my $src_ref = "<a href=\"$src_url\">$src_url</a>";
my @csvlist = (
    { name => "COV19 RATE NEW CASE", csvf => $REPORT_CSVF, htmlf => $GRAPH_HTML, kind => "NC", src_ref => $src_ref },
#    { name => "NEW DETH", csvf => $RATE_CSVF, htmlf => $GRAPH_HTML, kind => "ND"},
);

foreach my $clp (@csvlist){
    my %params = (
        debug => $DEBUG,
        win_path => $WIN_PATH,
		data_rel_path => "cov_data",
        clp => $clp,
        params => \@PARAMS,
    );
    csvgpl::csvgpl(\%params);
}

