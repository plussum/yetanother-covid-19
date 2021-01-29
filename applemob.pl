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
	
my $JP_TARGET = "Tokyo$KEY_DLM,Osaka$KEY_DLM";
my $EXEC = "driving";
my $US_TARGET = "United States";
my $US_STATE = "$KEY_DLM" . "United States";
my $US_EXEC = "";
my $END_OF_DATA = "###EOD###";
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

	default_graph => "line",
	END_OF_DATA => $END_OF_DATA,
	graph_params => [
		{dsc => "Japan", lank => [], static => "", target => "Japan", exclusion => "", start_date => "", end_date => ""},

		{dsc => "Japan", lank => [], static => "rlavr", target => "Japan", exclusion => "", start_date => "", end_date => ""},
		{dsc => "Japan 2m", lank => [], static => "", target => "Japan", exclusion => "", start_date => -93, end_date => ""},
		{dsc => "Japan 2m", lank => [], static => "rlavr", target => "Japan", exclusion => "", start_date => -93, end_date => ""},

		{dsc => "Japan target area", lank => [], static => "", target => $JP_TARGET, exclusion => $EXEC, start_date => "", end_date => ""},
		{dsc => "Japan target area", lank => [], static => "rlavr", target => $JP_TARGET, exclusion => $EXEC, start_date => "", end_date => ""},
		{dsc => "Japan target area 2m", lank => [], static => "", target => $JP_TARGET, exclusion => $EXEC, start_date => -93, end_date => ""},
		{dsc => "Japan target area 2m", lank => [], static => "rlavr", target => $JP_TARGET, exclusion => $EXEC, start_date => -93, end_date => ""},

		{dsc => $END_OF_DATA},

		{dsc => "USA", lank => [], static => "", target => $US_TARGET, exclusion => $US_EXEC, start_date => "", end_date => ""},
		{dsc => "USA", lank => [], static => "rlavr", target => $US_TARGET, exclusion => $US_EXEC, start_date => "", end_date => ""},
		{dsc => "USA target area 2m", lank => [0,10], static => "", target => "$US_TARGET", exclusion => $US_EXEC, start_date => -93, end_date => ""},
		{dsc => "USA target area 2m", lank => [0,10], static => "rlavr", target => "$US_TARGET", exclusion => $US_EXEC, start_date => -93, end_date => ""},
		{dsc => "USA CITY", lank => [], static => "", target => $US_STATE, exclusion => $US_EXEC, start_date => "", end_date => ""},
		{dsc => "USA CITY", lank => [], static => "rlavr", target => $US_STATE, exclusion => $US_EXEC, start_date => "", end_date => ""},
		{dsc => "USA CITY target area 2m", lank => [0,10], static => "", target => "$US_STATE", exclusion => $US_EXEC, start_date => -93, end_date => ""},
		{dsc => "USA CITY target area 2m", lank => [0,10], static => "rlavr", target => "$US_STATE", exclusion => $US_EXEC, start_date => -93, end_date => ""},



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
csvgraph::gen_html($CSV_DEF, $GRAPH_PARAMS);

