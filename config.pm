#
#
#
package config;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(config);

use strict;
use warnings;
#use ccse;
#use who;

our $WIN_PATH = "/mnt/f/cov/plussum.github.io";
our $HTML_PATH = "$WIN_PATH/HTML";
our $CSV_PATH  = "$WIN_PATH/CSV";
our $PNG_PATH  = "$WIN_PATH/PNG";
our $PNG_REL_PATH  = "../PNG";		# HTML からの相対パス
our $CSV_REL_PATH  = "../CSV";		# HTML からの相対パス

our $WHO_INDEX = "who_index.html";
our $RT_IP = 5;
our $RT_LP = 8;
our $THRESH_FT = {NC => 9, ND => 3, NR => 3};

our $POP_BASE = 1000 * 1000;		# 100万人当たりのケース数
our $POP_THRESH = 100 * 1000;		# 人口が少ないと振れ幅が大きいので、この人口より少ない国は対象外にする

our $DLM = ",";

our $MODE_NAME = {
	NC => "NEW CASES",
	ND => "NEW DEATHS",
	NR => "NEW RECOVERS",
	CC => "CCM CASES",
	CD => "CCM DEATHS",
	CR => "CCM RECOVERS",
};

my $CCSE_BASE_DIR = "/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series";

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
