#!/usr/bin/perl
#
#	Johne's hoplins university
#
#	Complete Data
#	https://covid19-static.cdn-apple.com/covid19-mobility-data/2025HotfixDev13/v3/en-us/applemobilitytrends-2021-01-25.csv
#
#	0                1              2    3     4          5       6         7
#	Province/State, Country/Region, Lat, Long, Dates
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

my $SRC_URL_TAG = "ccse";
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $src_url = "######"; #sprintf($SRC_URL_TAG, $year + 1900, $mon + 1, $mday);

my $CSV_DEF = {
	title => "Johns Hopkins Global",
	main_url =>  "https://covid19.apple.com/mobility",
	csv_file =>  "$config::CSV_PATH/time_series_covid19_confirmed_global.csv",
	src_url => $src_url,		# set

	down_load => \&download,

	src_dlm => ",",
	keys => [1, 0],		# 5, 1, 2
	data_start => 4,

	direct => "holizontal",		# vertical or holizontal(Default)
	timefmt => '%m/%d/%y',		# comverbt to %Y-%m-%d
};
	

my $END_OF_DATA = "###EOD###";

my $GRAPH_PARAMS = {
	html_title => $CSV_DEF->{title},
	png_path   => "$config::PNG_PATH",
	png_rel_path => "../PNG",
	html_file => "$config::HTML_PATH/ccse2.html",

	dst_dlm => "\t",
	avr_date => 7,

	timefmt => '%Y-%m-%d',
	format_x => '%m/%d',

	term_x_size => 1000,
	term_y_size => 350,

	END_OF_DATA => $END_OF_DATA,

	default_graph => "line",
	ymin => 0,
	#additional_plot => "100 with lines title '100%' lw 1 lc 'blue' dt (3,7)",

	graph_params => [
		{dsc => "Japan ", lank => [], static => "rlavr", target_col => ["","Japan"], },
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

