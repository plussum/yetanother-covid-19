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
use jhccse;
use dp;
use params;
use ft;
use rate;


#
#	初期化など
#
my $DEBUG = 0;
my $MIN_TOTAL = 100;
my $DLM = ",";

my $WIN_PATH = $config::WIN_PATH;
my $INFO_PATH = $config::INFO_PATH->{ccse};

my $SRC_FILE = "";
my $MODE = "";
my $DOWNLOAD = 0;

my @MODE_LIST = ();
my @SUB_MODE_LIST = ();
my @AGGR_LIST = ();

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$DOWNLOAD = 1 if(/-DL/i);

	push(@MODE_LIST, "ND") if(/-ND/);
	push(@MODE_LIST, "NC") if(/-NC/);
	push(@SUB_MODE_LIST, "FT") if(/-FT/);
	push(@SUB_MODE_LIST, "RT") if(/-RT/);
	push(@AGGR_LIST, "POP") if(/-POP/);
	if(/-ALL/i){
		push(@MODE_LIST, "ND", "NC");
		push(@SUB_MODE_LIST, "FT", "RT", "POP");
	}
	if(/-copy/){
		my $BASE_DIR = $INFO_PATH->{base_dir};
		system("cp $BASE_DIR/*.csv $WIN_PATH");
		exit(0);
	}
}
if($DOWNLOAD){
	system("(cd ../COVID-19; git pull origin master)");
}	
if($#MODE_LIST < 0) {
	push(@MODE_LIST, "ND", "NC");
}
push(@AGGR_LIST, "") if($#AGGR_LIST < 0);
push(@SUB_MODE_LIST, "") if($#SUB_MODE_LIST < 0);

#
#	Open File
#
my $SOURCE_DATA = $INFO_PATH->{src};
foreach my $AGGR_MODE (@AGGR_LIST){
	dp::dp "AGGR_MODE: $AGGR_MODE\n";
	foreach my $MODE (@MODE_LIST){
		dp::dp "MODE: $MODE\n";
		foreach my $SUB_MODE (@SUB_MODE_LIST){
			dp::dp "AGGR_MODE[$AGGR_MODE]  MODE[$MODE] SUB_MODE:[$SUB_MODE]\n";
			my $SRC_FILE = $INFO_PATH->{$MODE};
			my $STG1_CSVF   = $config::CSV_PATH  . "/" . $INFO_PATH->{prefix} . $MODE . $AGGR_MODE . ".csv.txt";
			
			my $STG2_CSVF = $config::CSV_PATH  . "/" . $INFO_PATH->{prefix} . $SUB_MODE . $AGGR_MODE . ".csv.txt";
			my $HTMLF = $config::HTML_PATH . "/" . $INFO_PATH->{prefix} . $MODE . $SUB_MODE . $AGGR_MODE . ".html";

			if($DEBUG){
				dp::dp "SRC_FILE:[$SRC_FILE]\n" ;
				dp::dp "STG1_CSVF:[$STG1_CSVF]\n";
				dp::dp "HTMLF:[$HTMLF]\n";
				dp::dp "STG2_CSVF:[$STG2_CSVF]\n";
			}

			&daily($MODE, $AGGR_MODE, $SRC_FILE, $STG1_CSVF, $HTMLF, $STG2_CSVF) if($SUB_MODE eq "");
			&ft  ($MODE, $AGGR_MODE, $SRC_FILE, $STG1_CSVF, $HTMLF, $STG2_CSVF) if($SUB_MODE eq "FT");
			&rate($MODE, $AGGR_MODE, $SRC_FILE, $STG1_CSVF, $HTMLF, $STG2_CSVF) if($SUB_MODE eq "RT");
		}
	}
}	

#
#
#
sub	daily 
{
	my ($mode, $aggr_mode, $src_file, $report_csvf, $graph_html, $sub_csvf) = @_;

	#
	#	Load CCSE CSV
	#
	my ($colum, $record , $start_day, $last_day) = &aggregate($mode, $aggr_mode, $src_file, $report_csvf, $graph_html);

	#
	#	グラフとHTMLの作成
	#

	my $TD = "($last_day) $SOURCE_DATA";
	$TD =~ s#/#.#g;

	#my $EXCLUSION = "Others,China,USA";
	my $EXCLUSION = "Others,US";
	#
	#	
#	{et => "EOD"},		End of Data  そこまでで処理をやめたいとき 
	#
	my @LOCAL_PARAMS = (
		{ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0, lank =>[0, 999], exclusion => $EXCLUSION, target => "Taiwan", label_skip => 3, graph => "lines"},
		{ext => "#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19], exclusion => $EXCLUSION, target => "China", label_skip => 3, graph => "lines"},
	);
	my @PARAMS = (@params::COMMON_PARAMS , @LOCAL_PARAMS);

	my $src_url = $INFO_PATH->{src_url};
	my $src_ref = "<a href=\"$src_url\">$src_url</a>";   
	my @csvlist = (
		{ name => "COV19 CASES NEW",  csvf => $report_csvf, htmlf => $graph_html, kind => "NC", src_ref => $src_ref},
		{ name => "COV19 DEATHS NEW", csvf => $report_csvf, htmlf => $graph_html, kind => "ND", src_ref => $src_ref},
	);
	foreach my $clp (@csvlist){
	   next if($clp->{kind} ne $mode); 
		my %params = (
			debug => $DEBUG,
			clp => $clp,
			params => \@PARAMS,
		);
		csvgpl::csvgpl(\%params);
	}
}

#
#
#
sub	pop
{
	my ($mode, $aggr_mode, $src_file, $report_csvf, $graph_html, $sub_csvf) = @_;

	#
	#	Load CCSE CSV
	#
	my ($colum, $record , $start_day, $last_day) = &aggregate($mode, $aggr_mode, $src_file, $report_csvf, $graph_html);

	#
	#	PARAMS for POP
	#
	my $EXC_POP = "San Marino,Holy See";
	my @PARAMS_POP = (
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

	);
	my $src_url = $INFO_PATH->{src_url};
	my $src_ref = "<a href=\"$src_url\">$src_url</a>";   
	my @csvlist = (
		{ name => "COV19 CASES NEW(POP)",  csvf => $report_csvf, htmlf => $graph_html, kind => "NC", src_ref => $src_ref},
		{ name => "COV19 DEATHS NEW(POP)", csvf => $report_csvf, htmlf => $graph_html, kind => "ND", src_ref => $src_ref},
	);

	foreach my $clp (@csvlist){
	   next if($clp->{kind} ne $mode); 
		my %params = (
			debug => $DEBUG,
			#win_path => $WIN_PATH,
			clp => $clp,
			params => \@PARAMS_POP,
			#data_rel_path => "cov_data",
		);
		csvgpl::csvgpl(\%params);
	}
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
	my ($mode, $aggr_mode, $src_file, $report_csvf, $graph_html, $sub_csvf) = @_;

	#
	#	Load CCSE CSV
	#
	my ($colum, $record , $start_day, $last_day) = &aggregate($mode, $aggr_mode, $src_file, $report_csvf, $graph_html);

	#
	#	Create FT CSV
	#
	my $THRESH_DAY = ($mode eq "NC") ? 9 : 5;	# 10 : 1
	dp::dp "### THRESH_DAY $THRESH_DAY\n";

	my $FT_PARAM = {
		input_file => $report_csvf,
		output_file => $sub_csvf,
		average_day => 7,
		thresh => $THRESH_DAY,
		delimiter => ",",
	};
	ft::ft($FT_PARAM);

	#
	#	グラフとHTMLの作成
	#
	my $TD = "($record) $SOURCE_DATA";
	$TD =~ s#/#.#g;
	my $guide = ft::exp_guide(2,10, 10, 'linecolor "#808080"');
	my $ymin = '10';

	my $EXCLUSION = "Others"; # "Others,China,USA";
	my @PARAMS = (
		{ext => "#KIND# Japan and others $TD", start_day => 0, lank =>[0, 999] , exclusion => $EXCLUSION, add_target => "Japan",
				target => "Japan,Korea- South,US,Spain,Italy,France,Germany,United Kingdom,Iran,Turkey,Belgium,Switzeland",
				label_skip => 2, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600, ft => 1,  ymin => $ymin, additional_plot => $guide},
		{ext => "#KIND# TOP5 $TD", start_day => 0, lank =>[0, 5] , exclusion => $EXCLUSION, 
			target => "", label_skip => 2, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600, 
			ft => 1, ymin => $ymin, additional_plot => $guide},
		{ext => "#KIND# TOP10 $TD", start_day => 0, lank =>[0, 10] , exclusion => $EXCLUSION, target => "", 
			label_skip => 7, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600,
			 ft => 1, ymin => $ymin, additional_plot => $guide},
		{ext => "#KIND# 10-20 $TD", start_day => 0, lank =>[10, 19] , exclusion => $EXCLUSION, 
			target => "", label_skip => 7, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600,
			 ft => 1, ymin => $ymin, additional_plot => $guide},
		{ext => "#KIND# Japn Koria $TD", start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, 
			target => "Japan,Korea- South", label_skip => 2, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600, 
			ft => 1, ymin => $ymin, additional_plot => $guide},
	);

	my @csvlist = (
		{ name => "FT NEW CASES", csvf => $sub_csvf, htmlf => $graph_html, kind => "NC"},
		{ name => "FT NEW DEATHES", csvf => $sub_csvf, htmlf => $graph_html, kind => "ND"},
	);

	foreach my $clp (@csvlist){
		next if($mode ne $clp->{kind});
		my %params = (
			debug => $DEBUG,
			#win_path => $WIN_PATH,
			#data_rel_path => "cov_data",
			clp => $clp,
			params => \@PARAMS,
		);
		csvgpl::csvgpl(\%params);
	}
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
	my ($mode, $aggr_mode, $src_file, $report_csvf, $graph_html, $sub_csvf) = @_;

	my ($colum, $record , $start_day, $last_day) = &aggregate($mode, $aggr_mode, $src_file, $report_csvf, $graph_html);


	my $ip = 5;			# 5 潜伏期間
	my $lp = 10;			# 8 感染期間
	my $average_date = 7;
	my $RATE_PARAM = {
		input_file => $report_csvf,
		output_file => $sub_csvf,
		delimiter => $DLM,
		average_date => $average_date,
		lp 		=> $ip,	# 5 潜伏期間
		ip 		=> $lp,	# 8 感染期間
	};
	rate::rate($RATE_PARAM);
	#dp::dp $REPORT_CSVF . "\n";

	#
	#	グラフとHTMLの作成
	#

	my $TD = "ip($ip)lp($lp)moving avr($average_date) (#LD#) src $SOURCE_DATA";
	$TD =~ s#/#.#g;

	my $EXCLUSION = "Others";
	my $R0_LINE = "1 with lines dt \"-\" title 'R0=1'";
	my @PARAMS = (
		{ext => "#KIND# Japan 01/23 $TD", start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan", 
			label_skip => 2, graph => "lines", additional_plot => $R0_LINE},
		{ext => "#KIND# Japan 03/01 $TD", start_day => "03/01", lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan", 
			label_skip => 2, graph => "lines", additional_plot => $R0_LINE},
		{ext => "#KIND# Japan 3weeks $TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan",
			 label_skip => 1, graph => "lines", additional_plot => $R0_LINE, ymin => 0},
		{ext => "#KIND# Germany 0301 $TD",   start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany",
			 label_skip => 2, graph => "lines", additional_plot => $R0_LINE},
		{ext => "#KIND# Germany 3weeks $TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany",
			 label_skip => 1, graph => "lines", additional_plot => $R0_LINE},
		{ext => "#KIND# Forcus area 01 3weeks $TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany,US,Italy,Spain,France",
			 label_skip => 1, graph => "lines", additional_plot => $R0_LINE},
		{ext => "#KIND# Focusing area from 0301 $TD",   start_day => 39, lank =>[0, 99] , exclusion => $EXCLUSION, 
			target => "Russia,Canada,Ecuador,Brazil,India", label_skip => 3, graph => "lines", ymax => 10, additional_plot => $R0_LINE},
		{ext => "#KIND# TOP 01-05 from 0301 $TD",   start_day => 39, lank =>[0, 4] , exclusion => $EXCLUSION, target => "", 
			label_skip => 3, graph => "lines", ymax => 10, additional_plot => $R0_LINE},
		{ext => "#KIND# TOP 06-10 from 0301 $TD",   start_day => 39, lank =>[5, 9] , exclusion => $EXCLUSION, target => "", 
			label_skip => 3, graph => "lines", ymax => 10, additional_plot => $R0_LINE},
		{ext => "#KIND# TOP 10 3w $TD",   start_day => -21, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
			label_skip => 1, graph => "lines", ymax => "", additional_plot => $R0_LINE},
		{ext => "#KIND# TOP 10 2w $TD",   start_day => -14, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
			label_skip => 1, graph => "lines", ymax => "", additional_plot => $R0_LINE},
		{ext => "#KIND# TOP 10 1w $TD",   start_day => -7, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
			label_skip => 1, graph => "lines", ymax => "", additional_plot => $R0_LINE},

		{ext => "#KIND# Japan  $TD",   start_day => "03/01", lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan", 
			label_skip => 2, graph => "lines", additional_plot => $R0_LINE},
	);
	my $src_url = $INFO_PATH->{src_url};
	my $src_ref = "<a href=\"$src_url\">$src_url</a>";
	my @csvlist = (
		{ name => "RATE NEW CASE", csvf => $sub_csvf, htmlf => $graph_html, kind => "NC", src_ref => $src_ref, srcf => $report_csvf },
	    { name => "RATE NEW DETH", csvf => $sub_csvf, htmlf => $graph_html, kind => "ND", src_ref => $src_ref, srcf => $report_csvf},
	);

	foreach my $clp (@csvlist){
		next if($mode ne $clp->{kind});
		dp::dp "##### SRC:[" . $clp->{srcf} . "]\n";
		my %params = (
			debug => $DEBUG,
			win_path => $WIN_PATH,
			data_rel_path => "cov_data",
			clp => $clp,
			params => \@PARAMS,
		);
		csvgpl::csvgpl(\%params);
	}

}


#
#	Aggregate JH CCSE CSV FILE
#
my ($colum, $record , $start_day, $last_day);
my %JHCCSE = ();
sub	aggregate
{
	my ($mode, $aggr_mode, $src_file, $report_csvf, $graph_html) = @_;
	if(! defined $JHCCSE{$aggr_mode}){
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
