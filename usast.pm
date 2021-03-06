#!/usr/bin/perl
#
#	src => "Johns Hopkins CSSE",
#	src_url => "https://github.com/beoutbreakprepared/nCoV2019",
#	prefix => "jhccse_",
#
#	Functions must define
#	new => \&new,
#	aggregate => \&aggregate,
#	download => \&download,
#	copy => \&copy,
#
#
package usast;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(usast);

use strict;
use warnings;
use Data::Dumper;
use config;
use csvgpl;
use jhccse;
use dp;
use params;

#
#	Initial 
#
my $DEBUG = 0;
my $DLM = $config::DLM;
my $WIN_PATH = $config::WIN_PATH;
my $infopath = $config::INFOPATH->{ccse} ;


#
#	Parameter set
#
my $EXCLUSION = "";
my $CCSE_BASE_DIR = "/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series";
my @usa_params = (
	{ext => "#KIND# TOP 10 (#LD#) #SRC#", start_day => 0, lank =>[0, 9], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP 10 (#LD#) #SRC#", start_day => 0, lank =>[0, 9], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", avr_date => 7},

	{ext => "#KIND# TOP 10 03/14 (#LD#) #SRC#", start_day => "03/14", lank =>[0, 9], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP 10 05/01(#LD#) #SRC#", start_day => "05/01", lank =>[0, 9], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},

	{ext => "#KIND# TOP 10 2month(#LD#) #SRC#", start_day => -62, lank =>[0, 9], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", avr_date => 7},
	{ext => "#KIND# TOP 11-20 2month(#LD#) #SRC#", start_day => -62, lank =>[10, 19], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", avr_date => 7},
	{ext => "#KIND# TOP 21-30 2month(#LD#) #SRC#", start_day => -62, lank =>[20, 29], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", avr_date => 7},
	{ext => "#KIND# TOP 31-40 2month(#LD#) #SRC#", start_day => -62, lank =>[30, 39], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", avr_date => 7},
	{ext => "#KIND# TOP 41-50 2month(#LD#) #SRC#", start_day => -62, lank =>[40, 49], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", avr_date => 7},

	{ext => "#KIND# TOP 10 2month(#LD#) #SRC#", start_day => -62, lank =>[0, 9], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP 11-20 2month(#LD#) #SRC#", start_day => -62, lank =>[10, 19], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP 21-30 2month(#LD#) #SRC#", start_day => -62, lank =>[20, 29], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP 31-40 2month(#LD#) #SRC#", start_day => -62, lank =>[30, 39], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP 41-50 2month(#LD#) #SRC#", start_day => -62, lank =>[40, 49], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},

	{ext => "#KIND# TOP 10 05/01 Arizona  (#LD#) #SRC#", start_day => "05/01", lank =>[0, 9], exclusion => $EXCLUSION, target => "Arizona", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP 10 05/01 Florida  (#LD#) #SRC#", start_day => "05/01", lank =>[0, 9], exclusion => $EXCLUSION, target => "Florida", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP 10 05/01 Oklahoma (#LD#) #SRC#", start_day => "05/01", lank =>[0, 9], exclusion => $EXCLUSION, target => "Oklahoma", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP 10 05/01 Oregon (#LD#) #SRC#", start_day => "05/01", lank =>[0, 9], exclusion => $EXCLUSION, target => "Oregon", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP 10 05/01 Texas (#LD#) #SRC#", start_day => "05/01", lank =>[0, 9], exclusion => $EXCLUSION, target => "Texas", label_skip => 3, graph => "lines"},

);

our $PARAMS = {			# MODULE PARETER        $mep
	comment => "**** CCSE PARAMS ****",
	src => "Johns Hopkins CSSE",
	src_url => "https://github.com/beoutbreakprepared/nCoV2019",
	prefix => "usast_",
	src_file => {
		NC => "$CCSE_BASE_DIR/time_series_covid19_confirmed_US.csv",
		ND => "$CCSE_BASE_DIR/time_series_covid19_deaths_US.csv",
		CC => "$CCSE_BASE_DIR/time_series_covid19_confirmed_US.csv",
		CD => "$CCSE_BASE_DIR/time_series_covid19_deaths_US.csv",
	#	NR  => "$CCSE_BASE_DIR/time_series_covid19_recovered_US.csv",
	#	CR => "$CCSE_BASE_DIR/time_series_covid19_recovered_US.csv",
	},
	base_dir => $CCSE_BASE_DIR,

	new => \&new,
	aggregate => \&aggregate,
	download => \&download,
	copy => \&copy,
	DLM => $DLM,

	SORT_BALANCE => {		# move to config.pm
		NC => [0, 0],
		ND => [0, 0],
	},
#	THRESH => {		# move to config.pm
#		NC => 0,
#		ND => 1,
#	},

	AGGR_MODE => {DAY => 1, POP => 1},									# Effective AGGR MODE
	#MODE => {NC => 1, ND => 1, CC => 1, CD => 1, NR => 1, CR => 1},		# Effective MODE

	COUNT => {			# FUNCTION PARAMETER    $funcp
		EXEC => "",
		graphp => [		# GPL PARAMETER         $gplp					# Old version of graph parameter
			{ext => "#KIND# TOP 10 (#LD#) #SRC#", start_day => 0, lank =>[0, 19], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
		],
		graphp_mode => {												# New version of graph pamaeter for each MODE
			NC => [
				@usa_params,
			],
			ND => [
				{ext => "#KIND# TOP 10 (#LD#) max=12000 #SRC#", start_day => 0, lank =>[0, 9], exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", ymax => 1200 },
				@usa_params,
			],
			CC => [
				@usa_params,
			],
			CD => [
				@usa_params,
			],
		},

	},
	FT => {
		EXC => "",  # "Others,China,USA";
		ymin => 10,
		average_date => 7,
		graphp => [
			{ext => "#KIND# USST TOP 20#FT_TD#", start_day => 0, lank =>[0, 19] , exclusion => "", add_target => "",
				target => "",label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
			{ext => "#KIND# USST 1-10#FT_TD#", start_day => 0, lank =>[0, 9] , exclusion => "", add_target => "",
				target => "",label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
			{ext => "#KIND# USST 11-20#FT_TD#", start_day => 0, lank =>[10, 19] , exclusion => "", add_target => "",
				target => "",label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
			{ext => "#KIND# USST 21-30#FT_TD#", start_day => 0, lank =>[20, 29] , exclusion => "", add_target => "",
				target => "",label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
			{ext => "#KIND# USST 31-40#FT_TD#", start_day => 0, lank =>[30, 39] , exclusion => "", add_target => "",
				target => "",label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
		],
	},
	ERN => {
		EXC => "",
		ip => 5,
		lp => 8,
		average_date => 7,
		graphp => [
			{ext => "#KIND# US 01/23 #RT_TD#", start_day => 0, lank =>[0, 9] , exclusion => "", target => "", label_skip => 2, graph => "lines"},
			{ext => "#KIND# US 2month #RT_TD#", start_day => -62, lank =>[0, 9] , exclusion => "", target => "", label_skip => 2, graph => "lines"},
			{ext => "#KIND# US 1month #RT_TD#", start_day => -31, lank =>[0, 9] , exclusion => "", target => "", label_skip => 2, graph => "lines"},
		],
	},
	KV => {
		EXC => "",
		graphp => [
			{ext => "#KIND# USA (#LD#) #SRC#", start_day => "03/15",  lank =>[0, 9], exclusion => "", target => "", label_skip => 3, graph => "lines"},
			{ext => "#KIND# USA 11-20(#LD#) #SRC#", start_day => "03/15",  lank =>[10, 19], exclusion => "", target => "", label_skip => 3, graph => "lines"},
			{ext => "#KIND# USA 2month(#LD#) #SRC#", start_day => -62,  lank =>[0, 9], exclusion => "", target => "", label_skip => 3, graph => "lines"},
			{ext => "#KIND# USA 11-20 2month(#LD#) #SRC#", start_day => -62,  lank =>[10, 19], exclusion => "", target => "", label_skip => 3, graph => "lines"},
			{ext => "#KIND# USA 1month(#LD#) #SRC#", start_day => -31,  lank =>[0, 9], exclusion => "", target => "", label_skip => 3, graph => "lines"},
			{ext => "#KIND# USA 11-20 1month(#LD#) #SRC#", start_day => -31,  lank =>[10, 19], exclusion => "", target => "", label_skip => 3, graph => "lines"},
		],
	},
};

#
#	For initial (first call from cov19.pl)
#
sub	new 
{
	return $PARAMS;
}

#
#	Download data from the data source
#
sub	download
{
	my ($info_path) = @_;
	system("(cd ../COVID-19; git pull origin master)");
	&copy($info_path);
	
}

#
#	Copy download data to Windows Path
#
sub	copy
{
	my ($info_path) = @_;
	my $BASE_DIR = $info_path->{base_dir};
	system("cp $BASE_DIR/*.csv $WIN_PATH/CSV");
}

#
#	Aggregate JH CCSE CSV FILE
#
my ($colum, $record , $start_day, $last_day);
my %JHCCSE = ();
sub	aggregate
{
	my ($fp) = @_;

	my $aggr_mode = $fp->{aggr_mode};
	#dp::dp "AGGREGATE: " . join("\n", $fp->{src_file}, $fp->{stage1_csvf}, $aggr_mode, $fp->{dlm}) . "\n";
	
	my $ds = ($fp->{mode} =~ /^[NC]D/) ? 12 : 11;
	if(1 || ! defined $JHCCSE{$aggr_mode}){
		my $param = {
			mode => $fp->{mode},
			input_file => $fp->{src_file},
			output_file => $fp->{stage1_csvf},
			aggr_mode	=> $fp->{aggr_mode},
			delimiter => $fp->{dlm},
			data_start_col => $ds,
			country_col => 10,
			us_sate => 1,
		};
		#dp::dp  "MODE: " . $fp->{mode} . "\n";
		($colum, $record , $start_day, $last_day) = jhccse::jhccse($param);
		$JHCCSE{$aggr_mode} = [$colum, $record , $start_day, $last_day];
	}
	return @{$JHCCSE{$aggr_mode}};
}
	
1;
