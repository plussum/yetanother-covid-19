#!/usr/bin/perl
#
#
#	J.A.G JAPAN のデータから、日本の感染状況をグラフ化する
#		URL: https://dl.dropboxusercontent.com/s/6mztoeb6xf78g5w/COVID-19.csv
#
#	USAGE:
#		japan.pl [-dl] 
#			-dl	データをダウンロードしたうえでグラフを作成
#
use strict;
use warnings;

use Data::Dumper;
use csvgpl;
use csvlib;

my $DEBUG = 1;
my $DLM = ","; # "\t";
my $DOWNLOAD = 0;
my $src_url = "https://dl.dropboxusercontent.com/s/6mztoeb6xf78g5w/COVID-19.csv";
my $WIN_PATH = "/mnt/f/OneDrive/cov";
my $transaction = "$WIN_PATH/gis-jag-japan.csv";
my $PLOT_CSV = "$WIN_PATH/covPrefect.csv";
my $GRAPH_HTML = "$WIN_PATH/JapanPref.html";
my $aggregate = "$WIN_PATH/agg.csv";

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
#	Date/Time, dispay_item[0], [1], [2],,,,
#
my $params = {
	input_file => $transaction,
	output_file => $aggregate,
	#agr_items_name => ["確定日#:#1/2/0","居住都道府県"],
	date_item => "確定日",
	
	select_item => "居住都道府県",
#	select_keys  => [qw(東京都 神奈川県)],
	exclude_keys => [],
	agr_total => 0,
	agr_count => 0,
	total_item_name => "",
	sort_keys_name => [qw (確定日) ],		# とりあえず、今のところ確定日にフォーカス（一般化できずにいる）
};


# print Dumper $params;
	
my @item_name = ();
my %item_name_col = ();
my %select_items= ();
my %count_ymd = ();
my %total_ymd = ();
my $total = 0;
my $count = 0;

my $start_time = time;
my $p = $params;
	
print "### open $p->{input_file}: " . (time - $start_time) . "\n";
open(TRN, $p->{input_file}) || die "cannot open $p->{input_file} file\n";

$_ = <TRN>; chop;
&item_name_and_col($_);

my $datetime = $item_name_col{$p->{date_item}};
my @date_fmt = (2, 0, 1);	# mm/dd/yyyy を yy/mm/dd で見た位置
my $select_items_col = "";
my $select_item_names = "";
my $select_keys = ();
$select_item_names = csvlib::valdef($p->{select_item}, "");
if($select_item_names){
	$select_items_col = $item_name_col{$select_item_names};
	$select_keys  = (defined $p->{select_keys}) ? [@{$p->{select_keys}}] : "";
}
my $total_item_col = ""; #  $item_name_col{somthing};
my %date_ymd = ();

# print join(",", $datetime, $select_item_0, $select_key_0, $total_item_col), "\n";

#
#	Read Data and aggregate;
#
my $date_start = 9999999999;
my $date_final = 0;
my @date_list = ();
print "### start read data $p->{input_file}: " . (time - $start_time) . "\n" ;
while(<TRN>){
	chop;
	my @w = split(/,/, $_);
	
	if(defined($select_items_col)){
		#print $w[$select_items_col] . "/$select_keys[0][0]/", "\n";
		#next if(! csvlib::search_list($w[$select_items_col],  @{$select_keys}));	# select ;
		# next if($w[$select_items_col] =~ /$select_keys[0][0]/);	# select ;
	}

	my $v = ($total_item_col) ? $w[$total_item_col] : 1;	# 1 -> count the records
	my $dt_raw = $w[$datetime];
	if(!defined $date_ymd{$dt_raw}) {
		#print "[$dt_raw]\n";
		next if(!$dt_raw);

		my $tm = csvlib::date2ut($dt_raw, "/", @date_fmt);
		$date_ymd{$dt_raw} = csvlib::ut2d4($tm, "");

		$date_start = $tm if($tm < csvlib::valdef($date_start, 999999999));
		$date_final = $tm if($tm > csvlib::valdef($date_final, 0));
	}
	my $dt_ymd = $date_ymd{$dt_raw};
	my $sk = $w[$select_items_col];
	my $dk = $dt_ymd .= "\t" . $sk;

	$select_items{$sk}++;

	$count_ymd{$dk} ++;
	$total_ymd{$dk} += $v;

	$count++;
	$total += $v;
}
close(TRN);
print "### close $p->{input_file}: " . (time - $start_time) . "\n";

