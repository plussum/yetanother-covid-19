#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、CSVとグラフを生成する
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
use dp;
use params;


#
#	初期化など
#
my $DEBUG = 0;
my $MIN_TOTAL = 100;
my $DLM = ",";

my $WIN_PATH = "/mnt/f/OneDrive/cov";
#my $file = "./COVID-19/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv";
#my $file = "./csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv";
my $BASE_DIR = "/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series";
my $file = "";
my $MODE = "";
my $POP = "";
my %NO_POP = ();
my $DOWNLOAD = 0;
for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$MODE = "ND" if(/-ND/);
	$MODE = "NC" if(/-NC/);
	$MODE = "FT" if(/-FT/);
	$MODE = "RT" if(/-RT/);
	$MODE = "ALL" if(/-ALL/i);
	$DOWNLOAD = 1 if(/-DL/i);
	$POP  = "-POP" if(/-POP/);
	
	if(/-copy/){
		system("cp $BASE_DIR/*.csv $WIN_PATH");
		exit(0);
	}
}
if($DOWNLOAD){
	system("(cd ../COVID-19; git pull origin master)");
}	
if($MODE eq "NC"){
	$file = "$BASE_DIR/time_series_covid19_confirmed_global.csv";
}
elsif($MODE eq "ND"){
	$file = "$BASE_DIR/time_series_covid19_deaths_global.csv";
}
elsif($MODE eq "FT"){
	system("./ft.pl");
	exit(0);
}
elsif($MODE eq "RT"){
	system("./rate.pl");
}
elsif($POP && !$MODE){
	system("$0 -NC -POP");
	system("$0 -ND -POP");
}
elsif($MODE eq "ALL"){
	system("$0 -NC ");
	system("$0 -ND ");
	system("$0 -FT ");
	system("$0 -RT ");
	system("$0 -NC -POP");
	system("$0 -ND -POP");
}
else {
	system("$0 -NC ");
	system("$0 -ND ");
	system("$0 -FT ");
	system("$0 -RT ");
	exit(0);
}


#
#	Open File
#
my $REPORT_CSVF = "$WIN_PATH/cov_daily_$MODE" . "$POP" . ".csv";
my $GRAPH_HTML = "$WIN_PATH/COVID-19_$MODE" . "$POP.html";

my $PARAM = {
	input_file => $file,
	output_file => $REPORT_CSVF,
	population	=> $POP,
	delimiter => ",",
};
my ($colum, $record , $start_day, $last_day) = jhccse::jhccse($PARAM);


#
#	グラフとHTMLの作成
#

my $src = "src Johns Hopkins CSSE";
my $TD = "($last_day) src Johns Hopkins CSSE";
$TD =~ s#/#.#g;
my $mode = ($MODE eq "NC") ? "NEW CASES" : "NEW DEATHS" ;
$mode = "#KIND#";
$mode .= $POP;

#my $EXCLUSION = "Others,China,USA";
my $EXCLUSION = "Others,US";
#
#	
#	{ext => "EOD"},		End of Data  そこまでで処理をやめたいとき 
#
my @LOCAL_PARAMS = (
    {ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0,  lank =>[0, 999] , exclusion => $EXCLUSION, target => "Taiwan", label_skip => 3, graph => "lines"},
    {ext => "#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXCLUSION, target => "China", label_skip => 3, graph => "lines"},
);
my @PARAMS = (params::common() , @LOCAL_PARAMS);


#
#	PARAMS for POP
#
my $EXC_POP = "San Marino,Holy See";
my @PARAMS_POP = (
	{ext => "$mode 01-05 -218 $TD($EXC_POP)", start_day => 27, lank =>[0, 4] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 06-10 -218 $TD($EXC_POP)", start_day => 27, lank =>[5, 9] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 11-15 -218 $TD($EXC_POP)", start_day => 27, lank =>[10, 14] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 16-20 -218 $TD($EXC_POP)", start_day => 27, lank =>[15, 19] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 01-05 from 0301 $TD($EXC_POP)", start_day => 38, lank =>[0,  4] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 06-10 from 0301 $TD($EXC_POP)", start_day => 38, lank =>[5,  9] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 10-15 from 0301 $TD($EXC_POP)", start_day => 38, lank =>[10, 14] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 16-20 from 0301 $TD($EXC_POP)", start_day => 38, lank =>[15, 19] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 3weeks 01-05 $TD($EXC_POP)", start_day => -21, lank =>[0, 4] , exclusion => $EXC_POP, target => "", graph => "lines"},
	{ext => "$mode 3weeks 06-10 $TD($EXC_POP)", start_day => -21, lank =>[5, 9] , exclusion => $EXC_POP, target => "", graph => "lines"},
	{ext => "$mode 3weeks 11-15 $TD($EXC_POP)", start_day => -21, lank =>[10,14] , exclusion => $EXC_POP, target => "", graph => "lines"},
	{ext => "$mode 3weeks 16-20 $TD($EXC_POP)", start_day => -21, lank =>[15,19] , exclusion => $EXC_POP, target => "", graph => "lines"},

	{ext => "$mode TOP20-218 $TD", start_day => 27, lank =>[0, 19] , exclusion => "", target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 01-10 from 0301 $TD",   start_day => 38, lank =>[0,  9] , exclusion => "", target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 3weeks 01-05 $TD", start_day => -21, lank =>[0, 4] , exclusion => "", target => "", graph => "lines"},

	{ext => "$mode Japan-122 $TD", start_day => 0, lank =>[0, 9999] , exclusion => $EXC_POP, target => "Japan", label_skip => 3, graph => "bars"},
#	{ext => "$mode Japan 2weeks $TD", start_day => -21, lank =>[0, 9999] , exclusion => $EXC_POP, target => "Japan", label_skip => 1, graph => "bars"},
	{ext => "$mode US $TD", start_day => 39,  lank =>[0, 100] , exclusion => "Others", target => "US", label_skip => 2, graph => "lines"},
	{ext => "$mode China $TD", start_day => 0,  lank =>[0, 100] , exclusion => "Others", target => "China", label_skip => 2, graph => "lines"},

);
my $src_url = "https://github.com/beoutbreakprepared/nCoV2019";
my $src_ref = "<a href=\"$src_url\">$src_url</a>";   
my @csvlist = (
    { name => "COV19 CASES NEW", csvf => $REPORT_CSVF, htmlf => $GRAPH_HTML, kind => "NC", src_ref => $src_ref},
    { name => "COV19 DEATHS NEW", csvf => $REPORT_CSVF, htmlf => $GRAPH_HTML, kind => "ND", src_ref => $src_ref},
);

foreach my $clp (@csvlist){
   next if($clp->{kind} ne $MODE); 
	my $parap = ($POP) ? \@PARAMS_POP : \@PARAMS;
    my %params = (
        debug => $DEBUG,
        win_path => $WIN_PATH,
        clp => $clp,
        params => $parap,
		data_rel_path => "cov_data",
    );
    csvgpl::csvgpl(\%params);
}

