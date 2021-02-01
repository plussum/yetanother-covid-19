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
my $END_OF_DATA = "###EOD###";
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
	
my $ERN_CSV_DEF = {
	title => "ERN pref",
	main_url =>  "Dummy",
	csv_file =>  "$config::WIN_PATH/PNG/09_tko_NEW_CASES_ERN_DAY_main_pref_0401_ip_6_lp_7_rl_avr_7_-plot.csv.txt",
	src_url => 	"src_url",		# set

	down_load => \&download,

	direct => "vertical",		# vertical or holizontal(Default)
	timefmt => '%Y/%m/%d',		# comverbt to %Y-%m-%d
	src_dlm => "\t",
	keys => [0],		# 5, 1, 2
	data_start => 1,
};

my $MARGE_CSV_DEF = {
	title => "MARGED Apple and ERN pref",
	main_url =>  "Dummy",
	csv_file =>  "Dummy",
	src_url => 	"Dummy",		# set

	start_date => "2020-04-01",
	end_date   => "2020-01-14",
};
my @additonal_plot = (
	"100 axis x1y1 with lines title '100%' lw 1 lc 'blue' dt (3,7)",
	"1 axis x1y2 with lines title 'ern=1' lw 1 lc 'red' dt (3,7)",
);
my $ap = join(",", @additonal_plot);
my $MARGE_GRAPH_PARAMS = {
	html_title => "MARGE Apple Mobility Trends and ERN",
	png_path   => "$config::PNG_PATH",
	png_rel_path => "../PNG",
	html_file => "$config::HTML_PATH/applemobile_ern.html",

	dst_dlm => "\t",
	avr_date => 7,

	timefmt => '%Y-%m-%d',
	format_x => '%m/%d',

	term_x_size => 1000,
	term_y_size => 350,

	END_OF_DATA => $END_OF_DATA,

	ylabel => '%',
	y2label => 'ERN',
	default_graph => "line",
	ymin => 0,
	additional_plot => $ap,
	y2_source => 0,		# soruce csv definition for y2
	graph_params => [
		{dsc => "Tokyo Apple mobility Trends and ERN", lank => [1,999], static => "rlavr", target_col => ["Tokyo-,東京都"], 
			start_date => "2020-04-01", end_date => "2021-01-13", ymax => ""},
	#	{dsc => $END_OF_DATA},

		{dsc => "Osaka Apple mobility Trends and ERN", lank => [1,999], static => "rlavr", target_col => ["Osaka-,大阪府"], 
			start_date => "2020-04-01", end_date => "2021-01-13", ymax => ""},
		{dsc => "Kanagawa Apple mobility Trends and ERN", lank => [1,999], static => "rlavr", target_col => ["Kanagawa,神奈川県"], 
			start_date => "2020-04-01", end_date => "2021-01-13", ymax => ""},
		{dsc => "Hyogo Apple mobility Trends and ERN", lank => [1,999], static => "rlavr", target_col => ["Hyogo,兵庫県"], 
			start_date => "2020-04-01", end_date => "2021-01-13", ymax => ""},
		{dsc => "Kyoto Apple mobility Trends and ERN", lank => [1,999], static => "rlavr", target_col => ["Kyoto,京都府"], 
			start_date => "2020-04-01", end_date => "2021-01-13", ymax => ""},
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
#
#
csvgraph::new($CSV_DEF); 			# Load Apple Mobility Trends
csvgraph::load_csv($CSV_DEF);
csvgraph::average($CSV_DEF, 2, "avr");

csvgraph::new($ERN_CSV_DEF); 		# Load ERN
csvgraph::load_csv($ERN_CSV_DEF);

csvgraph::marge_csv($MARGE_CSV_DEF, $ERN_CSV_DEF, $CSV_DEF);
exit;
csvgraph::gen_html($MARGE_CSV_DEF, $MARGE_GRAPH_PARAMS);
