#!/usr/bin/perl
#
#	Download COVID-19 data and generate graphs
#		Require gnuplot
#
#	cov19.pl [ccse who jag jagtotal] 
#		-NC 		New cases
#		-ND 		New deathes
#		-NR			New recovers
#		-CC			Cumelative cases toll
#		-CD			Cumelative deathes toll
#		-CR			Cumelative recovers
#
#		--POP		count/population (M)
#		--FT		Finatial Times like graph
#		--ERN		Effective reproduction number
#
#		-dl			Download data
#
#		-full		do all all data srouces and functions 
#		-FULL		-full with download
#
#	cov19.pl -> ccse	 ccse.pm 	John Hopkins univ. ccse
#			 -> who		 who.pm		WHO situation report
#			 -> jag		 jag.pm		J.A.G Japan data of Japan
#			 -> jagtotal jagtotal.pm	Total of all prefectures on J.A.A Japan 
#			 -> tko		 tko.pm		Japan data from Tokyo Open Data
#			 -> ku		 tkoku.pm	Tokyo City, Town data from Tokoto(Shinjyukuku)
#			 -> usa		 usa.pm		US States data
#			 -> usast	 usast.pm	US city, town data
#			 -> tkpos	 tkpos.pl	Tokyo Positive Rate, server etc
#			 -> tkage	 tkoage.pm	Tokyo age based data
#
#	AGGR_MODE
#		DAY				Daily count of the source data
#		POP				Daily count / population (M)
#
#	SUB_MODE
#		COUNT			Simply count
#		FT(ft.pm)		Finatial Times like 
#		ERN(ern.pm)		Effective reproduction number
#
#	MODE
#		NC				New Cases
#		ND				New Deaths
#		NR				New Recoverd
#		CC				Ccumulative Cases
#		CD				Ccumulative Deatheas
#		CR				Ccumulative Deatheas
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
use jagtotal;
use ft;
use ern;
use kvalue;
use usa;
use usast;
use tko;
use tkoku;
use tkoage;

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
my $FULL_SOURCE = 0;
my $UPLOAD = 0;

my @MODE_LIST = ();
my @SUB_MODE_LIST = ();
my @AGGR_LIST = ();
my $DATA_SOURCE = "ccse";
my @FULL_DATA_SOURCES = qw (tkage ku tko ccse tkpos jag usast usa who jagtotal);
#my @FULL_DATA_SOURCES = qw (ku);

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];

	$DATA_SOURCE = "ccse" if(/^ccse/i);
	$DATA_SOURCE = "who" if(/^who/i);
	$DATA_SOURCE = "jag" if(/^jag/i);
	$DATA_SOURCE = "jagtotal" if(/^jagtotal/i);
	$DATA_SOURCE = "usast" if(/^usast/i);
	$DATA_SOURCE = "usa" if(/^usa$/i);
	$DATA_SOURCE = "tko" if(/^tko$/i);
	$DATA_SOURCE = "ku" if(/^ku$/i);
	$DATA_SOURCE = "tkpos" if(/^tkpos$/i);
	$DATA_SOURCE = "tkage" if(/^tko*age$/i);


	if(/-debug/i){
		$DEBUG = 1;
	}
	elsif(/-copy/){
		$COPY = 1; 
	}
	elsif(/-DL/i){
		$DOWNLOAD = 1;
	}
	elsif(/-UL/i || /-upload/i){
		$UPLOAD = 1;
	}
	elsif(/-FULL/i){
		$FULL_SOURCE = $_ if(/-FULL/i);
	}
	elsif(/-tokyo/){
		system("./tokyo.pl -DL; tokyo.pl -av7");
		exit(0);
	}
	elsif(/-all/){
		push(@MODE_LIST, "ND", "NC", "CC", "CD", "NR", "CR");
		push(@SUB_MODE_LIST, "COUNT", "FT", "ERN", "KV");
		push(@AGGR_LIST, "DAY", "POP");
	}
	elsif(/^-[A-Za-z]/){
		s/^-//;
		push(@MODE_LIST, $_);
	}
	if(/^--[A-Za-z]/){
		s/^--//;
		if(/POP/i){
			push(@AGGR_LIST, $_);
		}
		else {
			push(@SUB_MODE_LIST, $_);
		}
	}

}
if($FULL_SOURCE){
	my $dl = "-DL" if($FULL_SOURCE =~ /FULL/);
	foreach my $src (@FULL_DATA_SOURCES){
		$_ = $src;
		my $d = (/jtagtotal|usa|tkpos/) ? "" : $dl;
		my $cmd = "$0 $src -all $d";
		dp::dp "system: " . $cmd . "\n";
		my $rc = system($cmd);
		$rc = $rc >> 8;
		dp::dp "RETURN CODE [$rc]: $cmd\n";
		exit 1 if($rc > 0);
	}
	system("./tokyo.pl -DL; tokyo.pl -av7");
	system("./tokyo.pl -av7");
	system("./genindex.pl");
	system("$0 -upload");
	exit(0);
}
if($UPLOAD){		# upload web data to github.io
	dp::dp "UPLOAD github.io\n";
	system("./upload.pl");
	exit(0);
}

