#!/usr/bin/perl
#
#	Transaction File
#		2020/01/01	Tokyo	1
#		2020/01/01	Kanaga 	1
#		2020/01/02	Tokyo	1
#		2020/01/02	Saitama	1
#
#	Aggrigate
#					Tokyo	Kanagawa	Saitama
#		2020/01/01		1		1			0
#		2020/01/02		1		0			1
#
package csvaggregate;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(csvaggregate);

use strict;
use warnings;

use Data::Dumper;
use Time::Local 'timelocal';
use csvgpl;
use csvlib;
use dp;

my $DEBUG = 1;

#
#	Date/Time, dispay_item[0], [1], [2],,,,
#
#my $params = {
#	input_file => $transaction,			
#	output_file => $aggregate,
#	#agr_items_name => ["確定日#:#1/2/0","居住都道府県"],
#	date_item => "確定日",
#	
#	select_item => "居住都道府県",
##	select_keys  => [qw(東京都 神奈川県)],
##	exclude_keys => [],
#	agr_total => 0,
#	agr_count => 0,
#	date_format => [2, 0, 1],
#	total_item_name => "",
#	sort_keys_name => [qw (確定日) ],		# とりあえず、今のところ確定日にフォーカス（一般化できずにいる）
#};


my @item_name = ();
my %item_name_col = ();
my $DLM = ",";
sub	csv_aggregate
{
	my ($agrp) = @_;
	
	my %select_items= ();
	my %count_ymd = ();
	my %total_ymd = ();
	my $total = 0;
	my $count = 0;
	$DLM = $agrp->{deleimiter} if(defined $agrp->{delimiter}); # "," "\t";

	my $start_time = time;
		
	dp::dp "### open $agrp->{input_file}: " . (time - $start_time) . "\n" if($DEBUG > 1);
	open(TRN, $agrp->{input_file}) || die "cannot open $agrp->{input_file} file\n";

	$_ = <TRN>; chop;
	&item_name_and_col($_);

	my $datetime = $item_name_col{$agrp->{date_item}};
	my @date_fmt = @{$agrp->{date_format}};	# mm/dd/yyyy を yy/mm/dd で見た位置
	my $select_items_col = "";
	my $select_item_names = "";
	my $select_keys = ();
	$select_item_names = csvlib::valdef($agrp->{select_item}, "");
	if($select_item_names){
		$select_items_col = $item_name_col{$select_item_names};
		$select_keys  = (defined $agrp->{select_keys}) ? [@{$agrp->{select_keys}}] : "";
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
	dp::dp "### start read data $agrp->{input_file}: " . (time - $start_time) . "\n" if($DEBUG > 1);
	while(<TRN>){
		chop;
		my @w = split(/,/, $_);
		my $v = ($total_item_col) ? $w[$total_item_col] : 1;	# 1 -> count the records
		
		#
		#	Date format convert
		#
		my $dt_raw = $w[$datetime];
		if(!defined $date_ymd{$dt_raw}) {						# Date format 
			next if(!$dt_raw);

			my $tm = csvlib::date2ut($dt_raw, "/", @date_fmt);
			$date_ymd{$dt_raw} = csvlib::ut2d4($tm, "");				# 変換が重いので、連想配列に記録

			$date_start = $tm if($tm < csvlib::valdef($date_start, 999999999));	# データ中の最初の日と
			$date_final = $tm if($tm > csvlib::valdef($date_final, 0));			# 最後の日を抽出
		}
		my $dt_ymd = $date_ymd{$dt_raw};						# 変換済みの日付をセット
		my $sk = $w[$select_items_col];							# 選択した項目名を記録
		$select_items{$sk}++;									# 

		my $dk = $dt_ymd .= "\t" . $sk;							# 日付+項目名を記録
		$count_ymd{$dk} ++;
		$total_ymd{$dk} += $v;

		$count++;												# レコード数と合計を計算
		$total += $v;
	}
	close(TRN);
	dp::dp "### close $agrp->{input_file}: " . (time - $start_time) . "\n"if($DEBUG > 1);

	#
	#	欠損している日時に補完するために最小から最大までの日をセットする
	#
	dp::dp "### make no data date \n"if($DEBUG > 1);
	for(my $tm = $date_start; $tm <= $date_final; $tm += 60 * 60 * 24){
		my $ymd = csvlib::ut2d4($tm, "");
		push(@date_list, $ymd);
	}

	#
	#	日付けでsortし、データを出力
	#
	dp::dp "### set sort key : " . (time - $start_time) . "\n"if($DEBUG > 1);
	
	#	選択した項目をソートして配列に入れておく（ソートを一回で済ますため）I
	my @sorted_select_items = (sort {$select_items{$b} <=> $select_items{$a}} keys %select_items);
	#print CSV "#" . join($DLM, @sorted_select_items), "\n";

	#	CSV出力用の日付けの変換	(最初からこのフォーマットでやればよかったか？）
	my @dts = ();
	foreach my $dt (@date_list){
			my $dts = $dt;
			$dts =~ s#([0-9]{4})([0-9]{2})([0-9]{2})#$2/$3#;
			push(@dts, $dts);
	}

	#
	#	CSVの出力	
	#
	open(CSV, "> $agrp->{output_file}") || die "cannot create $agrp->{output_file}";

	#	1行目：項目名など
	print CSV "#" . join($DLM, "date", "total", @dts), "\n";

	#
	#	1日分のデータの出力
	#
	my $rn = 0;
	my $aggr_mode = csvlib::valdefs($agrp->{aggr_mode}, "");
	dp::dp "aggr_mode: $aggr_mode\n"if($DEBUG > 1);
	if(! $aggr_mode){
		foreach my $sk (@sorted_select_items){
			my @records = ();
			my $total_count = 0;
			foreach my $dt (@date_list){
				my $k = $dt . "\t" . $sk;
				my $count = (defined $count_ymd{$k}) ? $count_ymd{$k} : 0;
				my $total = (defined $total_ymd{$k}) ? $total_ymd{$k} : 0;
				push(@records, $count);
				$total_count += $count;
			}
			$rn++;
			print CSV join($DLM, $sk, $total_count, @records), "\n";
		}
	}
	else {
		my $agg_total = 0;
		my @records = ();
		foreach my $dt (@date_list){
			my $total_count = 0;
			foreach my $sk (@sorted_select_items){
				my $k = $dt . "\t" . $sk;
				my $count = (defined $count_ymd{$k}) ? $count_ymd{$k} : 0;
				my $total = (defined $total_ymd{$k}) ? $total_ymd{$k} : 0;
				$total_count += $count;
			}
			if($aggr_mode eq "TOTAL"){
				$agg_total += $total_count;
				push(@records, $total_count);
			}
			elsif($aggr_mode eq "AVERAGE"){
				$agg_total += $total_count / ($#date_list + 1);
				push(@records, ($total_count / ($#date_list + 1)));
			}
		}
		$rn++;
		print CSV join($DLM, $aggr_mode, $agg_total, @records), "\n";
	}
	close(CSV);

	dp::dp "### done sort : " . (time - $start_time) . "\n"if($DEBUG > 1);
	dp::dp join($DLM, "total", $count, $total), "\n"if($DEBUG > 1);

	return ($#date_list, $rn , $date_list[0], $date_list[$#date_list]) ;
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

