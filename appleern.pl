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
use dp;

binmode(STDOUT, ":utf8");

my $VERBOSE = 0;
my $DOWN_LOAD = 0;

my $DEFAULT_AVR_DATE = 7;
my $END_OF_DATA = "###EOD###";

my $SRC_URL_TAG = "https://covid19-static.cdn-apple.com/covid19-mobility-data/2025HotfixDev13/v3/en-us/applemobilitytrends-%04d-%02d-%02d.csv";
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $src_url = sprintf($SRC_URL_TAG, $year + 1900, $mon + 1, $mday);
my $ern_adp	= "1 with lines title 'ern=1' lw 1 lc 'red' dt (3,7)";


#
#	Definion of Apple Mobility Trends CSV Format
#
my $AMT_DEF = {
	title => "Apple Mobility Trends",
	main_url =>  "https://covid19.apple.com/mobility",
	csv_file =>  "$config::WIN_PATH/applemobile/applemobilitytrends.csv.txt",
	src_url => $src_url,		# set

	down_load => \&download,

	direct => "holizontal",		# vertical or holizontal(Default)
	timefmt => '%Y-%m-%d',		# comverbt to %Y-%m-%d
	src_dlm => ",",
	key_dlm => "#",
	keys => [1, 2],		# 5, 1, 2
	data_start => 6,
};

#
#	Definition of Graph Parameter for Apple Mobility Trends
#
my $REG = "country/region";
my $SUBR = "sub-region";
my $CITY = "city";
my $DRV = "driving";
my $TRN = "transit";
my $WLK = "walking";
my $AVR = "avr";

my $AMT_GRAPH = {
	html_title => $AMT_DEF->{title},
	png_path   => "$config::PNG_PATH",
	png_rel_path => "../PNG",
	html_file => "$config::HTML_PATH/apple_mobile.html",

	dst_dlm => "\t",
	avr_date => 7,

	timefmt => '%Y-%m-%d', format_x => '%m/%d',
	term_x_size => 1000, term_y_size => 350,
	ymin => 0,

	END_OF_DATA => $END_OF_DATA,

	default_graph => "line",
	additional_plot => "100 with lines title '100%' lw 1 lc 'blue' dt (3,7)",
	graph_params => [
		{dsc => "Tokyo Apple mobility Trends and ERN", lank => [1,10], static => "", 
			target_col => [$REG, "Japan", "", "", ""], 
			start_date => "2020-04-01", end_date => "2021-01-13", ymax => ""},
	],
};

#
#	Definition of Johns Hpkings University CCSE CSV format
#
my $CCSE_DEF = {
	title => "Johns Hopkins Global",
	main_url =>  "https://covid19.apple.com/mobility",
	csv_file =>  "$config::CSV_PATH/time_series_covid19_confirmed_global.csv",
	src_url => $src_url,		# set
	cumrative => 1,
	down_load => \&download,

	src_dlm => ",",
	keys => [1, 0],		# 5, 1, 2
	data_start => 4,

	direct => "holizontal",		# vertical or holizontal(Default)
	timefmt => '%m/%d/%y',		# comverbt to %Y-%m-%d
};
my $CCSE_GRAPH = {
	html_title => $CCSE_DEF->{title},
	png_path   => "$config::PNG_PATH",
	png_rel_path => "../PNG",
	html_file => "$config::HTML_PATH/ccse2.html",

	dst_dlm => "\t",
	avr_date => 7,
	default_graph => "line",

	timefmt => '%Y-%m-%d', format_x => '%m/%d',
	term_x_size => 1000, term_y_size => 350,
	ymin => 0,

	END_OF_DATA => $END_OF_DATA,

	graph_params => [
		{dsc => "Japan ern", lank => [1,99], static => "", target_col => ["","Japan"], 
			ylabel => "ern", y2label => "ern", additional_plot => $ern_adp, ymax => 3},
#		{dsc => "Japan rlavr", lank => [1,5], static => "rlavr", target_col => ["","Japan"], },
#		{dsc => "Japan ", lank => [1,5], static => "ern", target_col => ["","Japan"], 
#			ylabel => "ern", y2label => "ern", additional_plot => $ern_adp, ymax => 3},
#		{dsc => "World top 10 ", lank => [1,10], static => "", target_col => ["",""], },
#		{dsc => "World top 10 ", lank => [1,10], static => "rlavr", target_col => ["",""], },
	],
};

