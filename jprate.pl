#!/usr/bin/perl
#
#	J.A.G JAPAN のデータから、日本の感染状況を実行再生産数のグラフにする
#		https://dl.dropboxusercontent.com/s/6mztoeb6xf78g5w/COVID-19.csv
#
#	USAGE:
#		japan.pl [-dl] 
#			-dl	データをダウンロードしたうえでグラフを作成
#

use strict;
use warnings;

use Data::Dumper;
use Time::Local 'timelocal';
# use lib qw(../gsfh);
use csvgpl;
use csvaggregate;
use csvlib;
use rate;

my $DEBUG = 1;
my $DOWNLOAD = 0;
my $MODE = "NC";
my $src_url = "https://dl.dropboxusercontent.com/s/6mztoeb6xf78g5w/COVID-19.csv";
my $WIN_PATH = "/mnt/f/OneDrive/cov";
my $transaction = "$WIN_PATH/gis-jag-japan.csv";
my $aggregate = "$WIN_PATH/JapanPref_total.csv.txt";

my $REPORT_CSVF = "$WIN_PATH/japan_rate$MODE" . ".csv.txt";
my $GRAPH_HTML = "$WIN_PATH/japan_rate$MODE" . ".html";

my $DLM = ",";

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
	output_file => $aggregate,
	delemiter => ",",
	#agr_items_name => ["確定日#:#1/2/0","居住都道府県"],
	date_item => "確定日",
	date_format => [2, 0, 1],
	aggr_mode => "",		# "TOTAL",
	
	select_item => "居住都道府県",
#	select_keys  => [qw(東京都 神奈川県)],
	exclude_keys => [],
	agr_total => 0,
	agr_count => 0,
	total_item_name => "",
	sort_keys_name => [qw (確定日) ],		# とりあえず、今のところ確定日にフォーカス（一般化できずにいる）
};

csvaggregate::csv_aggregate($params);		# 集計処理
#system("more $aggregate");

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

my $ip = 5;			# 5 潜伏期間
my $lp = 10;			# 8 感染期間
my $average_date = 7;

my $RATE_PARAM = {
	input_file => $aggregate,
	output_file => $REPORT_CSVF,
	delimiter => $DLM,
	average_date => $average_date,
	lp 		=> $ip,	# 5 潜伏期間
	ip 		=> $lp,	# 8 感染期間
};
my ($colum, $record , $start_day, $last_day) = rate::rate($RATE_PARAM);
dp::dp $REPORT_CSVF . "\n";


#
#	グラフとHTMLの作成
#
my $src = "src J.A.G JAPAN ";
my $TD = "ip($ip)lp($lp)moving avr($average_date) ($last_day) $src";
$TD =~ s#/#.#g;
my $mode = ($MODE eq "NC") ? "RATE NEW CASES" : "RATE NEW DEATHS" ;

my $EXCLUSION = "Others";
my $R0_LINE = "1 with lines dt \"-\" title 'R0=1'";
my @PARAMS = (
	{ext => "$mode Japan 0301 (#LD#)", start_day => "02/01", lank =>[0, 5] , exclusion => $EXCLUSION, ymax => 10, 
		label_skip => 2, graph => "lines", additional_plot => $R0_LINE},
	{ext => "$mode Tokyo 0301 (#LD#)", start_day => "02/01", lank =>[0, 5] , exclusion => $EXCLUSION, target => "東京,大阪,神戸,北海道", ymax => 10, 
		label_skip => 2, graph => "lines", additional_plot => $R0_LINE},
);
my $src_ref = "<a href=\"$src_url\">$src_url</a>";
my @csvlist = (
    { name => "COV19 RATE NEW CASE", csvf => $REPORT_CSVF, htmlf => $GRAPH_HTML, kind => "NC", src_ref => $src_ref },
#    { name => "NEW DETH", csvf => $RATE_CSVF, htmlf => $GRAPH_HTML, kind => "ND"},
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

