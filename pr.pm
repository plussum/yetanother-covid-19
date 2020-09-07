#!/usr/bin/perl
#
#	Tokyo Positive Rate
#
#
#

package tpm;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(pm);

use strict;
use warnings;

use Data::Dumper;
use csvgpl;
use csvaggregate;
use csvlib;

use JSON qw/encode_json decode_json/;

#
#	Initial
#
my $WIN_PATH = $config::WIN_PATH;
my $CSV_PATH = $config::CSV_PATH;
my $DLM = $config::DLM;

my $DEBUG = 1;


#
#	Parameter set
#
our $EXCLUSION = "";

my $BASE_DIR = "/home/masataka/who/tokyo/covid19";
our $transaction = "$BASE_DIR/data/positive_rate.json";		# 感染率
#our $transaction = "$CSV_PATH/gis-jag-japan.csv.txt",
our $src_url = "https://github.com/tokyo-metropolitan-gov/covid19";
our $PARAMS = {			# MODULE PARETER		$mep
    comment => "**** TOYO Positive Rate ****",
    src => "tokyo-metroplitan-gov/covid19",
	src_url => $src_url,
    prefix => "tpr_",
    src_file => {
		NC => $transaction,
		CC => $transaction,
    },
    base_dir => "",
	csv_aggr_mode => "", 	# "" or TOTAL

    new => \&new,
    aggregate => \&aggregate,
    download => \&download,
    copy => \&copy,


	AGGR_MODE => {DAY => 1, POP => 1},		# POP: 7 Days Total / POP
	#MODE => {NC => 1, ND => 1},

	COUNT => {			# FUNCTION PARAMETER	$funcp
		EXEC => "",
		graphp => [		# GPL PARAMETER			$gplp
		],
		graphp_mode => {												# New version of graph pamaeter for each MODE
			NC => [
				{ext => "#KIND# Tokyo Positive Rate (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXCLUSION, target => "", 
					label_skip => 2, graph => "lines"},
			],
			CC => [
				{ext => "#KIND# Tokyo Positive Rate (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXCLUSION, target => "", 
					label_skip => 2, graph => "lines"},
			],
		},
	},
};


#
#	For initial (first call from cov19.pl)
#
sub	new 
{
	return $PARAMS;
}

#
#	Download data from the data source
#
sub	download
{
	my ($info_path) = @_;

	system("(cd ../tokyo/covid19; git pull origin master)");
}

#
#	Copy download data to Windows Path
#
sub	copy
{
	my ($info_path) = @_;

	system("cp $transaction $CSV_PATH/");
}

#
#	Aggregate J.A.G Japan  
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
		mode => $mode,
		input_file => $transaction,
		output_file => $fp->{stage1_csvf},
		delemiter => $fp->{dlm},
		exclude_keys => [],						# 動作未検証
		agr_total => 0,
		agr_count => 0,
		total_item_name => "",
	};

	return &tko_csv($agrp);		# 集計処理
	#system("more $aggregate");
}

sub	tko_pr
{
	my ($agp) = @_;

	my $src_file = $agp->{input_file};
	my $out_file = $agp->{output_file};


	my $JSON = "";
	open(FD, $src_file) || die "cannot open $src_file";
	while(<FD>){
		$JSON .= $_;
	}
	close(FD);

	my $positive = decode_json($JSON);
	my @KEYS = qw(diagnosed_date positive_count negative_count positive_rate);

	print $positive->{date} . "\n";
	foreach my $dt (@{$positive->{data}}) {
		my @data = ();
		foreach my $k (@KEYS){
			push(@data, csvlib::valdef($dt->{$k}));
		}
		print join(", ", @data) . "\n";
	}

	#sub	valdef
	#{
	#	my($v) = @_;
	#
	#	$v = 0 if(!defined $v);
	#	return $v;
	#}
	#dp::dp "Tokyo: " . $PREFS{Tokyo} . "\n";
	my @PREF_ORDER = sort {$PREFS{$b} <=> $PREFS{$a}} keys %PREFS;
	my @DATE_ORDER = sort keys %DATES;

	open(CSV, "> $out_file") || die "cannto create $out_file\n";
	print CSV join(",", "# pref", "total", @DATE_ORDER) . "\n";
	my $RN = 0;
	foreach my $pref (@PREF_ORDER){
		my @data = ();
		my $lv = 0;
		my $tl = 0;
		for(my $i = 0; $i <= $#DATE_ORDER; $i++){
			my $ymd = $DATE_ORDER[$i];
			my $v = csvlib::valdef($COUNT{$ymd}{$pref}, 0);
			$v = 0 if(!$v);
			#dp::dp "$ymd: $v, $lv => " . ($v - $lv) . "\n";
			push(@data, $v - $lv);
			$tl += ($v - $lv);
			$lv= $v;
		}
		#dp::dp join(", ", $pref, $#DATE_ORDER, $lv, $DATE_ORDER[$#DATE_ORDER]) . "\n";
		print CSV join(",", $pref, $tl, @data) . "\n";
		$RN++;
	}
	close(CSV);
	#
	#	戻り値: カラム数、レコード数、最初の日付け、最後の日付
	#
	#return ($#date_list, $rn , $date_list[0], $date_list[$#date_list]) ;
	return ($#DATE_ORDER, $RN, $DATE_ORDER[0], $DATE_ORDER[$#DATE_ORDER]);
}