#
#	Definition of Marged CSV from Apple Mobility Trends and Johns Hopkings Univ. CCSE
#
my $MARGE_CSV_DEF = {
	title => "MARGED Apple and ERN pref",
	main_url =>  "Marged, no url",
	csv_file =>  "Marged, no csv file",
	src_url => 	"Marged, no src url",		# set
};
my @additonal_plot_list = (
	"100 axis x1y1 with lines title '100%' lw 1 lc 'blue' dt (3,7)",
	"1 axis x1y2 with lines title 'ern=1' lw 1 lc 'red' dt (3,7)",
);
my $additional_plot = join(",", @additonal_plot_list);

my $MARGE_GRAPH_PARAMS = {
	html_title => "MARGE Apple Mobility Trends and ERN",
	png_path   => "$config::PNG_PATH",
	png_rel_path => "../PNG",
	html_file => "$config::HTML_PATH/applemobile_ern.html",

	dst_dlm => "\t",
	avr_date => 7,
	END_OF_DATA => $END_OF_DATA,
	default_graph => "line",

	timefmt => '%Y-%m-%d', format_x => '%m/%d',
	term_x_size => 1000, term_y_size => 350,

	y2label => 'ERN', y2min => 0, y2max => 3, y2_source => 0,		# soruce csv definition for y2
	ylabel => '%', ymin => 0,
	additional_plot => $additional_plot,

	graph_params => [
#		{dsc => "Japan ", lank => [1,99], static => "", target_col => ["Japan"] },
#		{dsc => "USA",    lank => [1,99], static => "", target_col => ["US,United State"], },

#		{dsc => $END_OF_DATA},
#		{dsc => "Tokyo Apple mobility Trends and ERN", lank => [1,10], static => "ern", target_col => ["Tokyo-,Japan"], 
#			start_date => "2020-04-01", end_date => "2021-01-13", ymax => "", ymax => 3},
#
#		{dsc => "Osaka Apple mobility Trends and ERN", lank => [1,999], static => "", target_col => ["Osaka-,大阪府"], 
#			start_date => "2020-04-01", end_date => "2021-01-13", ymax => ""},
#		{dsc => "Kanagawa Apple mobility Trends and ERN", lank => [1,999], static => "rlavr", target_col => ["Kanagawa,神奈川県"], 
#			start_date => "2020-04-01", end_date => "2021-01-13", ymax => ""},
#		{dsc => "Hyogo Apple mobility Trends and ERN", lank => [1,999], static => "rlavr", target_col => ["Hyogo,兵庫県"], 
#			start_date => "2020-04-01", end_date => "2021-01-13", ymax => ""},
#		{dsc => "Kyoto Apple mobility Trends and ERN", lank => [1,999], static => "rlavr", target_col => ["Kyoto,京都府"], 
#			start_date => "2020-04-01", end_date => "2021-01-13", ymax => ""},
	],
};

my @TARGET_REAGION = (
		"Japan", "US,United States", 
		"United Kingdom", "France", "Spain", "Italy", "Russia", 
			"Germany", "Poland", "Ukraine", "Netherlands", "Czechia,Czech Republic", "Romania",
			"Belgium", "Portugal", "Sweden",
		"India",  "Indonesia", "Israel", # "Iran", "Iraq","Pakistan",
		"Brazil", "Colombia", "Argentina",  "Canada", "Chile", "Mexico",
		"South Africa", 
);
my $TARGET_GRAPH_TAG = {dsc => "", lank => [1,10], static => "", target_col => [] };
my $gp = $MARGE_GRAPH_PARAMS->{graph_params};

