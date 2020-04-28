#
#
#
package config;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(config);

use strict;
use warnings;
use ccse;

our $WIN_PATH = "/mnt/f/OneDrive/cov";
our $HTML_PATH = "$WIN_PATH/HTML";
our $CSV_PATH  = "$WIN_PATH/CSV";
our $PNG_PATH  = "$WIN_PATH/PNG";
our $PNG_REL_PATH  = "../PNG";		# HTML からの相対パス
our $DLM = ",";


my $CCSE_BASE_DIR = "/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series";

our  $INFO_PATH = { 
	"ccse" => { 
		src => "Johns Hopkins CSSE", 
		src_url => "https://github.com/beoutbreakprepared/nCoV2019",
		params => $ccse::PARAMS,
		prefix => "jhccse_",
		NC => "$CCSE_BASE_DIR/time_series_covid19_confirmed_global.csv",
		ND => "$CCSE_BASE_DIR/time_series_covid19_deaths_global.csv",
		base_dir => $CCSE_BASE_DIR,
		# system("(cd ../COVID-19; git pull origin master)");
	},
	"who" => { 
		src => "WHO situation report", 
		nc => "$WIN_PATH/who_situation_report_NC.csv.txt",
		nd => "$WIN_PATH/who_situation_report_ND.csv.txt",
	},
	"japan" => { 
		nc => "$WIN_PATH/gis-jag-japan.csv.txt",
		nd => "",
	},
};	

our $CSS = << "_EOCSS_";
    <meta charset="utf-8">
    <style type="text/css">
    <!--
        span.c {font-size: 12px;}
    -->
    </style>
_EOCSS_

our $CLASS = "class=\"c\"";

1;	
