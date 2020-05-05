#!/usr/bin/perl
#
#	J.A.G JAPAN のデータから、日本の感染状況をFinatial Time LIKEなグラフ化する
#		URL: https://dl.dropboxusercontent.com/s/6mztoeb6xf78g5w/COVID-19.csv
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
use ft;

my $DEBUG = 1;
my $DOWNLOAD = 0;
my $src_url = "https://dl.dropboxusercontent.com/s/6mztoeb6xf78g5w/COVID-19.csv";
my $WIN_PATH = "/mnt/f/OneDrive/cov";
my $transaction = "$WIN_PATH/gis-jag-japan.csv";
my $GRAPH_HTML = "$WIN_PATH/JapanPref_total-ft.html";
my $aggregate = "$WIN_PATH/JapanPref_total.csv";
my $ft_jp = "$WIN_PATH/JapanPref_total-ft.csv";

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
#	定型のCSVから、Finantial Times方式のデータを生成
#
my $FT_PARAM = {
	input_file => $aggregate,
	output_file => $ft_jp,
	average_day => 7,
	thresh => 10,
	delimiter => ",",
};
ft::ft($FT_PARAM);

#
my $guide = ft::exp_guide(2, 10, 11, 'linecolor "#808080"');
my $ymin = '10';

my $src = "src J.A.G JAPAN ";
my $EXCLUSION = "";
my $src_ref = "J.A.G JAPAN : <a href=\"$src_url\"> $src_url</a>";
my @PARAMS = (
    {ext => "#KIND# ALL Japan all FT (#LD#) $src", start_day => 0,  lank =>[0, 20] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", 
		series => 1, average => 7, logscale => "y", term_ysize => 600, ft => 1, ymin => $ymin, additional_plot => $guide},
);
my @csvlist = (
	{ name => "New cases", csvf => $ft_jp, htmlf => $GRAPH_HTML, kind => "NC", src_ref => $src_ref, xlabel => "", ylabel => ""},
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

