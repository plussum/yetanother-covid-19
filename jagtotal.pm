#!/usr/bin/perl
#
#
package jagtotal;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(jagtotal);

use strict;
use warnings;

use Data::Dumper;
use csvgpl;
use csvaggregate;
use csvlib;
#use ft;

my $WIN_PATH = $config::WIN_PATH;
my $CSV_PATH = $config::CSV_PATH;
my $DLM = $config::DLM;

my $DEBUG = 1;

#my $aggr_total = "$WIN_PATH/Japan_total.csv.txt";
#my $TOTAL_CSVF = "$WIN_PATH/japan_total$MODE" . ".csv.txt";
#my $TOTAL_GRAPH_HTML = "$WIN_PATH/japan_total$MODE" . ".html";
my $transaction = "$CSV_PATH/gis-jag-japan.csv.txt",
my $src_url = "https://dl.dropboxusercontent.com/s/6mztoeb6xf78g5w/COVID-19.csv";

my $EXCLUSION = "";
our $PARAMS = {			# MODULE PARETER		$mep
    comment => "**** J.A.G JAPAN PARAMS ****",
    src => "JAG JAPAN",
	src_url => $src_url,
    prefix => "jagtotal_",
    src_file => {
		NC => $transaction,
		ND => "",
    },
    base_dir => "",
	csv_aggr_mode => "TOTAL", 	# "" or TOTAL

    new => \&new,
    aggregate => \&aggregate,
    download => \&download,
    copy => \&copy,


	COUNT => {			# FUNCTION PARAMETER	$funcp
		EXEC => "",
		graphp => [		# GPL PARAMETER			$gplp
			{ext => "#KIND# TOTAL Japan 02/15(#LD#) #SRC#", start_day => "02/15",  lank =>[0, 1] , exclusion => $EXCLUSION, target => "", label_skip => 2, graph => "lines"},
			{ext => "#KIND# TOTAL Japan 03/01(#LD#) #SRC#", start_day => "03/01",  lank =>[0, 1] , exclusion => $EXCLUSION, target => "", label_skip => 2, graph => "lines"},
			{ext => "#KIND# TOTAL Japan 3w(#LD#) #SRC#", start_day => -21,  lank =>[0, 1] , exclusion => $EXCLUSION, target => "", label_skip => 2, graph => "lines"},
			{ext => "#KIND# TOTAL Japan log (#LD#) #SRC#", start_day => "02/15",  lank =>[0, 1] , exclusion => $EXCLUSION, target => "", label_skip => 2, graph => "lines",
				 logscale => "y", average => 7},
		],

	},
	FT => {
		EXEC => "",
		average_date => 7,
		ymin => 10,
		graphp => [
			{ext => "#KIND# TOTAL Japan all FT (#LD#) #SRC#", start_day => 0,  lank =>[0, 1] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", 
				series => 1, average => 7, logscale => "y", term_ysize => 600, ft => 1},
		],
	},
	RT => {
		EXEC => "",
        ip => $config::RT_IP,
		lp => $config::RT_LP,,
		average_date => 7,
		graphp => [	
			{ext => "#KIND# TOTAL Japan 0301 #RT_TD#", start_day => "03/01", lank =>[0, 5] , exclusion => $EXCLUSION, taget => "",
				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 10},
			{ext => "#KIND# TOTAL Japan 3w #RT_TD#", start_day => -21, lank =>[0, 5] , exclusion => $EXCLUSION, taget => "",
				label_skip => 2, graph => "lines", term_ysize => 300, ymax => 10},
		],
	},
};


#
#
#
sub	new 
{
	return $PARAMS;
}

#
#	Download CSV file
#
sub	download
{
	my ($info_path) = @_;

	print("wget $src_url -O $transaction\n");
	system("wget $src_url -O $transaction");
}

sub	copy
{
	my ($info_path) = @_;

	system("cp $transaction $CSV_PATH/");
}

#
#	パラメータの設定と集計の実施
#
sub	aggregate
{
	my ($fp) = @_;

	my $mode = $fp->{mode};
	my $aggr_mode = $fp->{aggr_mode};
	my $src_file = $fp->{src_file};
	my $report_csvf = $fp->{stage1_csvf};
	my $graph_html = $fp->{htmlf};
	my $csv_aggr_mode = csvlib::valdef($fp->{csv_aggr_mode}, "");

	my $agrp = {
		input_file => $transaction,
		output_file => $fp->{stage1_csvf},
		delemiter => $fp->{dlm},
		#agr_items_name => ["確定日#:#1/2/0","居住都道府県"],
		date_item => "確定日",
		date_format => [2, 0, 1],
		aggr_mode => "TOTAL",					######### このセットでTOTAL
		
		select_item => "居住都道府県",
	#	select_keys  => [qw(東京都 神奈川県)],	# 動作未検証
		exclude_keys => [],						# 動作未検証
		agr_total => 0,
		agr_count => 0,
		total_item_name => "",
		sort_keys_name => [qw (確定日) ],		# とりあえず、今のところ確定日にフォーカス（一般化できずにいる）
	};

	csvaggregate::csv_aggregate($agrp);		# 集計処理
	#system("more " . $fp->{stage1_csvf});
}

1;
