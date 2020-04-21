#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、感染率のグラフを作成する
#
#	beoutbreakprepared
#	https://github.com/beoutbreakprepared/nCoV2019
#
#
use strict;
use warnings;
#use lib qw(../gsfh);
use csvgpl;
use csvaggregate;
use csvlib;
use jhccse;
use ft;

#
#	初期化など
#
my $DEBUG = 0;
my $DLM = ",";

my $WIN_PATH = "/mnt/f/OneDrive/cov";
my $BASE_DIR = "/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series";
my $file = "";
my $MODE = "";

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$MODE = "ND" if(/-ND/);
	$MODE = "NC" if(/-NC/);
	if(/-copy/){
		system("cp $BASE_DIR/*.csv $WIN_PATH");
		exit(0);
	}
}
if($MODE eq "NC"){
	$file = "$BASE_DIR/time_series_covid19_confirmed_global.csv";
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
#	John Hopkins CCSEから、定型のCSVを作成
#
my $IM_CSVF = "$WIN_PATH/ft-im-$MODE.csv";
my $FT_CSVF = "$WIN_PATH/cov_ft_$MODE" . ".csv";
my $ABS_CSVF = "$WIN_PATH/cov_ftabs_$MODE" . ".csv";
my $GRAPH_HTML = "$WIN_PATH/COVID-19_ft_$MODE.html";
my $PARAM = {
	input_file => $file,
	output_file => $IM_CSVF,
	population	=> "",
	delimiter => $DLM,
};
my ($colum_number, $record_number , $start_day, $last_day) = jhccse::jhccse($PARAM);


#
#	定型のCSVから、Finantial Times方式のデータを生成
#
my $THRESH_DAY = ($MODE eq "NC") ? 9 : 1;	# 10 : 1

my $FT_PARAM = {
	input_file => $IM_CSVF,
	output_file => $ABS_CSVF,
	average_day => 7,
	thresh => $THRESH_DAY,
	delimiter => ",",
};

ft::ft($FT_PARAM);


#
#	グラフとHTMLの作成
#
my $TD = "($record_number) src Johns Hopkins CSSE";
$TD =~ s#/#.#g;
my $mode = ($MODE eq "NC") ? "RATE NEW CASES" : "RATE NEW DEATHS" ;

my $guide = ft::exp_guide(2,10, 10, 'linecolor "#808080"');
my $ymin = '10';

#my $EXCLUSION = "Others,China,USA";
my $EXCLUSION = "Others";
my @PARAMS = (
	{ext => "$mode TOP5 $TD", start_day => 0, lank =>[0, 5] , exclusion => $EXCLUSION, 
		target => "", label_skip => 2, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600, 
		ft => 1, ymin => $ymin, additional_plot => $guide},
	{ext => "$mode Japn Koria FT $TD", start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => "Japan,Korea- South", label_skip => 2, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600, 
		ft => 1, ymin => $ymin, additional_plot => $guide},
	{ext => "$mode Japan and others FT $TD", start_day => 0, lank =>[0, 999] , exclusion => $EXCLUSION, 
			target => "Japan,Korea- South,US,Spain,Italy,France,Germany,United Kingdom,Iran,Turkey,Belgium,Switzeland",
		 	label_skip => 2, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600, ft => 1,  ymin => $ymin, additional_plot => $guide},
	{ext => "$mode TOP10 $TD", start_day => 0, lank =>[0, 10] , exclusion => $EXCLUSION, target => "", 
		label_skip => 7, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600,
		 ft => 1, ymin => $ymin, additional_plot => $guide},
	{ext => "$mode 10-20 $TD", start_day => 0, lank =>[10, 19] , exclusion => $EXCLUSION, 
		target => "", label_skip => 7, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600,
		 ft => 1, ymin => $ymin, additional_plot => $guide},
);
my @csvlist = (
    { name => "NEW CASE", csvf => $FT_CSVF, htmlf => $GRAPH_HTML, kind => "NC"},
#    { name => "NEW DETH", csvf => $FT_CSVF, htmlf => $GRAPH_HTML, kind => "ND"},
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

