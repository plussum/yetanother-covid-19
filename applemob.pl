#!/usr/bin/perl
#
#	Apple Mobile report
#	https://covid19.apple.com/mobility
#
#	Complete Data
#	https://covid19-static.cdn-apple.com/covid19-mobility-data/2025HotfixDev13/v3/en-us/applemobilitytrends-2021-01-25.csv
#
#	0        1      2                   3                4          5       6         7
#	geo_type,region,transportation_type,alternative_name,sub-region,country,2020/1/13,2020/1/14,2020/1/15,2020/1/16
#	country/region,Japan,driving,日本,Japan-driving,,100,97.94,99.14,103.16
#
#	CSV_DEF
#		src_url => source_url of data,
#		src_csv => download csv data,
#		keys => [1, 2],		# region, transport
#		date_start => 6,	# 2020/01/13
#		html_title => "Apple Mobility Trends",
#	GRAPH_PARAMN
#		dsc => "Japan"
#		lank => [1,999],
#		graph => "LINE | BOX",
#		statics => "RLAVR",
#		target_area => "Japan,XXX,YYY", 
#		exclusion_are => ""
#
#
use strict;
use warnings;
use utf8;
use Encode 'decode';
use Data::Dumper;
use config;
use csvlib;
use csvgraph;

binmode(STDOUT, ":utf8");

my $VERBOSE = 0;

my $DOWN_LOAD = 0;
my $DEFAULT_AVR_DATE = 7;

my $KEY_DLM = "-";					# Initial key items

my $SRC_URL_TAG = "https://covid19-static.cdn-apple.com/covid19-mobility-data/2025HotfixDev13/v3/en-us/applemobilitytrends-%04d-%02d-%02d.csv";
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $src_url = sprintf($SRC_URL_TAG, $year + 1900, $mon + 1, $mday);

my $CSV_DEF = {
	title => "Apple Mobility Trends",
	main_url =>  "https://covid19.apple.com/mobility",
	csv_file =>  "$config::WIN_PATH/applemobile/applemobilitytrends.csv.txt",
	src_url => $src_url,		# set

	down_load => \&download,

	src_dlm => ",",
	keys => [1, 2],		# 5, 1, 2
	data_start => 6,
};
	
my $JP_TARGET = join("$KEY_DLM,", "Tokyo","Osaka");
my $EXEC = "driving";
my $US_TARGET = "United States";
my $US_STATE = join("$KEY_DLM,", "New Yorl","California");
my $US_EXEC = "";
my $END_OF_DATA = "###EOD###";
my @WW_TR =	("country/region", "", "transit", "", "", ""); 
my @WW_WK =	("country/region", "", "walking", "", "", ""); 
my @WW_DR =	("country/region", "", "driving", "", "", ""); 

my @USA =	("country/region", "United State", "", "", "", ""); 
my @JAPAN =	("country/region", "Japan", "", "", "", ""); 
my @JP_PR_TR =	("sub-region", "", "transit", "", "", "Japan"); 
my @JP_PR_WK =	("sub-region", "", "walking", "", "", "Japan"); 
my @JP_CT_TR =	("city", "", "transit", "", "", "Japan"); 
my @JP_CT_WK =	("city", "", "walking", "", "", "Japan"); 