foreach my $reagion (@TARGET_REAGION){
	my $rn = $reagion;
	$rn =~ s/,.*$//;
	my @rr = ();
	foreach my $r (split(/,/, $reagion)){
		push(@rr, "$r-", "~$r#");
	}
	$reagion = join(",", @rr);
	
	push (@$gp, {
		dsc => "Mobiliy and ERN $rn",
		lank => [1,10],
		static => "",
		target_col => [$reagion],
		}
	);
} 
#foreach my $p (@$gp){
#	dp::dp join(", ", $p->{dsc}, @{$p->{target_col}}, @{$p->{lank}}, ) . "\n";
#}

my $TKY_DIR = "$config::WIN_PATH/tokyo/covid19"; # "/home/masataka/who/tokyo/covid19";
my $TOKYO_DEF = {
	title => "Tokyo Positive Rate",
	main_url => "-- tokyo data --- ",
	src_file => "$TKY_DIR/data/positive_rate.json",
	src_url => 	"--- src url ---",		# set
	json_items => [qw (diagnosed_date positive_count negative_count positive_rate)],
	down_load => \&download,

	direct => "json",		# vertical or holizontal(Default)
	timefmt => '%Y-%m-%d',		# comverbt to %Y-%m-%d
	src_dlm => ",",
	key_dlm => "#",
	keys => [0],		# 5, 1, 2
	data_start => 1,
};


csvgraph::new($TOKYO_DEF); 						# Load Apple Mobility Trends
csvgraph::load_csv($TOKYO_DEF);
csvgraph::dump_cdp($TOKYO_DEF, {ok => 1, lines => 5});
#csvgraph::gen_html($amt_country, $AMT_GRAPH);		# Generate Graph/HTHML
exit ;

#
#	Down Load CSV 
#
sub	download
{
	my ($cdp) = @_;
	return 1;
}

if(0){
	my @skeys = (
		["Japan", "~Japan-"],
		["United Kingdom", "United Kingdom-"],
	);
	my @items = ("Japan", "Japan-", "United State", "United Kingdom-Falkland Islands");
	foreach my $item ("Japan", "Japan-", "United State"){
		for my $skey (@skeys){
			dp::dp csvlib::search_listn($item, @$skey) . "[$item]" . join(",", @$skey) . "\n";
		}
	}
	exit;
}

#
#
#
csvgraph::new($AMT_DEF); 						# Load Apple Mobility Trends
csvgraph::load_csv($AMT_DEF);
my $amt_country = {};
csvgraph::reduce_cdp_target($AMT_DEF, $amt_country, ["$REG"]);
csvgraph::dump_cdp($amt_country, {ok => 1, lines => 5});
csvgraph::add_average($amt_country, 2, "avr");
csvgraph::comvert2rlavr($amt_country);
csvgraph::gen_html($amt_country, $AMT_GRAPH);		# Generate Graph/HTHML

csvgraph::new($CCSE_DEF); 						# Load Johns Hopkings University CCSE
csvgraph::load_csv($CCSE_DEF);
my $ccse_country = {};
csvgraph::reduce_cdp_target($CCSE_DEF, $ccse_country, ["NULL"]);
csvgraph::comvert2ern($ccse_country);				# Calc ERN
csvgraph::gen_html($ccse_country, $CCSE_GRAPH);		# Generate Graph/HTML

csvgraph::marge_csv($MARGE_CSV_DEF, $ccse_country, $amt_country);		# Marge CCSE(ERN) and Apple Mobility Trends
#csvgraph::dump_cdp($MARGE_CSV_DEF, {ok => 1, lines => 5});
csvgraph::gen_html($MARGE_CSV_DEF, $MARGE_GRAPH_PARAMS);		# Gererate Graph
exit;

my $gdp = $MARGE_GRAPH_PARAMS;
foreach my $gp (@{$gdp->{graph_params}}){
	csvgraph::csv2graph($MARGE_CSV_DEF, $gdp, $gp);
	dp::dp join(",", $gp->{dsc}, $gp->{start_date}, $gp->{end_date},
			$gp->{fname}, $gp->{plot_png}, $gp->{plot_csv}, $gp->{plot_cmd}) . "\n";
}

