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

	direct => "holizontal",
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
	additional_plot => "100 with lines title '100%' lw 1 lc 'blue' dt (3,7)",

	graph_params => [
		#{dsc => "Tokyo Apple mobility Trends and ERN", lank => [], static => "rlavr", target_col => ["Tokyo-,東京都"], 
		#	start_date => "2020-04-01", end_date => "2021-01-13", ymax => ""},
	],
};

my $REG = "country/region";
my $SUBR = "sub-region";
my $CITY = "city";
my $DRV = "driving";
my $TRN = "transit";
my $WLK = "walking";
my $AVR = "avr";
my $jp_target = "Tokyo,Kanagawa,Saitama,Chiba,Osaka,Kyoto,Hyogo,Fukuoka,Aichi,Hokaido";
my @targets = (

	{dsc => "Japan all average", target_col => [$REG, "Japan", "!$AVR", "", "", ""], ,lank => [1, 10]} ,
	{dsc => $END_OF_DATA},
	{dsc => "Japan Target average", target_col => [$SUBR, $jp_target, $AVR, "", "", "Japan"], ,lank => [1, 10]} ,
	{dsc => "Japan Target walk", target_col => [$SUBR, $jp_target, "walking", "", "", "Japan"], ,lank => [1, 20]} ,
	{dsc => "Tokyo Target all", target_col => [$SUBR, "Tokyo", "", "", "", "Japan"],,lank => [1, 20]} ,
	{dsc => "Tokyo 23 Target all", target_col => [$CITY, "Tokyo", "", "", "", "Japan"],,lank => [1, 20]} ,

	{dsc => "WorldWid transit  1-10", target_col => [$REG, "", $AVR, "", "", ""], ,lank => [ 1, 10]} ,
	{dsc => "WorldWid transit 11-10", target_col => [$REG, "", $AVR, "", "", ""], ,lank => [11, 20]} ,
	{dsc => "WorldWid transit 21-30", target_col => [$REG, "", $AVR, "", "", ""], ,lank => [21, 30]} ,
	{dsc => "WorldWid transit 21-40", target_col => [$REG, "", $AVR, "", "", ""], ,lank => [31, 40]} ,

	#{dsc => $END_OF_DATA},
	{dsc => "WorldWid transit", target_col => [$REG, "", $TRN, "", "", ""], ,lank => [1, 20]} ,
	{dsc => "WorldWid walking", target_col => [$REG, "", $WLK, "", "", ""], ,lank => [1, 20]} ,
	{dsc => "WorldWid driving", target_col => [$REG, "", $DRV, "", "", ""], ,lank => [1, 20]} ,

	{dsc => "US States driving", target_col => [$SUBR, "", $DRV, "", "", "United State"], ,lank => [1, 20]} ,
	{dsc => "US States transit", target_col => [$SUBR, "", $TRN, "", "", "United State"], ,lank => [1, 20]} ,
	{dsc => "US States walk", target_col => [$SUBR, "", $WLK, "", "", "United State"], ,lank => [1, 20]} ,

	{dsc => "Japan all", target_col => [$SUBR, $jp_target, "", "", "", "Japan"], } ,
	{dsc => "Japan walking", target_col => [$SUBR, $jp_target, $WLK, "", "", "Japan"], ,lank => [1, 20]} ,
	{dsc => "Japan transit ", target_col => [$SUBR, "Tokyo", $TRN, "", "", "Japan"],,lank => [1, 20]} ,
	{dsc => "Japan driving ", target_col => [$SUBR, "Tokyo", $DRV, "", "", "Japan"],,lank => [1, 20]} ,
	{dsc => $END_OF_DATA},
);


my @USA =	("country/region", "United State", "", "", "", ""); 
my @JAPAN =	("country/region", "Japan", "", "", "", ""); 
my @JP_PR_TR =	("sub-region", "", "transit", "", "", "Japan"); 
my @JP_PR_WK =	("sub-region", "", "walking", "", "", "Japan"); 
my @JP_CT_TR =	("city", "", "transit", "", "", "Japan"); 
my @JP_CT_WK =	("city", "", "walking", "", "", "Japan"); 
my @dates = (["",""], [-93, ""]);
my @statics = ("", "rlavr");

my $gpa = $GRAPH_PARAMS->{graph_params};
my $i = 0;
foreach my $tc (@targets){
	last if($tc->{dsc} eq $END_OF_DATA);
	foreach my $dt (@dates){
		foreach my $st (@statics){
			$gpa->[$i++] = {
				dsc => "#$i " . $tc->{dsc},
				lank => ($tc->{lank} // [1,20]),
				static => $st,
				target_col => $tc->{target_col},
				start_date => $dt->[0],
				end_date => $dt->[1],
				ymax => ($tc->{ymax} // ""),
			};
			
		}
	}
}

if(0){
	$i = 0;
	foreach my $gp (@$gpa){
		dp::dp join(",", $i++, $gp->{dsc}, $gp->{static}, $gp->{start_date}, $gp->{end_date}, 
				@{$gp->{lank}}, " # ", @{$gp->{target_col}}) . "\n";
	} 
}

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

