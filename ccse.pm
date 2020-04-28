#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、CSVとグラフを生成する
#
#	beoutbreakprepared
#	https://github.com/beoutbreakprepared/nCoV2019
#
#
package ccse;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(ccse);

use strict;
use warnings;
use Data::Dumper;
use config;
use csvgpl;
use jhccse;
use dp;
use params;
use ft;
use rate;


#
#	初期化など
#
my $DEBUG = 0;
my $DLM = $config::DLM;
my $WIN_PATH = $config::WIN_PATH;
my $INFO_PATH = $config::INFO_PATH->{ccse};

my $EXCLUSION = "Others,US";
my $EXC_POP = "San Marino,Holy See";
my $FT_TD = "#FT_TD#";
my $RT_TD = "#RT_TD#"; #"ip($ip)lp($lp)moving avr($average_date) (#LD#) src $SOURCE_DATA";
my $infopath = $config::INFOPATH->{ccse} ;

our $PARAMS = {
	comment => "**** CCSE PARAMS ****",
	src => $infopath->{src},
	aggregate => \&aggregate,
	download => \&download,
	copy => \&copy,
	DLM => ",",
	COUNT => {
		EXEC => "US",
		graphp => [@params::COMMON_PARAMS, 
			{ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0, lank =>[0, 999], exclusion => $EXCLUSION, target => "Taiwan", label_skip => 3, graph => "lines"},
			{ext => "#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19], exclusion => $EXCLUSION, target => "China", label_skip => 3, graph => "lines"},
		],
	},
	POP => {
		EXC => "San Marino,Holy See",
		graphp => [
		{ext => "#KIND# 01-05 -218 ($EXC_POP) (#LD#)", start_day => 27, lank =>[0, 4] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
		{ext => "#KIND# 06-10 -218 ($EXC_POP) (#LD#)", start_day => 27, lank =>[5, 9] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
		{ext => "#KIND# 11-15 -218 ($EXC_POP) (#LD#)", start_day => 27, lank =>[10, 14] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
		{ext => "#KIND# 16-20 -218 ($EXC_POP) (#LD#)", start_day => 27, lank =>[15, 19] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
		{ext => "#KIND# 01-05 from 0301 ($EXC_POP) (#LD#)", start_day => 38, lank =>[0,  4] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
		{ext => "#KIND# 06-10 from 0301 ($EXC_POP) (#LD#)", start_day => 38, lank =>[5,  9] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
		{ext => "#KIND# 10-15 from 0301 ($EXC_POP) (#LD#)", start_day => 38, lank =>[10, 14] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
		{ext => "#KIND# 16-20 from 0301 ($EXC_POP) (#LD#)", start_day => 38, lank =>[15, 19] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
		{ext => "#KIND# 3weeks 01-05 ($EXC_POP) (#LD#)", start_day => -21, lank =>[0, 4] , exclusion => $EXC_POP, target => "", graph => "lines"},
		{ext => "#KIND# 3weeks 06-10 ($EXC_POP) (#LD#)", start_day => -21, lank =>[5, 9] , exclusion => $EXC_POP, target => "", graph => "lines"},
		{ext => "#KIND# 3weeks 11-15 ($EXC_POP) (#LD#)", start_day => -21, lank =>[10,14] , exclusion => $EXC_POP, target => "", graph => "lines"},
		{ext => "#KIND# 3weeks 16-20 ($EXC_POP) (#LD#)", start_day => -21, lank =>[15,19] , exclusion => $EXC_POP, target => "", graph => "lines"},

		{ext => "#KIND# TOP20-218 (#LD#)", start_day => 27, lank =>[0, 19] , exclusion => "", target => "", label_skip => 3, graph => "lines"},
		{ext => "#KIND# 01-10 from 0301 (#LD#)",   start_day => 38, lank =>[0,  9] , exclusion => "", target => "", label_skip => 3, graph => "lines"},
		{ext => "#KIND# 3weeks 01-05 (#LD#)", start_day => -21, lank =>[0, 4] , exclusion => "", target => "", graph => "lines"},

		{ext => "#KIND# Japan-122 (#LD#)", start_day => 0, lank =>[0, 9999] , exclusion => $EXC_POP, target => "Japan", label_skip => 3, graph => "bars"},
	#	{ext => "#KIND# Japan 2weeks $TD", start_day => -21, lank =>[0, 9999] , exclusion => $EXC_POP, target => "Japan", label_skip => 1, graph => "bars"},
		{ext => "#KIND# US (#LD#)", start_day => 39,  lank =>[0, 100] , exclusion => "Others", target => "US", label_skip => 2, graph => "lines"},
		{ext => "#KIND# China (#LD#)", start_day => 0,  lank =>[0, 100] , exclusion => "Others", target => "China", label_skip => 2, graph => "lines"},
		],
	},
	FT => {
		func => \&ft,
		EXC => "Others",  # "Others,China,USA";
		ymin => 10,
		average_date => 7,
		graphp => [
		{ext => "#KIND# Japan and others $FT_TD", start_day => 0, lank =>[0, 999] , exclusion => $EXCLUSION, add_target => "Japan",
			target => "Japan,Korea- South,US,Spain,Italy,France,Germany,United Kingdom,Iran,Turkey,Belgium,Switzeland",
			label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
		{ext => "#KIND# TOP5 $FT_TD", start_day => 0, lank =>[0, 5] , exclusion => $EXCLUSION, target => "", 
			label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
		{ext => "#KIND# TOP10 $FT_TD", start_day => 0, lank =>[0, 10] , exclusion => $EXCLUSION, target => "", 
			label_skip => 7, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
		{ext => "#KIND# 10-20 $FT_TD", start_day => 0, lank =>[10, 19] , exclusion => $EXCLUSION, target => "",
			label_skip => 7, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
		{ext => "#KIND# Japn Koria $FT_TD", start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan,Korea- South",
			label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
		],
	},
	RT => {
		EXC => "Others",
		ymin => 10,
		ip => 5,
		lp => 8,
		average_date => 7,
		graphp => [
		{ext => "#KIND# Japan 01/23 $RT_TD", start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan", 
			label_skip => 2, graph => "lines"},
		{ext => "#KIND# Japan 03/01 $RT_TD", start_day => "03/01", lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan", 
			label_skip => 2, graph => "lines"},
		{ext => "#KIND# Japan 3weeks $RT_TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan",
			 label_skip => 1, graph => "lines",  ymin => 0},
		{ext => "#KIND# Germany 0301 $RT_TD",   start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany",
			 label_skip => 2, graph => "lines", },
		{ext => "#KIND# Germany 3weeks $RT_TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany",
			 label_skip => 1, graph => "lines", },
		{ext => "#KIND# Forcus area 01 3weeks $RT_TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany,US,Italy,Spain,France",
			 label_skip => 1, graph => "lines", },
		{ext => "#KIND# Focusing area from 0301 $RT_TD",   start_day => 39, lank =>[0, 99] , exclusion => $EXCLUSION, 
			target => "Russia,Canada,Ecuador,Brazil,India", label_skip => 3, graph => "lines", ymax => 10, },
		{ext => "#KIND# TOP 01-05 from 0301 $RT_TD",   start_day => 39, lank =>[0, 4] , exclusion => $EXCLUSION, target => "", 
			label_skip => 3, graph => "lines", ymax => 10, },
		{ext => "#KIND# TOP 06-10 from 0301 $RT_TD",   start_day => 39, lank =>[5, 9] , exclusion => $EXCLUSION, target => "", 
			label_skip => 3, graph => "lines", ymax => 10, },
		{ext => "#KIND# TOP 10 3w $RT_TD",   start_day => -21, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
			label_skip => 1, graph => "lines", ymax => "", },
		{ext => "#KIND# TOP 10 2w $RT_TD",   start_day => -14, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
			label_skip => 1, graph => "lines", ymax => "", },
		{ext => "#KIND# TOP 10 1w $RT_TD",   start_day => -7, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
			label_skip => 1, graph => "lines", ymax => "", },

		{ext => "#KIND# Japan  $RT_TD",   start_day => "03/01", lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan", 
			label_skip => 2, graph => "lines", },
		],
	},
};

#
#	Aggregate JH CCSE CSV FILE
#
my ($colum, $record , $start_day, $last_day);
my %JHCCSE = ();
sub	aggregate
{
	my ($mode, $aggr_mode, $src_file, $report_csvf, $graph_html) = @_;
	if(1 || ! defined $JHCCSE{$aggr_mode}){
		my $param = {
			input_file => $src_file,
			output_file => $report_csvf,
			aggr_mode	=> $aggr_mode,
			delimiter => $DLM,
		};
		($colum, $record , $start_day, $last_day) = jhccse::jhccse($param);
		$JHCCSE{$aggr_mode} = [$colum, $record , $start_day, $last_day];
	}
	return @{$JHCCSE{$aggr_mode}};
}

sub	download
{
	my ($info_path) = @_;
	system("(cd ../COVID-19; git pull origin master)");
}

sub	copy
{
	my ($info_path) = @_;
	my $BASE_DIR = $info_path->{base_dir};
	system("cp $BASE_DIR/*.csv $WIN_PATH");
}
1;
