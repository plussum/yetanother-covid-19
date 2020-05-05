#!/usr/bin/perl
#
#

use strict;
use warnings;

use Data::Dumper;
use Time::Local 'timelocal';


my $DLM = "\t";
#my $transaction = "../COVID-19/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv";
my $transaction = "/mnt/f/OneDrive/cov/COVID-19-jp.csv";
my $aggregate = "/mnt/f/OneDrive/cov/agg.csv";
my @keys = qw ( 確定日 居住都道府県 );

#
#	Date/Time, dispay_item[0], [1], [2],,,,
#
my $params = {
	input_file => $transaction,
	output_file => $aggregate,
	#agr_items_name => ["確定日#:#1/2/0","居住都道府県"],
	agr_items_name => ["確定日#date#month/day/year"],
	select_items => {"居住都道府県" => ["東京都"]},
#	display_items => [qw (確定日 #COUNT# #TOTAL# 居住都道府県)],	# やっぱり、違う気がしてきた
	agr_total => 0,
	agr_count => 0,
	total_item_name => "",
	sort_keys_name => [qw (確定日) ],		# とりあえず、今のところ確定日にフォーカス（一般化できずにいる）
};


# print Dumper $params;
	
&aggregate_file($params);

#
#	csvdata 
#		@item_name
#		%item_col
#		$record_numner
#		$col_numner
#		@keys
#		@count
#		@total
#
sub	aggregate_file
{
	my ($p) = @_;

	my @item_name = ();
	my %item_name_col = ();
	my $col_number = 0;
	my $record_number = 0;
	my @key_items = ();
	my $arg_items_name = $p->{agr_items_name};
	my %agr_count_raw =  ();
	my %agr_total_raw =  ();
	my %agr_count =  ();
	my %agr_total =  ();
	my @agr_result_data = ();
	my $total_item_col = 0;
	my @result_data = ();
	my %result_col = ();
	my @sort_order_direction = ();
	my %item_format = ();
	my @key_format = ();
	my @key_format_flag = ();

	my $date_start = "";
	my $date_final = "";
	my $start_time = time;
	
	print "### open $p->{input_file}: " . (time - $start_time) . "\n";
	open(TRN, $p->{input_file}) || die "cannot open $p->{input_file} file\n";
	$_ = <TRN>; chop;
	@item_name = split(/,/, $_);
	$col_number = $#item_name;
	
	#
	#	Read and set the header of CSV
	#
	for(my $i = 0; $i <= $col_number; $i++){
		my $item_name = $item_name[$i];
		$item_name_col{$item_name} = $i;
	}

	#
	#	Set col numnber of aggregate items
	#
	my $kn = 0;
	foreach my $k (@{$arg_items_name}){
		my $fmt = "";
		my @fmta = ();
		my @fmt_order = ();
		my $kk = "";
		
		if($k =~ /#date#/i){
			($kk, $fmt) = split(/#date#/i, $k);
			$k = $kk;
			$item_format{$k} = $fmt;
			@fmta  = split(/\//, $fmt);
			for(my $i = 0; $i <= $#fmta; $i++){
				$fmt_order[0] = $i if($fmta[$i] =~ /year/i);
				$fmt_order[1] = $i if($fmta[$i] =~ /month/i);
				$fmt_order[2] = $i if($fmta[$i] =~ /day/i);
			}
			print "FMT:   $kk:$fmt\n";
		}
		if(! defined $item_name_col{$k}){
			die "item $k is not in the data (1st record)\n";
		}
		push(@key_items, $item_name_col{$k});
		push(@key_format, [@fmt_order]);
		push(@key_format_flag, $fmt);
		print "### key_format $kn format[$fmt]\n";
		$result_col{$k} = $kn++;
	}
	$result_col{"#COUNT#"} = $kn++;
	$result_col{"#TOTAL#"} = $kn++;

	$total_item_col = &valdef($item_name_col{total_item_name}, "");

	print "Keyitems " . $#key_items . "\n";
	
	#
	#	Read Data and aggregate;
	#
	print "### start read data $p->{input_file}: " . (time - $start_time) . "\n" ;
	while(<TRN>){
		chop;
		my @w = split(/,/, $_);
		
		my $v = ($total_item_col) ? $w[$total_item_col] : 1;	# 1 -> count the records
		my @agr_keys_raw = ();
		for(my $in = 0; $in <= $#key_items; $in++){
			my $kc = $key_items[$in];
			my $v = $w[$kc];
	
#			# select_items => {"居住都道府県" => ["東京都"]},
#			my $selp = &valdef($p->{select_items}, "");
#			if($selp){
#				foreach my $sl (keys %{$selp}){
#					my $col = $item_name_col{$sl};
#					my $sk = $selp->{$sl};
#					if(! $v =~ 


			push(@agr_keys_raw, $v);	# 本来は複数のキーだけど、現在は1キー（日付）のみ
		}

		#
		#	Set Total and Count
		#
		my $agr_key_raw = join("\t", @agr_keys_raw);
		$agr_count_raw{$agr_key_raw}++;
		$agr_total_raw{$agr_key_raw} += $v;
	}
	close(TRN);
	print "### close $p->{input_file}: " . (time - $start_time) . "\n";

	#
	#	日付けなどのフォーマット変換（トランザクションでやると重かったので)
	#
	foreach my $agr_key_raw (keys %agr_count_raw){
		my @keys = split(/\t/, $agr_key_raw);
		my @keys_formed = ();
		for(my $in = 0; $in <= $#keys; $in++){
			my $nk = $keys[$in];
			if($key_format_flag[$in]){
				my @fmt_o = @{$key_format[$in]};
				my @dt = split(/\//, $nk);
				my $tm = &ymd2tm($dt[$fmt_o[0]], $dt[$fmt_o[1]], $dt[$fmt_o[2]], 0, 0, 0);
				$nk = &ut2d($tm, "");

				$date_start = $tm if($nk < &valdef($date_start, 999999999));
				$date_final = $tm if($nk > &valdef($date_final, 0));
			}
			push(@keys_formed, $nk);
		}
		my $agr_key_reform = join("\t", @keys_formed);
		$agr_count{$agr_key_reform} = $agr_count_raw{$agr_key_raw};
		$agr_total{$agr_key_reform} = $agr_total_raw{$agr_key_raw};
		# print "$agr_key_raw -> $agr_key_reform\n";
	}
	print "### reform end $p->{input_file}: " . (time - $start_time) . "\n";

	#
	#	欠損している日時に補完
	#
	print "### make no data date \n";
	for(my $tm = $date_start; $tm <= $date_final; $tm += 60 * 60 * 24){
			my $ymd = &ut2d($tm, "");
			next if(defined $agr_count{$ymd});

			my $agr_key = &ut2d($tm, "");
			$agr_count{$agr_key} = 0;
			$agr_total{$agr_key} = 0;
			print "##### no data $agr_key\n";
	}

	#
	#	sort
	#
	print "### set sort key : " . (time - $start_time) . "\n";
	print 
	my @sort_keys_col = ();
	foreach my $sk (@{$p->{sort_keys_name}}){
		my $direction = "+";
		$sk =~ s/^[\-\+]//;
		$direction = $& if($&);

		print "## sortkeys [$sk]\n";
		if(! defined $item_name_col{$sk}){
			die "item $sk is not in the data (sort key)\n";
		}
		push(@sort_keys_col, $result_col{$sk});
		push(@sort_order_direction, $direction);
	}
	
	#
	#	 Output by order of agr_key 
	#
	print "### start sort: " . (time - $start_time) . "\n" ;
	my $rn = 0;
	foreach my $k (keys %agr_count){
		$result_data[$rn] = [split(/\t/, $k), $agr_count{$k}, $agr_total{$k}];
		#print "###### " . join($DLM, @{$result_data[$rn]}), "\n";
		$rn++;
	}

	my $sort_col = $sort_keys_col[0];

	# print "result_data: ", Dumper $result_data[0];
	$a = $result_data[0];
	#print $a->[0], ",  $sort_col\n";
	print join($DLM, @{$arg_items_name}, "count", "total"), "\n";
	foreach my $rd (sort {$a->[$sort_col] <=> $b->[$sort_col]} @result_data){
		print join($DLM, @$rd) ,"\n";
		#print join($DLM, @{$result_data[$rn]}), "\n";
	}
	print "### done sort : " . (time - $start_time) . "\n";
}	

sub	csv_sort
{
	my($a, $b) = @_;
}

#
#
#	
sub valdef
{
    my ($v, $d) = @_;
    $d = 0 if(! defined $d);
    my $rt = (defined $v && $v) ? $v : $d;

	#print "valdef:[$v]:[$d]:[$rt]\n";
    return $rt;
}	

#
#
#
sub ymd2tm
{
    my ($y, $m, $d, $h, $mn, $s) = @_;

	#print "ymd2tm: " . join("/", @_), "\n";

	#$y -= 2100 if($y > 2100);
	my $tm = timelocal($s, $mn, $h, $d, $m - 1, $y);
	# print "ymd2tm: " . join("/", $y, $m, $d, $h, $mn, $s), " --> " . &ut2d($tm, "/") . "\n";
    return $tm;
}

sub ut2t
{
    my ($tm, $dlm) = @_;

    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
    my $s = sprintf("%02d%s%02d%s%02d", $hour, $dlm, $min, $dlm, $sec);
    return $s;
}

sub ut2d
{
    my ($tm, $dlm) = @_;

    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
    my $s = sprintf("%04d%s%02d%s%02d", $year + 1900, $dlm, $mon+1, $dlm, $mday);
    return $s;
}
