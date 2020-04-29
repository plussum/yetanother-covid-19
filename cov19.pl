#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、CSVとグラフを生成する
#
#	beoutbreakprepared
#	https://github.com/beoutbreakprepared/nCoV2019
#
#
#
##
#
# our $PARAMS = {			# MODULE PARETER		$mep
#    comment => "**** J.A.G JAPAN PARAMS ****",
#    src => "JAG JAPAN",
#	src_url => $src_url,
#    prefix => "jag_",
#    src_file => {
#		NC => $transaction,
#		ND => "",
#    },
#
#    new => \&new,
#    aggregate => \&aggregate,
#    download => \&download,
#    copy => \&copy,
#
#	COUNT => {			# FUNCTION PARAMETER		$funcp
#		EXEC => "",
#		graphp => [		# GPL PARAMETER				$gplp
#			{ext => "#KIND# Japan 01-05 (#LD#) #SRC#", start_day => "02/15",  lank =>[0, 4] , exclusion => $EXCLUSION, target => "", label_skip => 2, graph => "lines"},
#

use strict;
#use warnings;
#use lib qw(../gsfh);
use Data::Dumper;
use config;
use csvgpl;
use dp;
use params;
use ccse;
use who;
use jag;


#
#	初期化など
#
my $DEBUG = 0;
my $VERBOSE = 0;
my $MIN_TOTAL = 100;

my $WIN_PATH = $config::WIN_PATH;

my $SRC_FILE = "";
my $MODE = "";
my $DOWNLOAD = 0;
my $COPY = 0;

my @MODE_LIST = ();
my @SUB_MODE_LIST = ();
my @AGGR_LIST = ();
my $DATA_SOURCE = "ccse";

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$DOWNLOAD = 1 if(/-DL/i);
	$COPY = 1 if(/-copy/);

	$DATA_SOURCE = "ccse" if(/-ccse/);
	$DATA_SOURCE = "who" if(/-who/);
	$DATA_SOURCE = "jag" if(/-jag/);

	push(@MODE_LIST, "ND") if(/-ND/);
	push(@MODE_LIST, "NC") if(/-NC/);
	push(@SUB_MODE_LIST, "FT") if(/-FT/);
	push(@SUB_MODE_LIST, "RT") if(/-RT/);
	push(@AGGR_LIST, "POP") if(/-POP/);
	if(/-ALL/i){
		push(@MODE_LIST, "ND", "NC");
		push(@SUB_MODE_LIST, "COUNT", "FT", "RT");
		push(@AGGR_LIST, "DAY", "POP");
	}
}

my $mep = ""; 
$mep = ccse::new() if($DATA_SOURCE eq "ccse");
$mep = who::new()  if($DATA_SOURCE eq "who");
$mep = jag::new()  if($DATA_SOURCE eq "jag");
die "no package for $DATA_SOURCE\n" if(! $mep);


dp::dp join(",", "DATA SOURCE:[$DATA_SOURCE] ", $mep->{src}, "[" . $mep->{comment} . "]") . "\n";

if($COPY){
	my $copy = $mep->{copy};
	$copy->($mep);
	exit(0);
}