#
#	欠損している日時に補完するために最小から最大までの日をセットする
#
print "### make no data date \n";
for(my $tm = $date_start; $tm <= $date_final; $tm += 60 * 60 * 24){
	my $ymd = csvlib::ut2d4($tm, "");
	push(@date_list, $ymd);
}

#
#	日付けでsortし、データを出力
#
print "### set sort key : " . (time - $start_time) . "\n";

my @sorted_select_items = (sort {$select_items{$b} <=> $select_items{$a}} keys %select_items);
open(CSV, "> $PLOT_CSV") || die "cannot create $PLOT_CSV";
#print CSV "#" . join($DLM, @sorted_select_items), "\n";
my @dts = ();
foreach my $dt (@date_list){
		print "<$dt>";
		my $dts = $dt;
		$dts =~ s#([0-9]{4})([0-9]{2})([0-9]{2})#$2/$3#;
		print "[$dts]";
		push(@dts, $dts);
}
print "\n";
print CSV "#" . join($DLM, "total", @dts), "\n";

foreach my $sk (@sorted_select_items){
	my @records = ();
	my $total_count = 0;
	foreach my $dt (@date_list){
		#print "($dt)";
		my $k = $dt . "\t" . $sk;
		my $count = (defined $count_ymd{$k}) ? $count_ymd{$k} : 0;
		my $total = (defined $total_ymd{$k}) ? $total_ymd{$k} : 0;
		push(@records, $count);
		$total_count += $count;
	}
	#print "\n";
	#print "($dt)";
	#print "<$dt>";
	print CSV join($DLM, $sk, $total_count, @records), "\n";
}
close(CSV);
print "### done sort : " . (time - $start_time) . "\n";
print join($DLM, "total", $count, $total), "\n";

#
#
#
my $src = "src J.A.G JAPAN ";
my $EXCLUSION = "";
my $src_ref = "J.A.G JAPAN : <a href=\"$src_url\"> $src_url</a>";
my @PARAMS = (
    {ext => "#KIND# Japan 01-10 all (#LD#) $src", start_day => 0,  lank =>[0, 9] , exclusion => "Others", target => "", label_skip => 3, graph => "lines"},
    {ext => "#KIND# Japan 01-05 (#LD#) $src", start_day => "02/15",  lank =>[0, 4] , exclusion => "Others", target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan 02-05 (#LD#) $src", start_day => "02/15",  lank =>[1, 4] , exclusion => "Others", target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan 06-10 (#LD#) $src", start_day => "02/15",  lank =>[5, 9] , exclusion => "Others", target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan 11-15 (#LD#) $src", start_day => "02/15",  lank =>[10, 14] , exclusion => "Others", target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan 16-20 (#LD#) $src", start_day => "02/15",  lank =>[15, 20] , exclusion => "Others", target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan 01-10 log (#LD#) $src", start_day => "02/15",  lank =>[0, 9] , exclusion => "Others", target => "", label_skip => 2, graph => "lines", logscale => "y", average => 7},
);
my @csvlist = (
	{ name => "New cases", csvf => $PLOT_CSV, htmlf => $GRAPH_HTML, kind => "NC", src_ref => $src_ref, xlabel => "", ylabel => ""},
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
#
#
sub	item_name_and_col
{
	my ($v) = @_;

	@item_name = split(/,/, $v);
	my $col_number = $#item_name;

	#
	#	Read and set the header of CSV
	#
	for(my $i = 0; $i <= $col_number; $i++){
		my $item_name = $item_name[$i];
		$item_name_col{$item_name} = $i;
		#print "[$item_name] $i\n";
	}
}

