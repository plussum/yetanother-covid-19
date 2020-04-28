#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、CSVとグラフを生成する
#
#	beoutbreakprepared
#	https://github.com/beoutbreakprepared/nCoV2019
#
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
	$DATA_SOURCE = "japan" if(/-japan/);

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

my $plist = ""; 
$plist = ccse::new() if($DATA_SOURCE eq "ccse");
$plist = who::new()  if($DATA_SOURCE eq "who");
die "no package for $DATA_SOURCE\n" if(! $plist);


dp::dp join(",", "DATA SOURCE:[$DATA_SOURCE] ", $plist->{src}, "[" . $plist->{comment} . "]") . "\n";

if($COPY){
	my $copy = $plist->{copy};
	$copy->($plist);
	exit(0);
}

if($DOWNLOAD){
	my $download = $plist->{download};
	$download->($plist);
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

my $DLM = $plist->{DLM};
my $SOURCE_DATA = $plist->{src};
foreach my $AGGR_MODE (@AGGR_LIST){
	foreach my $MODE (@MODE_LIST){
		foreach my $SUB_MODE (@SUB_MODE_LIST){
			dp::dp "AGGR_MODE[$AGGR_MODE]  MODE[$MODE] SUB_MODE:[$SUB_MODE]\n";

			next if($AGGR_MODE eq "POP" && $SUB_MODE ne "COUNT");
			my $SRC_FILE = $plist->{src_file}{$MODE};
			my $STG1_CSVF   = $config::CSV_PATH  . "/" . $plist->{prefix} . join("_", $MODE, $AGGR_MODE) . ".csv.txt";
			
			my $STG2_CSVF = $config::CSV_PATH  . "/" . $plist->{prefix} . join("_", $SUB_MODE, $AGGR_MODE) . ".csv.txt";
			my $HTMLF = $config::HTML_PATH . "/" . $plist->{prefix} . join("_", $MODE, $SUB_MODE, $AGGR_MODE) . ".html";

			if($VERBOSE || $DEBUG){
				dp::dp "SRC_FILE:[$SRC_FILE]\n" ;
				dp::dp "STG1_CSVF:[$STG1_CSVF]\n";
				dp::dp "HTMLF:[$HTMLF]\n";
				dp::dp "STG2_CSVF:[$STG2_CSVF]\n";
			}

			if(defined $FUNCS->{$SUB_MODE}){
				if(! defined $plist->{$SUB_MODE}){
					print STDERR "NO GRAPH Parameter for $SOURCE_DATA -> $SUB_MODE\n";
					next;
				}
				my $funcp = {
					param => $plist,
					gparam => $plist->{$SUB_MODE},
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
	my $plist = $fp->{param};

	dp::dp "daily \n" ; # Dumper($fp);

	#
	#	Load CCSE CSV
	#
	my $aggr_func = $plist->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($fp);

	#
	#	グラフとHTMLの作成
	#

	my $aggr_mode = $fp->{aggr_mode};
	my $name = ($fp->{mode} eq "NC") ? "$aggr_mode NEW CASE" : "$aggr_mode NEW DEATH"; 
	my $csvlist = {
		name => $name,
		csvf => $fp->{stage1_csvf}, htmlf => $fp->{htmlf}, kind => $fp->{mode},
		src => $plist->{src},
		src_url => $plist->{src_url},
	};

	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		params => $fp->{gparam}{graphp},
	);
	csvgpl::csvgpl(\%params);
}

#
#
#
sub	pop
{
	my ($fp) = @_;
	my $plist = $fp->{param};

	dp::dp "pop: \n" ; #  Dumper($fp) ;

	#
	#	Load CCSE CSV
	#
	my $aggr_func = $plist->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($fp);

	#
	#	PARAMS for POP
	#
	my $name = ($fp->{mode} eq "NC") ? "POP NEW CASE" : "POP NEW DEATH"; 
	dp::dp "NAME: $name \n";
	my $csvlist = {
		name => $name,
		csvf => $fp->{stage1_csvf}, htmlf => $fp->{htmlf}, kind => $fp->{mode},
		src => $plist->{src},
		src_url => $plist->{src_url},
	};

	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		params => $fp->{gparam}{graphp},
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
	my $plist = $fp->{param};

	#
	#	Load CCSE CSV
	#
	my $aggr_func = $plist->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($fp);

	#
	#	Create FT CSV
	#
	my $THRESH_DAY = ($fp->{mode} eq "NC") ? 9 : 5;	# 10 : 1

	my $FT_PARAM = {
		input_file => $fp->{stage1_csvf},
		output_file => $fp->{stage2_csvf},
		average_date => $fp->{gparam}{average_date},
		thresh => $THRESH_DAY,
		delimiter => $plist->{DLM},
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
		csvf => $fp->{stage2_csvf}, htmlf => $fp->{htmlf}, kind => $fp->{mode},
		src => $plist->{src},
		src_url => $plist->{src_url},
	};

	#dp::dp "### gparam " . Dumper ($fp->{gparam}{graphp}) . "\n";
	foreach my $gp (@{$fp->{gparam}{graphp}}){
		$gp->{ymin} = $fp->{gparam}{ymin};
		$gp->{guide} = $guide;
		$gp->{average_date} = $fp->{gparam}{average_date};
		$gp->{ext} =~ s/#FT_TD#/$FT_TD/;
		#dp::dp ">>>> gp: " . Dumper($gp) . "\n";
	}

	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		params => $fp->{gparam}{graphp},
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
	my $plist = $fp->{param};

	my $aggr_func = $plist->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($fp);

	my $RATE_PARAM = {
		input_file => $fp->{stage1_csvf},
		output_file => $fp->{stage2_csvf},
		delimiter => $plist->{DLM},
		average_date => $fp->{gparam}{average_date},
		lp 		=> $plist->{ip},	# 5 潜伏期間
		ip 		=> $plist->{lp},	# 8 感染期間
	};
	rate::rate($RATE_PARAM);
	#dp::dp $REPORT_CSVF . "\n";

	#
	#	グラフとHTMLの作成
	#

	my $RT_TD = sprintf("ip(%d)lp(%d)moving avr(%d) (#LD#)", $plist->{ip}, $plist->{lp}, $fp->{gparam}{average_date});
	$RT_TD =~ s#/#.#g;

	my $R0_LINE = "1 with lines dt \"-\" title 'R0=1'";
	my $name = ($fp->{mode} eq "NC") ? "RATE NEW CASE" : "RATE NEW DEATH"; 
	my $csvlist = { 
		name => $name,
		csvf => $fp->{stage2_csvf}, htmlf => $fp->{htmlf}, kind => $fp->{mode},
		src => $plist->{src},
		src_url => $plist->{src_url},
	};

	foreach my $gp (@{$fp->{gparam}{graphp}}){
		$gp->{additional_plot} = $R0_LINE;
		$gp->{ext} =~ s/#RT_TD#/$RT_TD/;
	}
	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		params => $fp->{gparam}{graphp},
	);
	csvgpl::csvgpl(\%params);
}