my $mep = ""; 
$mep = ccse::new() if($DATA_SOURCE eq "ccse");
$mep = usa::new() if($DATA_SOURCE eq "usa");
$mep = usast::new() if($DATA_SOURCE eq "usast");
$mep = who::new()  if($DATA_SOURCE eq "who");
$mep = jag::new()  if($DATA_SOURCE eq "jag");
$mep = jagtotal::new()  if($DATA_SOURCE eq "jagtotal");
$mep = tko::new()  if($DATA_SOURCE eq "tko");
$mep = tkoku::new()  if($DATA_SOURCE eq "ku");
$mep = tkoage::new()  if($DATA_SOURCE eq "tkage");

if($DATA_SOURCE eq "tkpos"){
	my $d = ($DOWNLOAD) ? "-DL" : "";
	system("./tokyo.pl $d");
	exit 0;
}
die "no package for $DATA_SOURCE\n" if(! $mep);


dp::dp join(",", "DATA SOURCE:[$DATA_SOURCE] ", $mep->{src}, "[" . $mep->{comment} . "]") . "\n" if($DEBUG);

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
	ERN => \&ern,
	KV => \&kv,
	#POP => \&pop,
};

my $DLM = $mep->{DLM};
my $SOURCE_DATA = $mep->{src};

dp::dp join(",", @AGGR_LIST) . "\n";
foreach my $AGGR_MODE (@AGGR_LIST){
	dp::dp "$DATA_SOURCE: AGGR_MODE[$AGGR_MODE] \n";
	if(! csvlib::valdef($mep->{AGGR_MODE}{$AGGR_MODE},"")){
		dp::dp "no function defined: $DATA_SOURCE: AGGR_MODE[$AGGR_MODE]\n";
		next;
	}

	foreach my $MODE (@MODE_LIST){
		dp::dp "$DATA_SOURCE: AGGR_MODE[$AGGR_MODE]  MODE[$MODE]\n";
		if(! csvlib::valdef($mep->{src_file}{$MODE},"")){
			dp::dp "no function defined: $DATA_SOURCE: MODE[$MODE]\n";
			next;
		}
			
		foreach my $SUB_MODE (@SUB_MODE_LIST){
			dp::dp "$DATA_SOURCE: AGGR_MODE[$AGGR_MODE]  MODE[$MODE] SUB_MODE:[$SUB_MODE]\n";
			next if($AGGR_MODE eq "POP" && $SUB_MODE ne "COUNT");		# POP affect only COUNT (no FT, ERN)
			next if($SUB_MODE eq "ERN" && $MODE eq "ND");				# Newdeath does not make sense for ERN
			next if($SUB_MODE ne "COUNT" && $MODE =~ /^C/);				# Only count for CC, CD 
			next if($SUB_MODE eq "KV" && $MODE ne "NC");				# Newdeath does not make sense for ERN

			next if(!defined $mep->{src_file}{$MODE});

			my $SRC_FILE = $mep->{src_file}{$MODE};
			my $STG1_CSVF   = $config::CSV_PATH  . "/" . $mep->{prefix} . join("_", $MODE, $AGGR_MODE) . ".csv.txt";
			
			my $STG2_CSVF = $config::CSV_PATH  . "/" . $mep->{prefix} . join("_", $MODE, $SUB_MODE, $AGGR_MODE) . ".csv.txt";
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
					src => $DATA_SOURCE,
					mode => $MODE,
					sub_mode => $SUB_MODE,
					aggr_mode => $AGGR_MODE,

					mep => $mep,
					funcp => $mep->{$SUB_MODE},

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
exit 0;

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
	my $mode = $fp->{mode};
	my $aggr_mode = $fp->{aggr_mode};
	my $name = join("-", csvlib::valdef($config::MODE_NAME->{$mode}, " $mode "), $fp->{sub_mode}, $aggr_mode) ;
	dp::dp "[$mode] $name\n";

	my $m = csvlib::valdef($mep->{AGGR_MODE}{$aggr_mode}, 0);
	$name .= "*$m" . "days" if($m > 1);
	my $csvlist = {
		name => $name, 
		csvf => $fp->{stage1_csvf}, 
		htmlf => $fp->{htmlf},
		kind => $fp->{mode},
		src_file => $fp->{src_file},
		src => $mep->{src},
		src_url => $mep->{src_url},
	};
	my $funcp = $fp->{funcp};
	my $mode = $fp->{mode};
	my $graphp = csvlib::valdef($funcp->{graphp_mode}{$mode}, $funcp->{graphp});

	#dp::dp Dumper $graphp;

	my %params = (
		debug => $DEBUG,
		src => $fp->{src},
		clp => $csvlist,
		fp => $fp,
		mep => $mep,
		gplp => $graphp,	# $fp->{funcp}{graphp},
		aggr_mode => $fp->{aggr_mode},
		csv_aggr_mode => (defined $mep->{csv_aggr_mode} ? $mep->{csv_aggr_mode} : ""),
		sort_balance => 0.5,
		sort_wight => 0.01,
	);
	#dp::dp "### daily: " . Dumper(%params) . "\n";
	csvgpl::csvgpl(\%params);
}

#
#	現在は、popを使っていないが、将来的に、分離する可能性があるので、タグだけ残しておく
#
sub	pop_not_in_use
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
	my $mode = $fp->{mode};
	my $name = join("-", csvlib::valdef($config::MODE_NAME->{$mode}, " $mode "), $fp->{sub_mode}, $fp->{aggr_mode}) ;

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
		src => $fp->{src},
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
	my $mode = $fp->{mode};

	#
	#	Load CCSE CSV
	#
	my $aggr_func = $mep->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($fp);

	#
	#	Create FT CSV
	#
	#dp::dp "THRESH($mode): [" . $config::THRESH_FT->{$mode} . "]\n";	

	my $FT_PARAM = {
		input_file => $fp->{stage1_csvf},
		output_file => $fp->{stage2_csvf},
		average_date => $fp->{funcp}{average_date},
		thresh => $config::THRESH_FT->{$mode},	# ($fp->{mode} eq "NC") ? 9 : 5;	# 10 : 1
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
	my $mode = $fp->{mode};
	my $name = join("-", csvlib::valdef($config::MODE_NAME->{$mode}, " $mode "), $fp->{sub_mode}, $fp->{aggr_mode}) ;

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
		src => $fp->{src},
		clp => $csvlist,
		fp => $fp,
		mep => $mep,
		gplp => $fp->{funcp}{graphp},
		sort_balance => 0.7,	# -0.7 0.6,		# 0.0 
		sort_wight => 0.30,			# 0.0
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
sub	ern
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
	ern::ern($RATE_PARAM);

	#
	#	グラフとHTMLの作成
	#

	my $RT_TD = sprintf("ip(%d)lp(%d)rl-avr(%d) (#LD#)", $fp->{funcp}{ip}, $fp->{funcp}{lp}, $fp->{funcp}{average_date});
	dp::dp "RT_TD :" . $RT_TD. "\n";
	$RT_TD =~ s#/#.#g;

	my $R0_LINE = "1 with lines dt \"-\" title 'R0=1'";
	my $mode = $fp->{mode};
	my $name = join("-", csvlib::valdef($config::MODE_NAME->{$mode}, " $mode "), $fp->{sub_mode}, $fp->{aggr_mode}) ;
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
		src => $fp->{src},
		clp => $csvlist,
		fp => $fp,
		mep => $mep,
		gplp => $fp->{funcp}{graphp},
		sort_balance => 0.7,
		sort_wight => 0.1,
	);
	csvgpl::csvgpl(\%params);
}

#
#	K値
#
#	・X=累計感染者数
#	・Y=1週間前の累計感染者数
#
#	とおき、“画期的な”指標である「K値」を
#
#	・K=(X-Y)/X=1-Y/X
#
#		source		https://note.com/yagena/n/n22215ecd9175
#
sub	kv
{
	my ($fp) = @_;
	my $mep = $fp->{mep};

	dp::dp "------ KV ---------\n";
	my $aggr_func = $mep->{aggregate};
	my ($colum, $record , $start_day, $last_day) = $aggr_func->($fp);

	my $RATE_PARAM = {
		input_file => $fp->{stage1_csvf},
		output_file => $fp->{stage2_csvf},
		delimiter => $mep->{DLM},
		average_date => $fp->{funcp}{average_date},
	};
	kvalue::kvalue($RATE_PARAM);

	#
	#	グラフとHTMLの作成
	#

	my $RT_TD = sprintf("ip(%d)lp(%d)rl-avr(%d) (#LD#)", $fp->{funcp}{ip}, $fp->{funcp}{lp}, $fp->{funcp}{average_date});
	dp::dp "RT_TD :" . $RT_TD. "\n";
	$RT_TD =~ s#/#.#g;

	my $mode = $fp->{mode};
	my $name = join("-", csvlib::valdef($config::MODE_NAME->{$mode}, " $mode "), $fp->{sub_mode}, $fp->{aggr_mode}) ;
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
		$gp->{ext} =~ s/#RT_TD#/$RT_TD/;
	}
	my %params = (
		debug => $DEBUG,
		src => $fp->{src},
		clp => $csvlist,
		fp => $fp,
		mep => $mep,
		gplp => $fp->{funcp}{graphp},
		sort_balance => 0.5,
		sort_wight => 0.01,
	);
	csvgpl::csvgpl(\%params);
}