if($DOWNLOAD){
	my $download = $mep->{download};
	$download->($mep);
}	
if($#MODE_LIST < 0) {
	push(@MODE_LIST, "ND", "NC");
}
push(@AGGR_LIST, "DAY") if($#AGGR_LIST < 0);
push(@SUB_MODE_LIST, "COUNT") if($#SUB_MODE_LIST < 0);


#
#	Open File
#
my 	$FUNCS = {
	COUNT => \&daily,
	FT => \&ft,
	RT => \&rate,
	#POP => \&pop,
};

my $DLM = $mep->{DLM};
my $SOURCE_DATA = $mep->{src};
foreach my $AGGR_MODE (@AGGR_LIST){
	foreach my $MODE (@MODE_LIST){
		foreach my $SUB_MODE (@SUB_MODE_LIST){
			dp::dp "AGGR_MODE[$AGGR_MODE]  MODE[$MODE] SUB_MODE:[$SUB_MODE]\n";

			next if($AGGR_MODE eq "POP" && $SUB_MODE ne "COUNT");
			my $SRC_FILE = $mep->{src_file}{$MODE};
			my $STG1_CSVF   = $config::CSV_PATH  . "/" . $mep->{prefix} . join("_", $MODE, $AGGR_MODE) . ".csv.txt";
			
			my $STG2_CSVF = $config::CSV_PATH  . "/" . $mep->{prefix} . join("_", $SUB_MODE, $AGGR_MODE) . ".csv.txt";
			my $HTMLF = $config::HTML_PATH . "/" . $mep->{prefix} . join("_", $MODE, $SUB_MODE, $AGGR_MODE) . ".html";

			if($VERBOSE || $DEBUG){
				dp::dp "SRC_FILE:[$SRC_FILE]\n" ;
				dp::dp "STG1_CSVF:[$STG1_CSVF]\n";
				dp::dp "HTMLF:[$HTMLF]\n";
				dp::dp "STG2_CSVF:[$STG2_CSVF]\n";
			}

			if(defined $FUNCS->{$SUB_MODE}){
				if(! defined $mep->{$SUB_MODE}){
					print STDERR "NO GRAPH Parameter for $SOURCE_DATA -> $SUB_MODE\n";
					next;
				}
				my $funcp = {
					mep => $mep,
					funcp => $mep->{$SUB_MODE},

					mode => $MODE,
					aggr_mode => $AGGR_MODE,
					src_file => $SRC_FILE,
					stage1_csvf => $STG1_CSVF,
					stage2_csvf => $STG2_CSVF,
					htmlf => $HTMLF,
					dlm => $DLM,
				};
				$FUNCS->{$SUB_MODE}->($funcp);
			}
			else {
				print STDERR "No function defined for $SUB_MODE\n";
			}
		}
	}
}	

#
#
#
sub	daily 
{
	my ($fp) = @_;
	my $mep = $fp->{mep};

	#dp::dp "daily \n" ; # Dumper($fp);

	#
	#	Load CCSE CSV
	#
	my $aggr_func = $mep->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($fp);

	#
	#	グラフとHTMLの作成
	#

	#my $prefix = $mep->{prefix};
	my $name = ($fp->{mode} eq "NC") ? "NEW CASE" : "NEW DEATH"; 
	dp::dp "name: $name\n";
	my $csvlist = {
		name => $name,
		csvf => $fp->{stage1_csvf}, 
		htmlf => $fp->{htmlf},
		kind => $fp->{mode},
		src_file => $fp->{src_file},
		src => $mep->{src},
		src_url => $mep->{src_url},
	};

	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		mep => $mep,
		gplp => $fp->{funcp}{graphp},
	);
	#dp::dp "### daily: " . Dumper(%params) . "\n";
	csvgpl::csvgpl(\%params);
}

#
#
#
sub	pop
{
	my ($fp) = @_;
	my $mep = $fp->{mep};

	dp::dp "pop: \n" ; #  Dumper($fp) ;

	#
	#	Load CCSE CSV
	#
	my $aggr_func = $mep->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($fp);

	#
	#	PARAMS for POP
	#
	my $name = ($fp->{mode} eq "NC") ? "POP NEW CASE" : "POP NEW DEATH"; 
	dp::dp "NAME: $name \n";
	my $csvlist = {
		name => $name,
		csvf => $fp->{stage1_csvf}, 
		htmlf => $fp->{htmlf}, 
		kind => $fp->{mode},
		src_file => $fp->{src_file},
		src => $mep->{src},
		src_url => $mep->{src_url},
	};

	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		mep => $mep,
		gplp => $fp->{funcp}{graphp},
	);
	csvgpl::csvgpl(\%params);
}