#my $MAIN_PREF = "東京,神奈川,埼玉,千葉,大阪,京都,兵庫,福岡,愛知,北海道";
my @JP_TG_ALL =	("sub-region", "Tokyo,Kanagawa,Saitama,Chiba,Osaka,Kyoto,Hyogo,Fukuoka,Aichi,Hokaido", "", "", "", "Japan"); 
my @TKO_TG_ALL =	("sub-region", "Tokyo", "", "", "", "Japan"); 
my @JP_TG_TR =	("sub-region", "Tokyo,Kanagawa,Saitama,Chiba,Osaka,Kyoto,Hyogo,Fukuoka,Aichi,Hokaido", "transit", "", "", "Japan"); 
my @JP_TG_WK =	("sub-region", "Tokyo,Osaka,Kanagawa,Chiba,Saitama,Tochigi,Aichi,Kyoto,Hyogo", "walking", "", "", "Japan"); 
my @TKO_TG_WK =	("sub-region", "Tokyo", "walking", "", "", "Japan"); 
my @US_ST_DRV=	("sub-region", "", "driving", "", "", "United State"); 
my @US_ST_TRN =	("sub-region", "", "transit", "", "", "United State"); 
my @US_ST_WLK =	("sub-region", "", "walking", "", "", "United State"); 

