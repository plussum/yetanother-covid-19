#!/usr/bin/perl
#
#

use strict;
use warnings;

use Data::Dumper;
use Time::Local 'timelocal';
# use lib qw(../gsfh);
use csvgpl;
use csvaggregate;
use csvlib;
use ft;
use rate;

my $DEBUG = 1;
my $DOWNLOAD = 0;
my $MODE = "NC";
my $DLM = ",";

my $src_url = "https://dl.dropboxusercontent.com/s/6mztoeb6xf78g5w/COVID-19.csv";
my $WIN_PATH = "/mnt/f/OneDrive/cov";
my $transaction = "$WIN_PATH/gis-jag-japan.csv.txt";
my $AGR_CSVF = "$WIN_PATH/JapanPref_total.csv.txt";
my $RATE_CSVF = "$WIN_PATH/JapanPref_total-rate.csv.txt";
my $AGR_HTML = "$WIN_PATH/JapanPref_total-c.html";
my $RATE_HTML = "$WIN_PATH/JapanPref_total-c-rate.html";

#
#	引数処理	
#
for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DOWNLOAD = 1 if(/-dl/i);
}

#
#	Download CSV file
#
if($DOWNLOAD){
	print("wget $src_url -O $transaction\n");
	system("wget $src_url -O $transaction");
}

#
#	パラメータの設定と集計の実施
#
my $params = {
	input_file => $transaction,
	output_file => $AGR_CSVF,
	delemiter => ",",
	#agr_items_name => ["確定日#:#1/2/0","居住都道府県"],
	date_item => "確定日",
	date_format => [2, 0, 1],
	aggr_mode => "TOTAL",
	
	select_item => "居住都道府県",
#	select_keys  => [qw(東京都 神奈川県)],
	exclude_keys => [],
	agr_total => 0,
	agr_count => 0,
	total_item_name => "",
	sort_keys_name => [qw (確定日) ],		# とりあえず、今のところ確定日にフォーカス（一般化できずにいる）
};

my ($colum, $record , $start_day, $last_day) = csvaggregate::csv_aggregate($params);		# 集計処理
#system("more $aggregate");

my $src = "src J.A.G JAPAN ";
my $TD = "($last_day) $src";
$TD =~ s#/#.#g;
my $EXCLUSION = "";
my $src_ref = "J.A.G JAPAN : <a href=\"$src_url\"> $src_url</a>";
my $mode = ($MODE eq "NC") ? "RATE NEW CASES" : "RATE NEW DEATHS" ;

my @PARAMS = (
	{ext => "$mode Japan 0301 $TD", start_day => "02/01", lank =>[0, 5] , exclusion => $EXCLUSION,  label_skip => 2, graph => "lines"},
);
my @csvlist = (
	{ name => "New cases", csvf => $AGR_CSVF, htmlf => $AGR_HTML, kind => "NC", src_ref => $src_ref},
);

foreach my $clp (@csvlist){
    my %params = (
        debug => $DEBUG,
        win_path => $WIN_PATH,
		data_rel_path => "cov_data",
        clp => $clp,
        params => \@PARAMS,
    );
    csvgpl::csvgpl(\%params);
}

#
#	実行再生産数
#
#
my $ip = 5;			# 5 潜伏期間
my $lp = 10;			# 8 感染期間
my $average_date = 7;

my $RATE_PARAM = {
	input_file => $AGR_CSVF,
	output_file => $RATE_CSVF,
	delimiter => $DLM,
	average_date => $average_date,
	lp 		=> $ip,	# 5 潜伏期間
	ip 		=> $lp,	# 8 感染期間
};
($colum, $record , $start_day, $last_day) = rate::rate($RATE_PARAM);

my $R0_LINE = "1 with lines dt \"-\" title 'R0=1'";
$TD = "ip($ip)lp($lp)moving avr($average_date) ($last_day) $src";
my @RATE_PARAMS = (
	{ext => "$mode RATE Japan 0301 $TD", start_day => "02/01", lank =>[0, 5] , exclusion => $EXCLUSION, label_skip => 2, graph => "lines", additional_plot => $R0_LINE},
);
my @rate_csvlist = (
	{ name => "New cases", csvf => $RATE_CSVF, htmlf => $RATE_HTML, kind => "NC", src_ref => $src_ref, xlabel => "", ylabel => ""},
);


foreach my $clp (@rate_csvlist){
	my %params = (
		debug => $DEBUG,
		win_path => $WIN_PATH,
		data_rel_path => "cov_data",
		clp => $clp,
		params => \@RATE_PARAMS,
	);	
	csvgpl::csvgpl(\%params);
}

