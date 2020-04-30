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
#use ft;
#use rate;


#
#	初期化など
#
my $DEBUG = 0;
my $DLM = $config::DLM;
my $WIN_PATH = $config::WIN_PATH;

my $EXCLUSION = "Others,US";
my $EXC_POP = "San Marino,Holy See";
my $FT_TD = "#FT_TD#";
my $RT_TD = "#RT_TD#"; #"ip($ip)lp($lp)moving avr($average_date) (#LD#) src $SOURCE_DATA";
my $infopath = $config::INFOPATH->{ccse} ;

my $CCSE_BASE_DIR = "/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series";

our $PARAMS = {			# MODULE PARETER        $mep
	comment => "**** CCSE PARAMS ****",
	src => "Johns Hopkins CSSE",
	src_url => "https://github.com/beoutbreakprepared/nCoV2019",
	prefix => "jhccse_",
	src_file => {
		NC => "$CCSE_BASE_DIR/time_series_covid19_confirmed_global.csv",
		ND => "$CCSE_BASE_DIR/time_series_covid19_deaths_global.csv",
	},
	base_dir => $CCSE_BASE_DIR,

	new => \&new,
	aggregate => \&aggregate,
	download => \&download,
	copy => \&copy,
	DLM => $DLM,

	AGGR_MODE => {DAY => 1, POP => 1},
	DATA_KIND => {NC => 1, ND => 1},		#

	COUNT => {			# FUNCTION PARAMETER    $funcp
		EXEC => "US",
		graphp => [		# GPL PARAMETER         $gplp
			@params::PARAMS_COUNT, 
			{ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0, lank =>[0, 999], exclusion => $EXCLUSION, target => "Taiwan", label_skip => 3, graph => "lines"},
			{ext => "#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19], exclusion => $EXCLUSION, target => "China", label_skip => 3, graph => "lines"},
		],
	},
	FT => {
		EXC => "Others",  # "Others,China,USA";
		ymin => 10,
		average_date => 7,
		graphp => [
			@params::PARMS_FT
		],
	},
	RT => {
		EXC => "Others",
		ip => 5,
		lp => 8,
		average_date => 7,
		graphp => [
			@params::PARMS_RT
		],
	},
};

sub	new 
{
	return $PARAMS;
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
			input_file => $fp->{src_file},
			output_file => $fp->{stage1_csvf},
			aggr_mode	=> $fp->{aggr_mode},
			delimiter => $fp->{dlm},
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
	&copy($info_path);
	
}

sub	copy
{
	my ($info_path) = @_;
	my $BASE_DIR = $info_path->{base_dir};
	system("cp $BASE_DIR/*.csv $WIN_PATH/CSV");
}
1;
