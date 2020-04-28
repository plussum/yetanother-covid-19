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

if(! defined  $config::INFO_PATH->{$DATA_SOURCE}){
	print STDERR "No data source definiton for [$DATA_SOURCE] in confg.pm\n";
	exit(1);
}
my $INFO_PATH = $config::INFO_PATH->{$DATA_SOURCE};
my $plist = $INFO_PATH->{params}; 
#dp::dp Dumper $INFO_PATH;
dp::dp join(",", "DATA SOURCE:[$DATA_SOURCE] ", $INFO_PATH->{src}, "[" . $plist->{comment} . "]") . "\n";

if($COPY){
	my $copy = $plist->{copy};
	$copy->($INFO_PATH);
	exit(0);
}

if($DOWNLOAD){
	my $download = $plist->{download};
	$download->($INFO_PATH);
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
	POP => \&pop,
};

my $DLM = $plist->{DLM};
my $SOURCE_DATA = $INFO_PATH->{src};
foreach my $AGGR_MODE (@AGGR_LIST){
	foreach my $MODE (@MODE_LIST){
		foreach my $SUB_MODE (@SUB_MODE_LIST){
			dp::dp "AGGR_MODE[$AGGR_MODE]  MODE[$MODE] SUB_MODE:[$SUB_MODE]\n";

			next if($AGGR_MODE eq "POP" && $SUB_MODE ne "COUNT");
			my $SRC_FILE = $INFO_PATH->{$MODE};
			my $STG1_CSVF   = $config::CSV_PATH  . "/" . $INFO_PATH->{prefix} . join("_", $MODE, $AGGR_MODE) . ".csv.txt";
			
			my $STG2_CSVF = $config::CSV_PATH  . "/" . $INFO_PATH->{prefix} . join("_", $SUB_MODE, $AGGR_MODE) . ".csv.txt";
			my $HTMLF = $config::HTML_PATH . "/" . $INFO_PATH->{prefix} . join("_", $MODE, $SUB_MODE, $AGGR_MODE) . ".html";

			if($DEBUG){
				dp::dp "SRC_FILE:[$SRC_FILE]\n" ;
				dp::dp "STG1_CSVF:[$STG1_CSVF]\n";
				dp::dp "HTMLF:[$HTMLF]\n";
				dp::dp "STG2_CSVF:[$STG2_CSVF]\n";
			}
			my $aggregate = $plist->{aggregate};
			my $p = $plist->{$SUB_MODE};

			if(defined $FUNCS->{$SUB_MODE}){
				$FUNCS->{$SUB_MODE}->($p, $plist, $INFO_PATH, $MODE, $AGGR_MODE, $SRC_FILE, $STG1_CSVF, $HTMLF, $STG2_CSVF);
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
	my ($p, $plist, $infop, $mode, $aggr_mode, $src_file, $report_csvf, $graph_html, $sub_csvf) = @_;

	#dp::dp Dumper $p;

	#
	#	Load CCSE CSV
	#
	my $aggr_func = $plist->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($mode, $aggr_mode, $src_file, $report_csvf, $graph_html);

	#
	#	グラフとHTMLの作成
	#

	my $name = ($mode eq "NC") ? "NEW CASE" : "NEW DEATH"; 
	my $csvlist = {
		name => $name,
		csvf => $report_csvf, htmlf => $graph_html, kind => $mode,
		src => $infop->{src},
		src_url => $infop->{src_url},
	};

	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		params => $p->{graphp},
	);
	csvgpl::csvgpl(\%params);
}

#
#
#
sub	pop
{
	my ($p, $plist, $infop, $mode, $aggr_mode, $src_file, $report_csvf, $graph_html, $sub_csvf) = @_;

	#
	#	Load CCSE CSV
	#
	my $aggr_func = $plist->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($mode, $aggr_mode, $src_file, $report_csvf, $graph_html);

	#
	#	PARAMS for POP
	#
	my $name = ($mode eq "NC") ? "POP NEW CASE" : "POP NEW DEATH"; 
	my $csvlist = {
		name => $name,
		csvf => $report_csvf, htmlf => $graph_html, kind => $mode, srcf => $report_csvf,
		src => $infop->{src},
		src_url => $infop->{src_url},
	};

	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		params => $p->{graphp},
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
	my ($p, $plist, $infop, $mode, $aggr_mode, $src_file, $report_csvf, $graph_html, $sub_csvf) = @_;

	#
	#	Load CCSE CSV
	#
	my $aggr_func = $plist->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($mode, $aggr_mode, $src_file, $report_csvf, $graph_html);

	#
	#	Create FT CSV
	#
	my $THRESH_DAY = ($mode eq "NC") ? 9 : 5;	# 10 : 1

	my $FT_PARAM = {
		input_file => $report_csvf,
		output_file => $sub_csvf,
		average_date => $p->{average_date},
		thresh => $THRESH_DAY,
		delimiter => $DLM,
	};
	ft::ft($FT_PARAM);

	#
	#	グラフとHTMLの作成
	#
	my $guide = ft::exp_guide(2,10, 10, 'linecolor "#808080"');
   	my $FT_TD = "($record)";
    $FT_TD =~ s#/#.#g;
	my $name = ($mode eq "NC") ? "FT NEW CASE" : "FT NEW DEATH"; 
	my $csvlist = {
		name => $name,
		csvf => $sub_csvf, htmlf => $graph_html, kind => $mode, srcf => $report_csvf,
		src => $infop->{src},
		src_url => $infop->{src_url},
	};

	foreach my $gp (@{$p->{graphp}}){
		$gp->{ymin} = $p->{ymin};
		$gp->{guide} = $guide;
		$gp->{average_date} = $p->{average_date};
		$gp->{ext} =~ s/#FT_TD#/$FT_TD/;
	}

	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		params => $p->{graphp},
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
	my ($p, $plist, $infop, $mode, $aggr_mode, $src_file, $report_csvf, $graph_html, $sub_csvf) = @_;

	my $aggr_func = $plist->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($mode, $aggr_mode, $src_file, $report_csvf, $graph_html);

	my $RATE_PARAM = {
		input_file => $report_csvf,
		output_file => $sub_csvf,
		delimiter => $DLM,
		average_date => $p->{average_date},
		lp 		=> $p->{ip},	# 5 潜伏期間
		ip 		=> $p->{lp},	# 8 感染期間
	};
	rate::rate($RATE_PARAM);
	#dp::dp $REPORT_CSVF . "\n";

	#
	#	グラフとHTMLの作成
	#

	my $RT_TD = sprintf("ip(%d)lp(%d)moving avr(%d) (#LD#)", $p->{ip}, $p->{lp}, $p->{average_date});
	$RT_TD =~ s#/#.#g;

	my $R0_LINE = "1 with lines dt \"-\" title 'R0=1'";
	my $name = ($mode eq "NC") ? "RATE NEW CASE" : "RATE NEW DEATH"; 
	my $csvlist = { 
		name => $name,
		csvf => $sub_csvf, htmlf => $graph_html, kind => "NC",
		src => $infop->{src},
		src_url => $infop->{src_url},
	};

	foreach my $gp (@{$p->{graphp}}){
		$gp->{additional_plot} = $R0_LINE;
		$gp->{ext} =~ s/#RT_TD#/$RT_TD/;
	}
	my %params = (
		debug => $DEBUG,
		clp => $csvlist,
		params => $p->{graphp},
	);
	csvgpl::csvgpl(\%params);
}