my $GRAPH_PARAMS = {
	html_title => $CSV_DEF->{title},
	png_path   => "$config::PNG_PATH",
	png_rel_path => "../PNG",
	html_file => "$config::HTML_PATH/apple_mobile.html",

	dst_dlm => "\t",
	avr_date => 7,

	timefmt => '%Y-%m-%d',
	format_x => '%m/%d',

	term_x_size => 1000,
	term_y_size => 350,

	END_OF_DATA => $END_OF_DATA,

	default_graph => "line",
	ymin => 0,
	additional_plot => 100,

	graph_params => [
		{dsc => "Japan target area Walking 2", lank => [1,99], static => "rlavr", target_col => [@TKO_TG_ALL], 
			start_date => "2020-03-12", end_date => "2021-01-13"},
		{dsc => $END_OF_DATA},
		{dsc => "Japan target area Walking 2", lank => [1,99], static => "rlavr", target_col => [@JP_TG_WK], 
			start_date => "2020-03-12", end_date => "2021-01-13"},
		{dsc => "Tokyo target area Walking 2", lank => [1,99], static => "rlavr", target_col => [@TKO_TG_WK], 
			start_date => "2020-03-12", end_date => "2021-01-13"},
		{dsc => $END_OF_DATA},

		{dsc => "Japan", lank => [1,99], static => "", target_col => [@JAPAN], start_date => "", end_date => ""},
		{dsc => "Japan", lank => [1,99], static => "rlavr", target_col => [@JAPAN], start_date => "", end_date => ""},
		{dsc => "Japan 2m", lank => [1,99], static => "", target_col => [@JAPAN], start_date => -93, end_date => ""},
		{dsc => "Japan 2m", lank => [1,99], static => "rlavr", target_col => [@JAPAN], start_date => -93, end_date => ""},

		{dsc => "Japan target area Transit", lank => [1,99], static => "", target_col => [@JP_TG_TR], start_date => "", end_date => ""},
		{dsc => "Japan target area Transit", lank => [1,99], static => "rlavr", target_col => [@JP_TG_TR], start_date => "", end_date => ""},
		{dsc => "Japan target area Transit 2m", lank => [1,99], static => "", target_col => [@JP_TG_TR], start_date => -93, end_date => ""},
		{dsc => "Japan target area Transit 2m", lank => [1,99], static => "rlavr", target_col => [@JP_TG_TR], start_date => -93, end_date => ""},

		{dsc => "Japan target area Walking", lank => [1,99], static => "", target_col => [@JP_TG_WK], start_date => "", end_date => ""},
		{dsc => "Japan target area Walking", lank => [1,99], static => "rlavr", target_col => [@JP_TG_WK], start_date => "", end_date => ""},


		{dsc => "Japan target area Walking 2m", lank => [1,99], static => "", target_col => [@JP_TG_WK], start_date => -93, end_date => ""},
		{dsc => "Japan target area Walking 2m", lank => [1,99], static => "rlavr", target_col => [@JP_TG_WK], start_date => -93, end_date => ""},
		{dsc => $END_OF_DATA},

		{dsc => "Japan prefecture Transit", lank => [1,20], static => "", target_col => [@JP_PR_TR], start_date => "", end_date => ""},
		{dsc => "Japan prefecture Transit", lank => [1,20], static => "rlavr", target_col => [@JP_PR_TR], start_date => "", end_date => ""},
		{dsc => "Japan prefecture Transit 2m", lank => [1,20], static => "", target_col => [@JP_PR_TR], start_date => -93, end_date => ""},
		{dsc => "Japan prefecture Transit 2m", lank => [1,20], static => "rlavr", target_col => [@JP_PR_TR], start_date => -93, end_date => ""},

		{dsc => "Japan prefecture Walking", lank => [1,20], static => "", target_col => [@JP_PR_WK], start_date => "", end_date => ""},
		{dsc => "Japan prefecture Walking", lank => [1,20], static => "rlavr", target_col => [@JP_PR_WK], start_date => "", end_date => ""},
		{dsc => "Japan prefecture Walking 2m", lank => [1,20], static => "", target_col => [@JP_PR_WK], start_date => -93, end_date => ""},
		{dsc => "Japan prefecture Walking 2m", lank => [1,20], static => "rlavr", target_col => [@JP_PR_WK], start_date => -93, end_date => ""},

		{dsc => "Japan city Transit", lank => [1,20], static => "", target_col => [@JP_CT_TR], start_date => "", end_date => ""},
		{dsc => "Japan city Transit", lank => [1,20], static => "rlavr", target_col => [@JP_CT_TR], start_date => "", end_date => ""},
		{dsc => "Japan city Transit 2m", lank => [1,20], static => "", target_col => [@JP_CT_TR], start_date => -93, end_date => ""},
		{dsc => "Japan city Transit 2m", lank => [1,20], static => "rlavr", target_col => [@JP_CT_TR], start_date => -93, end_date => ""},

		{dsc => "Japan city Walking", lank => [1,20], static => "", target_col => [@JP_CT_WK], start_date => "", end_date => ""},
		{dsc => "Japan city Walking", lank => [1,20], static => "rlavr", target_col => [@JP_CT_WK], start_date => "", end_date => ""},
		{dsc => "Japan city Walking 2m", lank => [1,20], static => "", target_col => [@JP_CT_WK], start_date => -93, end_date => ""},
		{dsc => "Japan city Walking 2m", lank => [1,20], static => "rlavr", target_col => [@JP_CT_WK], start_date => -93, end_date => ""},

		#{dsc => $END_OF_DATA},
		{dsc => "World wide Transit", lank => [1,10], static => "", target_col => [@WW_TR], start_date => "", end_date => ""},
		{dsc => "World wide Transit", lank => [1,10], static => "rlavr", target_col => [@WW_TR], start_date => "", end_date => ""},
		{dsc => "World wide Transit 2m", lank => [1,10], static => "", target_col => [@WW_TR], start_date => -93, end_date => ""},
		{dsc => "World wide Transit 2m", lank => [1,10], static => "rlavr", target_col => [@WW_TR], start_date => -93, end_date => ""},

		{dsc => "World wide Walking", lank => [1,10], static => "", target_col => [@WW_WK], start_date => "", end_date => ""},
		{dsc => "World wide Walking", lank => [1,10], static => "rlavr", target_col => [@WW_WK], start_date => "", end_date => ""},
		{dsc => "World wide Walking 2m", lank => [1,10], static => "", target_col => [@WW_WK], start_date => -93, end_date => ""},
		{dsc => "World wide Walking 2m", lank => [1,10], static => "rlavr", target_col => [@WW_WK], start_date => -93, end_date => ""},

		{dsc => "World wide Driving", lank => [1,10], static => "", target_col => [@WW_DR], start_date => "", end_date => ""},
		{dsc => "World wide Driving", lank => [1,10], static => "rlavr", target_col => [@WW_DR], start_date => "", end_date => ""},
		{dsc => "World wide Driving 2m", lank => [1,10], static => "", target_col => [@WW_DR], start_date => -93, end_date => ""},
		{dsc => "World wide Transit 2m", lank => [1,10], static => "rlavr", target_col => [@WW_DR], start_date => -93, end_date => ""},

		{dsc => "USA DRV", lank => [1,10], static => "", target_col => [@USA], start_date => "", end_date => ""},
		{dsc => "USA DRV", lank => [1,10], static => "rlavr", target_col => [@USA], start_date => "", end_date => ""},
		{dsc => "USA DRV 2m", lank => [1,10], static => "", target_col => [@USA], start_date => -93, end_date => ""},
		{dsc => "USA DRV 2m", lank => [1,10], static => "rlavr", target_col => [@USA], start_date => -93, end_date => ""},

		{dsc => "USA STATES DRV", lank => [1,10], static => "", target_col => [@US_ST_DRV], start_date => "", end_date => ""},
		{dsc => "USA STATES DRV", lank => [1,10], static => "rlavr", target_col => [@US_ST_DRV], start_date => "", end_date => ""},
		{dsc => "USA STATES DRV target area 2m", lank => [1,10], static => "", target_col => [@US_ST_DRV], start_date => -93, end_date => ""},
		{dsc => "USA STATES DRV target area 2m", lank => [1,10], static => "rlavr", target_col => [@US_ST_DRV], start_date => -93, end_date => ""},

		{dsc => "USA STATES TRNSIT", lank => [1,10], static => "", target_col => [@US_ST_TRN], start_date => "", end_date => ""},
		{dsc => "USA STATES TRNSIT", lank => [1,10], static => "rlavr", target_col => [@US_ST_TRN], start_date => "", end_date => ""},
		{dsc => "USA STATES TRNSIT 2m", lank => [1,10], static => "", target_col => [@US_ST_TRN], start_date => -93, end_date => ""},
		{dsc => "USA STATES TRNSIT 2m", lank => [1,10], static => "rlavr", target_col => [@US_ST_TRN], start_date => -93, end_date => ""},

		{dsc => "USA STATES WALK", lank => [1,10], static => "", target_col => [@US_ST_WLK], start_date => "", end_date => ""},
		{dsc => "USA STATES WALK", lank => [1,10], static => "rlavr", target_col => [@US_ST_WLK], start_date => "", end_date => ""},
		{dsc => "USA STATES WALK 2m", lank => [1,10], static => "", target_col => [@US_ST_WLK], start_date => -93, end_date => ""},
		{dsc => "USA STATES WALK 2m", lank => [1,10], static => "rlavr", target_col => [@US_ST_WLK], start_date => -93, end_date => ""},

		{dsc => $END_OF_DATA},


	#	{dsc => "USA", lank => [], static => "", target => $US_TARGET, exclusion => $US_EXEC, start_date => "", end_date => ""},
	#	{dsc => "USA", lank => [], static => "rlavr", target => $US_TARGET, exclusion => $US_EXEC, start_date => "", end_date => ""},
	#	{dsc => "USA target area 2m", lank => [0,10], static => "", target => "$US_TARGET", exclusion => $US_EXEC, start_date => -93, end_date => ""},
	#	{dsc => "USA target area 2m", lank => [0,10], static => "rlavr", target => "$US_TARGET", exclusion => $US_EXEC, start_date => -93, end_date => ""},

		{dsc => $END_OF_DATA},


	],
};

#
#	Down Load CSV 
#
sub	download
{
	my ($cdp) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $src_url = $cdp->{src_url};
	my $wget = "wget $src_url -O " . $cdp->{csv_file};
	dp::dp $wget ."\n" if($VERBOSE);
	system($wget);
	return 1;
}

#
#	Generate Graph
#
csvgraph::new($CSV_DEF); 
csvgraph::load_csv($CSV_DEF);
csvgraph::average($CSV_DEF, 2, "avr");
csvgraph::gen_html($CSV_DEF, $GRAPH_PARAMS);