#####################################
#
#	Finatial Times
#
#
#	定型のCSVから、Finantial Times方式のデータを生成
#
sub	ft
{
	my ($fp) = @_;
	my $mep = $fp->{mep};

	#
	#	Load CCSE CSV
	#
	my $aggr_func = $mep->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($fp);

	#
	#	Create FT CSV
	#
	my $THRESH_DAY = ($fp->{mode} eq "NC") ? 9 : 5;	# 10 : 1

	my $FT_PARAM = {
		input_file => $fp->{stage1_csvf},
		output_file => $fp->{stage2_csvf},
		average_date => $fp->{funcp}{average_date},
		thresh => $THRESH_DAY,
		delimiter => $mep->{DLM},
	};
	#dp::dp "FT_PARAM: " . Dumper $FT_PARAM;
	ft::ft($FT_PARAM);

	#
	#	グラフとHTMLの作成
	#
	my $guide = ft::exp_guide(2,10, 10, 'linecolor "#808080"');
   	my $FT_TD = "($record)";
    $FT_TD =~ s#/#.#g;
	my $name = ($fp->{mode} eq "NC") ? "FT NEW CASE" : "FT NEW DEATH"; 
	my $csvlist = {
		name => $name,
		csvf => $fp->{stage2_csvf},
		htmlf => $fp->{htmlf}, 
		kind => $fp->{mode},
		src_file => $fp->{src_file},
		src => $mep->{src},
		src_url => $mep->{src_url},
	};

	#dp::dp "### funcp " . Dumper ($fp->{funcp}{graphp}) . "\n";
	foreach my $gp (@{$fp->{funcp}{graphp}}){
		$gp->{ymin} = $fp->{funcp}{ymin};
		$gp->{guide} = $guide;
		$gp->{average_date} = $fp->{funcp}{average_date};
		$gp->{ext} =~ s/#FT_TD#/$FT_TD/;
		#dp::dp ">>>> gp: " . Dumper($gp) . "\n";
	}

	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		mep => $mep,
		gplp => $fp->{funcp}{graphp},
	);
	csvgpl::csvgpl(\%params);
}

#
#	定型のCSVから、再生産数 のデータを生成
#
#		t                  *
#		+----+-------------+
#		  ip       lp
#
#		R0 = ip * S[t+ip+lp] / sum(S[t+1..t+ip])
#	
#		source		https://qiita.com/oki_mebarun/items/e68b34b604235b1f28a1
#
sub	rate
{
	my ($fp) = @_;
	my $mep = $fp->{mep};

	my $aggr_func = $mep->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($fp);

	my $RATE_PARAM = {
		input_file => $fp->{stage1_csvf},
		output_file => $fp->{stage2_csvf},
		delimiter => $mep->{DLM},
		average_date => $fp->{funcp}{average_date},
		ip 		=> $fp->{funcp}{ip},
		lp 		=> $fp->{funcp}{lp},	
	};
	rate::rate($RATE_PARAM);

	#
	#	グラフとHTMLの作成
	#

	my $RT_TD = sprintf("ip(%d)lp(%d)mv-avr(%d) (#LD#)", $fp->{funcp}{ip}, $fp->{funcp}{lp}, $fp->{funcp}{average_date});
	dp::dp "RT_TD :" . $RT_TD. "\n";
	$RT_TD =~ s#/#.#g;

	my $R0_LINE = "1 with lines dt \"-\" title 'R0=1'";
	my $name = ($fp->{mode} eq "NC") ? "RATE NEW CASE" : "RATE NEW DEATH"; 
	my $csvlist = { 
		name => $name,
		csvf => $fp->{stage2_csvf}, 
		htmlf => $fp->{htmlf}, 
		kind => $fp->{mode},
		src_file => $fp->{src_file},
		src => $mep->{src},
		src_url => $mep->{src_url},
	};

	foreach my $gp (@{$fp->{funcp}{graphp}}){
		$gp->{additional_plot} = $R0_LINE;
		$gp->{ext} =~ s/#RT_TD#/$RT_TD/;
	}
	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		mep => $mep,
		gplp => $fp->{funcp}{graphp},
	);
	csvgpl::csvgpl(\%params);
}


