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
my $EXCLUSION = "Others,US";
my $CCSE_BASE_DIR = "/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series";



our $PARAMS = {			# MODULE PARETER        $mep
	comment => "**** CCSE PARAMS ****",
	src => "Johns Hopkins CSSE",
	src_url => "https://github.com/beoutbreakprepared/nCoV2019",
	prefix => "jhccse_",
	src_file => {
		NC => "$CCSE_BASE_DIR/time_series_covid19_confirmed_global.csv",
		ND => "$CCSE_BASE_DIR/time_series_covid19_deaths_global.csv",
		CC => "$CCSE_BASE_DIR/time_series_covid19_confirmed_global.csv",
		CD => "$CCSE_BASE_DIR/time_series_covid19_deaths_global.csv",
		NR  => "$CCSE_BASE_DIR/time_series_covid19_recovered_global.csv",
		CR => "$CCSE_BASE_DIR/time_series_covid19_recovered_global.csv",
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
		EXEC => "US",
		graphp => [		# GPL PARAMETER         $gplp					# Old version of graph parameter
			@params::PARAMS_COUNT, 
			{ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0, lank =>[0, 999], exclusion => $EXCLUSION, target => "Taiwan", label_skip => 7, graph => "lines"},
			{ext => "#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19], exclusion => $EXCLUSION, target => "China", label_skip => 7, graph => "lines"},
		],
		graphp_mode => {												# New version of graph pamaeter for each MODE
			NC => [
#    			{ext => "#KIND# #SRC# 1", start_day => 0,  end_day => 30, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 2", start_day => 0,  end_day => 45, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 3", start_day => 0,  end_day => 60, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 4", start_day => 0,  end_day => 75, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 5", start_day => 0,  end_day => 90, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 6", start_day => 0,  end_day => 105, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 7", start_day => 0,  end_day => 120, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 8", start_day => 0,  end_day => 135, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 9", start_day => 0,  end_day => 150, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 11", start_day => 0,  end_day => 165, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 12", start_day => 0,  end_day => 180, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 13", start_day => 0,  end_day => 195, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},
#    			{ext => "#KIND# #SRC# 14", start_day => 0,  end_day => 215, lank =>[0, 29] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", term_ysize => 600},

				@params::PARAMS_COUNT, 
				#{ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0, lank =>[0, 999], exclusion => $EXCLUSION, target => "Taiwan", label_skip => 3, graph => "lines"},
				#{ext => "#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19], exclusion => $EXCLUSION, target => "China", label_skip => 3, graph => "lines"},
			],
			ND => [
				@params::PARAMS_COUNT, 
				#{ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0, lank =>[0, 999], exclusion => $EXCLUSION, target => "Taiwan", label_skip => 3, graph => "lines"},
				#{ext => "#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19], exclusion => $EXCLUSION, target => "China", label_skip => 3, graph => "lines"},
			],
			CC => [
				 @params::ACCD_PARAMS, 
			],
			CD => [
				 @params::ACCD_PARAMS, 
			],
		},

	},
	FT => {
		EXC => "Others",  # "Others,China,USA";
		ymin => 10,
		average_date => 7,
		graphp => [
			@params::PARMS_FT
		],
	},
	ERN => {
		EXC => "Others",
		ip => 5,
		lp => 8,
		average_date => 7,
		graphp => [
			@params::PARMS_RT
		],
	},
	KV => {
		EXC => "Others",
		graphp => [
			@params::PARAMS_KV
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

	if(1 || ! defined $JHCCSE{$aggr_mode}){
		my $param = {
			mode => $fp->{mode},
			input_file => $fp->{src_file},
			output_file => $fp->{stage1_csvf},
			aggr_mode	=> $fp->{aggr_mode},
			delimiter => $fp->{dlm},
			data_start_col => 4,
			country_col => 1,
		};
		($colum, $record , $start_day, $last_day) = jhccse::jhccse($param);
		$JHCCSE{$aggr_mode} = [$colum, $record , $start_day, $last_day];
	}
	return @{$JHCCSE{$aggr_mode}};
}
	
1;
