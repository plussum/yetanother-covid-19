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
	date_item => "確定日",
	
	select_item => "居住都道府県",
	select_keys  => [qw(東京都 神奈川県)],
	exclude_keys => [],
	agr_total => 0,
	agr_count => 0,
	total_item_name => "",
	sort_keys_name => [qw (確定日) ],		# とりあえず、今のところ確定日にフォーカス（一般化できずにいる）
};


# print Dumper $params;
	
my %agr_count_raw = ();
my %agr_total_raw = ();
my %agr_count = ();
my %agr_total = ();
my @item_name = ();
my %item_name_col = ();
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
my @select_items = ();
my @select_item_names = ();
my @select_keys = ();
$select_item_names[0] = &valdef($p->{select_item}, "");
if($select_item_names[0]){
	$select_items[0] = $item_name_col{$select_item_names[0]};
	$select_keys[0]  = [@{$p->{select_keys}}];
}
my $total_item_col = ""; #  $item_name_col{somthing};

# print join(",", $datetime, $select_item_0, $select_key_0, $total_item_col), "\n";

#
#	Read Data and aggregate;
#
my $date_start = 9999999999;
my $date_final = 0;
print "### start read data $p->{input_file}: " . (time - $start_time) . "\n" ;
while(<TRN>){
	chop;
	my @w = split(/,/, $_);
	
	if(defined($select_items[0])){
		#print $w[$select_items[0]] . "/$select_keys[0][0]/", "\n";
		next if(! &search_list($w[$select_items[0]],  @{$select_keys[0]}));	# select ;
		# next if($w[$select_items[0]] =~ /$select_keys[0][0]/);	# select ;
	}

	my $v = ($total_item_col) ? $w[$total_item_col] : 1;	# 1 -> count the records
	my $dt_raw = $w[$datetime];

	$agr_count_raw{$dt_raw}++;
	$agr_total_raw{$dt_raw} += $v;
	$count++;
	$total += $v;
	
}
close(TRN);
print "### close $p->{input_file}: " . (time - $start_time) . "\n";

#
#	日付けなどのフォーマット変換（トランザクションでやると重かったので)
#
foreach my $dt_raw (keys %agr_count_raw){
	my $tm = &date2ut($dt_raw, "/", @date_fmt);

	$date_start = $tm if($tm < &valdef($date_start, 999999999));
	$date_final = $tm if($tm > &valdef($date_final, 0));

	my $ymd = &ut2d($tm, "");
	$agr_count{$ymd} = $agr_count_raw{$dt_raw};
	$agr_total{$ymd} = $agr_total_raw{$dt_raw};
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
	# print "##### no data $agr_key\n";
}

#
#	日付けでsort
#
print "### set sort key : " . (time - $start_time) . "\n";

foreach my $dt (sort keys %agr_count){
	print join($DLM, $dt, $agr_count{$dt}, $agr_total{$dt}), "\n";
}
print "### done sort : " . (time - $start_time) . "\n";
print join($DLM, "total", $count, $total), "\n";

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

#
#
#
sub	date2ut
{
	my ($dt, $dlm, $yn, $mn, $dn, $hn, $mnn, $sn) = @_;

	my @w = split(/$dlm/, $dt);
	my ($y, $m, $d, $h, $mi, $s) = ();
	
	$y = &valdef($w[$yn], 0);
	$m = &valdef($w[$mn], 0);
	$d = &valdef($w[$dn], 0);

	if(! defined $hn){
		return &ymd2tm($y, $m, $d, 0, 0, 0);
	}

	$h  = &valdef($w[$hn], 0);
	$mi = &valdef($w[$mnn], 0);
	$s  = &valdef($w[$sn], 0);

	return &ymd2tm($y, $m, $d, $h, $mi, $s);
} 

sub	date_format
{
	my ($dt, $dlm, $y, $m, $d, $h, $mn, $s) = @_;

	my @w = split(/$dlm/, $dt);
	my @dt = ();
	my @tm = ();
	
	$dt[0] = &valdef($w[$y], 0);
	$dt[1] = &valdef($w[$m], 0);
	$dt[2] = &valdef($w[$d], 0);

	my $dts = join("/", @dt);
	if(! defined $h){
		retunr $dts;
	}
	
	$tm[0] = &valdef($w[$h], 0);
	$tm[1] = &valdef($w[$mn], 0);
	$tm[2] = &valdef($w[$s], 0);
	my $tms = join(":", @tm);

	return "$dts $tms";
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

sub search_list
{
    my ($key, @w) = @_;

	#print "search: " . join(",", @w) , "\n";
    foreach my $item (@w){
        if($key =~ /$item/){
            # print "search_list: $key:$item\n";
            return 1;
        }
    }
    return "";
}
