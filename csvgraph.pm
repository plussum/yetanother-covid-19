#!/usr/bin/perl
#
#	Apple Mobile report
#	https://covid19.apple.com/mobility
#
#	Complete Data
#	https://covid19-static.cdn-apple.com/covid19-mobility-data/2025HotfixDev13/v3/en-us/applemobilitytrends-2021-01-25.csv
#
#	0        1      2                   3                4          5       6         7
#	geo_type,region,transportation_type,alternative_name,sub-region,country,2020/1/13,2020/1/14,2020/1/15,2020/1/16
#	country/region,Japan,driving,日本,Japan-driving,,100,97.94,99.14,103.16
#
##	CSV_DEF = {
#		title => "Apple Mobility Trends",						# Title of CSV (use for HTML and other)
#		main_url =>  "https://covid19.apple.com/mobility",		# Main URL to reffer
#
#		src_url => $src_url,									# Source URL to download (mainly for HTML)
#		csv_file =>  "$config::WIN_PATH/apm/abc.csv.txt",		# Dowanloaded file, csv file for anlyize
#		down_load => \&download,								# Download function (User must define this)
#
#		timefmt = '%Y-%m-%d',									# 2021-01-02 %Y/%m/%d
#		src_dlm => ",",											# Delimitter (usually "," or "\t")
#		keys => [1, 2],		# 5, 1, 2							# key column numbers  -> Japana-driving
#		data_start => 6,										# Start column number of dates
#
#		#### INITAIL at new
#		csv_data =>  {},										# Main Data (All data of CSV file)
#		date_list =>  [],										# Date information 
#		dates =>  0,											# Number of dates
#		order =>  {},											# Soreted order of data (key)
#		key_items =>  {};
#		avr_date =>  ($CDP->{avr_date} // $DEFAULT_AVR_DATE),
#	};
#
##	GRAPH_PARAMN
#		html_file => "$config::HTML_PATH/apple_mobile.html",	# HTML file to generate
#		html_title => $CSV_DEF->{title},						# Use for HTML Title
#		png_path   => "$config::PNG_PATH",						# directory for generating graph items
#		png_rel_path => "../PNG",								# Relative path of CSV, PNG
#		GRAPH_PARAMS = {
#
#		dst_dlm => "\t",										# Delimitter of csv  for gnueplot
#		avr_date => 7,											# Default rolling average term (date)
#	
#		timefmt => '%Y-%m-%d',									# Time format of CSV (gnueplot)
#		format_x => '%m/%d',									# Time format for Graph (gnueplot)
#	
#		term_x_size => 1000,									# Graph image size (x) PNG
#		term_y_size => 350,										# Graph image size (y) PNG
#	
#		END_OF_DATA => $END_OF_DATA,							# END MARK of graph parameters
#		graph_params => [
#			{
#				dsc => "Japan target prefecture", 				# Description of the graph, use for title and file name
#				lank => [1,5], 									# Target data for use (#1 to #5)
#				static => "rlavr", 								# "": Raw, "rlavr":Rolling average
#				start_date => "", 								# Start date: Date format or number (+: from firsta date, -: from last date)
#				end_date => ""									# 	2021-01-01, 10, -10
#				target_col => [ 								### Taget itmes 
#					"sub-region", 								# Col#0 = sub-region
#					"Tokyo,Osaka,Kanagawa",						# Col#1 = Tokyo or Osaka or Kanagawa
#					 "transit", 								# Col#2 = transit
#					"",											# Col#3 = any (*)
#					"",											# Col#4 = any (*)
#					"Japan" 									# Col#5 = Japan
#				],
#			},
#			{dsc => "Japan", lank => [1,99], static => "rlavr", target_col => [@JAPAN], start_date => "", end_date => ""},
#			{dsc => "Japan 2m", lank => [1,99], static => "", target_col => [@JAPAN], start_date => -93, end_date => ""},
#			{dsc => "Japan 2m", lank => [1,99], static => "rlavr", target_col => [@JAPAN], start_date => -93, end_date => ""},
#			{dsc => $END_OF_DATA},
#		}
#	};
#
package csvgraph;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(csvgraph);

use strict;
use warnings;
use utf8;
use Encode 'decode';
use JSON qw/encode_json decode_json/;
use Data::Dumper;
use config;
use csvlib;

binmode(STDOUT, ":utf8");

my $DEBUG = 0;
my $VERBOSE = 0;
my $DEFAULT_AVR_DATE = 7;
my $DEFAULT_KEY_DLM = "-";					# Initial key items
our $CDP = {};

my $FIRST_DATE = "";
my $LAST_DATE  = "";

my @cdp_arrays = ("date_list", "keys", "load_order");
my @cdp_hashs = ("order");
my @cdp_hash_with_keys = ("csv_data", "key_items");
my @cdp_values = ("title", "main_url", "src_url", "csv_file",
		"down_load", 
		"src_dlm", "timefmt", "data_start");

sub	new
{
	my ($cdp) = @_;
	
	&init_cdp($cdp);
}

sub	init_cdp
{
	my ($cdp) = @_;
	
	foreach my $item (@cdp_arrays){
		$cdp->{$item} = [] if(! defined $cdp->{$item});
	}
	foreach my $item (@cdp_hashs, @cdp_hash_with_keys){
		$cdp->{$item} = {} if(! defined $cdp->{$item});
	}

	$cdp->{dates} = 0,
	$cdp->{avr_date} = ($cdp->{avr_date} // $DEFAULT_AVR_DATE),
	$cdp->{timefmt} = $cdp->{timefmt} // "%Y-%m-%d";
	$cdp->{key_dlm} = $cdp->{key_dlm} // $DEFAULT_KEY_DLM;
}

#
#	Dump csv definition
#
sub	dump_cdp
{
	my ($cdp, $p) = @_;

	my $ok = $p->{ok} // 1;
	my $lines = $p->{lines} // "";
	my $items =$p->{items} // 5;
	my $mess = $p->{message} // "";

	print "#" x 10 . "[$mess] CSV DUMP " . $cdp->{title} . " " . "#" x 10 ."\n";
	#
	#	Dump Values
	#
	foreach my $item (@cdp_values){
		print join("\t", $item, $cdp->{$item}// "undefined") . "\n"; 
	}

	my $csv_data = $cdp->{csv_data};
	my $key_items = $cdp->{key_items};
	my $load_order = $cdp->{load_order};

	my $key_count = keys (%$csv_data);
	
	print "-------- Dump CSV Data($key_items)  $key_count ----------\n";
	$p->{src_csv} = $cdp->{src_csv};
	&dump_csv_data($csv_data, $p);
	#dp::dp "LOAD ORDER " . join(",", @$load_order) . "\n";

	print "#" x 40 . "\n\n";
}

sub	dump_csv_data
{
	my($csv_data, $p) = @_;
	my $ok = $p->{ok} // 1;
	my $lines = $p->{lines} // "";
	my $items = $p->{items} // 5;
	my $src_csv = $p->{src_csv} // "";
	my $mess = $p->{message} // "";

	dp::dp "------ [$mess] Dump csv data ($csv_data) --------\n";
	csvlib::disp_caller(1..3);
	dp::dp "-" x 30 . "\n";
	my $ln = 0;
	foreach my $k (keys %$csv_data){
		my @w = @{$csv_data->{$k}};
		next if($#w < 0);

		if(! defined $w[1]){
			dp::dp " --> [$k] csv_data is not assigned\n";
		}
		if($ok){
			last if($lines && $ln++ >= $lines);

			my $scv = "--";
			$scv = $src_csv->{$k} if($src_csv && defined $src_csv->{$k});
			print "[$ln] " . join(", ", $k, "[$scv]", @w[0..$items]) . "\n";
		}
	}
	dp::dp "-" x 30 . "\n";
}


#
#	Lpad CSV File
#
sub	load_csv
{
	my ($cdp, $download) = @_;

	if(($download // "")){
		my $download = $cdp->{download};
		$download->($cdp);
	}

	my $direct = $cdp->{direct} // "";
	if($direct =~ /json/i){
		&load_json($cdp);
	}
	elsif($direct =~ /vertical/i){
		&load_csv_vertical($cdp);
	}
	else {
		&load_csv_holizontal($cdp);
	}

	if(($cdp->{cumrative} // "")){
		&cumrative2daily($cdp);
	}

	#
	#	DEBUG: Dump data 
	#
	&dump_cdp($cdp, {ok => 1, lines => 5}) if($VERBOSE > 1);
	
	return 0;
}

#
#	load holizontal csv file
#
#			01/01, 01/02, 01/03 ...
#	key1
#	key1
#
sub	load_csv_holizontal
{
	my ($cdp) = @_;

	my $csv_file = $cdp->{csv_file};
	my $data_start = $cdp->{data_start};
	my $src_dlm = $cdp->{src_dlm};
	my $date_list = $cdp->{date_list};
	my $csv_data = $cdp->{csv_data};
	my $key_items = $cdp->{key_items};
	my @keys = @{$cdp->{keys}};			# Item No for gen HASH Key
	my $timefmt = $cdp->{timefmt};

	#
	#	Load CSV DATA
	#
	dp::dp "$csv_file\n";
	open(FD, $csv_file) || die "Cannot open $csv_file";
	my $line = <FD>;
	$line =~ s/[\r\n]+$//;
	$line = decode('utf-8', $line);

	my @w = split(/$src_dlm/, $line);
	@$date_list = @w[$data_start..$#w];
	for(my $i = 0; $i < scalar(@$date_list); $i++){
		$date_list->[$i] = &timefmt($timefmt, $date_list->[$i]);
	}
		
	$cdp->{dates} = scalar(@$date_list) - 1;
	$FIRST_DATE = $date_list->[0];
	$LAST_DATE = $date_list->[$#w - $data_start];

	#dp::dp join(",", "# ", @$date_list) . "\n";
	#dp::dp "keys : ", join(",", @keys). "\n";
	my $load_order = $cdp->{load_order};
	my $key_dlm = $cdp->{key_dlm} // $DEFAULT_KEY_DLM;
	my $ln = 0;
	while(<FD>){
		s/[\r\n]+$//;
		my $line = decode('utf-8', $_);
		my @items = split(/$src_dlm/, $line);

		my @gen_key = ();
		my $kn = 0;
		foreach my $n (@keys){
			my $itm = $items[$n];
			push(@gen_key, $itm);
			$kn++;
		}
		my $k = join($key_dlm, @gen_key);				# set key_name
		$csv_data->{$k}= [@items[$data_start..$#items]];	# set csv data
		$key_items->{$k} = [@items[0..($data_start - 1)]];	# set csv data
		push(@$load_order, $k);
		
		$ln++;
		#last if($ln > 50);
	}
	close(FD);
	return 0;
}

#
#	Load vetical csv file
#
#			key1,key2,key3
#	01/01
#	01/02
#	01/03
#
sub	load_csv_vertical
{
	my ($cdp) = @_;

	my $remove_head = 1;
	my $csv_file = $cdp->{csv_file};
	my $data_start = $cdp->{data_start};
	my $src_dlm = $cdp->{src_dlm};
	my $date_list = $cdp->{date_list};
	my $csv_data = $cdp->{csv_data};
	my $key_items = $cdp->{key_items};
	my @keys = @{$cdp->{keys}};
	my $timefmt = $cdp->{timefmt};

	#
	#	Load CSV DATA
	#
	dp::dp "$csv_file\n";
	open(FD, $csv_file) || die "Cannot open $csv_file";
	my $line = <FD>;
	$line =~ s/[\r\n]+$//;
	$line = decode('utf-8', $line);

	my @key_list = split(/$src_dlm/, $line);
	if($#key_list <= 1){
		dp::dp "WARNING: may be wrong delimitter [$src_dlm]\n";
		dp::dp $line . "\n";
	}
	shift(@key_list);
	foreach my $k (@key_list){
		#$k =~ s/^[0-9]+:// if($remove_head);			# 
		$csv_data->{$k}= [];		# set csv data array
		$key_items->{$k} = [$k];
	}
	#dp::dp join(",", "# " , @key_list) . "\n";

	my $ln = 0;
	while(<FD>){
		s/[\r\n]+$//;
		my $line = decode('utf-8', $_);
		my ($date, @items) = split(/$src_dlm/, $line);
	
		$date_list->[$ln] = &timefmt($timefmt, $date);
		#dp::dp "date:$ln $date " . $date_list->[$ln] . " ($timefmt) $cdp->{title}\n";
	
		for(my $i = 0; $i <= $#items; $i++){
			my $k = $key_list[$i];
			$csv_data->{$k}->[$ln]= $items[$i];
		}
		$ln++;
	}
	close(FD);

	$cdp->{dates} = $ln - 1;
	$FIRST_DATE = $date_list->[0];
	$LAST_DATE = $date_list->[$ln-1];
}

#{	
#		src => "$TKY_DIR/data/positive_rate.json",
#		date => "diagnosed_date",
#		dst => "tky_pr",
#		title => "Tokyo Positive Rate",
#		ylabel => "daiagnosed count",
#		y2label => "positive rate",
#		items => [qw (diagnosed_date positive_count negative_count positive_rate)],
#		y2max => "positive_rate",
#		dt_start => "0000-00-00",
#		plot => [
#			{colm => '($2+$3)', axis => "x1y1", graph => "boxes fill",  item_title => "test total"},
#			{colm => '2', axis => "x1y1", graph => "boxes fill",  item_title => "positive count"},
#			{colm => '4', axis => "x1y2", graph => "lines linewidth 2",  item_title => "positive rate"},
#		],
#	}
sub	load_json
{
	my ($cdp) = @_;

	my $remove_head = 1;
	my $src_file = $cdp->{src_file};
	my @items = $cdp->{json_items};
	my $date_key = shift(@items);

	$cdp->{data_start} = $cdp->{data_start} // 1 ;
	my $date_list = $cdp->{date_list};
	my $csv_data = $cdp->{csv_data};
	my $key_items = $cdp->{key_items};
	my @keys = @{$cdp->{keys}};
	my $timefmt = $cdp->{timefmt};

	my $rec = 0;
	my $date_name = "";

	#
	#	Read from JSON file
	#
	my $JSON = "";
	open(FD, $src_file) || die "cannot open $src_file";
	while(<FD>){
		$JSON .= $_;
	}
	close(FD);
	my $positive = decode_json($JSON);
	#print Dumper $positive;

	my @data0 = (@{$positive->{data}});
	#print Dumper $positive;
	#[421] csvgraph.pm $VAR1 = {
    #     'pcr_positive_count' => 5,
    #     'antigen_positive_count' => undef,
    #     'pcr_negative_count' => 69,
    #     'negative_count' => 69,
    #     'antigen_negative_count' => undef,
    #     'positive_rate' => undef,
    #     'positive_count' => 5,
    #     'diagnosed_date' => '2020-02-16',
    #     'weekly_average_diagnosed_count' => undef
	for(my $i = 0; $i <= $#data0; $i++){
		my $datap = $data0[$i];
		my $date = $datap->{$date_key};
		$date_list->[$i] = $date;
		foreach (my $itn = 0; $itn <= $#items; $itn++){
			my $k = $items[$itn];
			my $v = $datap->{$k} // 0;
			$key_items->{$k} = [$k] if($itn == 0);

			my $dp = $csv_data->{$k};
			$dp->[$i] = $v;
			#dp::dp Dumper $dt;
			dp::dp "$k:$itn: $v\n";
		}
		#dp::dp  join(",", @$dp) . "\n";
	}
	$cdp->{dates} = $#data0;
	$FIRST_DATE = $date_list->[0];
	$LAST_DATE = $date_list->[$#data0];
}

#
#	Combert time format
#
sub	timefmt
{
	my ($timefmt, $date) = @_;

	#dp::dp "[$timefmt][$date]\n";
	if($timefmt eq "%Y/%m/%d"){
		$date =~ s#/#-#g;
	}
	elsif($timefmt eq "%m/%d/%y"){
		my($m, $d, $y) = split(/\//, $date);
		$date = sprintf("%04d-%02d-%02d", $y + 2000, $m, $d);
	}
	return $date;
}


#
#	Cumrative data to daily data
#
sub	cumrative2daily
{
	my($cdp) = @_;

	my $csv_data = $cdp->{csv_data};

	foreach my $k  (keys %$csv_data){
		my $dp = $csv_data->{$k};
		#dp::dp "##" . join(",", $k, $csv_data, $dp) . "\n";
		my $dates = scalar(@$dp) - 1;
		for(my $i = $dates; $i > 0; $i--){
			$dp->[$i] = $dp->[$i] - $dp->[$i-1];
		}
	}
}


#
#	Marge csvdef
#
sub	marge_csv
{
	my ($marge, @src_csv_list) = @_;

	&new($marge);

	my $date_start = "0000-00-00";
	foreach my $cdp (@src_csv_list){
		my $dt = $cdp->{date_list}->[0];
		$date_start = $dt if($dt gt $date_start );
		#dp::dp "date_start[$dt] $date_start\n";
	}
	my $date_end = "9999-99-99";
	foreach my $cdp (@src_csv_list){
		my $dates = $cdp->{dates};
		my $dt = $cdp->{date_list}->[$dates];
		$date_end = $dt if($dt le $date_end );
		#dp::dp "date_end[$dt] $date_end\n";
	}
	my $dates = csvlib::date2ut($date_end, "-") - csvlib::date2ut($date_start, "-");
	$dates /= 60 * 60 * 24;
	dp::dp join(", ", $date_start, $date_end, $dates) . "\n" if($DEBUG);

	#
	#	Check Start date(max) and End date(min)
	#
	my @csv_info = ();
	for(my $i = 0; $i <= $#src_csv_list; $i++){
		$csv_info[$i] = {};
		my $infop = $csv_info[$i];
		my $cdp = $src_csv_list[$i];
		my $date_list = $cdp->{date_list};
		push(@{$marge->{load_order}}, @{$cdp->{load_order}});

		my $dt_start = csvlib::search_listn($date_start, @$date_list);
		if($dt_start < 0){
			dp::dp "WARNING: Date $date_start is not in the data\n";
			$dt_start = 0;
		}
		$infop->{date_start} = $dt_start;

		my $dt_end = csvlib::search_listn($date_end, @$date_list);
		if($dt_end < 0){
			dp::dp "WARNING: Date $date_end is not in the data\n";
			$dt_end = 0;
		}
		$infop->{date_end} = $dt_end;
	
		#dp::dp ">>>>>>>>>> date:[$i] " . join(", ", $dt_start, $dt_end) . "\n";
	}

	#
	#	Marge
	#
	my $m_csv_data = $marge->{csv_data};
	my $m_date_list = $marge->{date_list};
	my $m_key_items = $marge->{key_items};

	my $infop = $csv_info[0];
	$marge->{dates} = $dates;
	$marge->{src_csv} = {};
	$marge->{data_start} = 1;
	my $src_csv = $marge->{src_csv};
	#dp::dp ">>> Dates: $dates,  $m_csv_data\n";

	#dp::dp "start:$start, end:$end dates:$dates\n";
	#dp::dp "## src:" . join(",", @{$date_list} ) . "\n";
	#dp::dp "## dst:" . join(",", @{$m_date_list} ) . "\n";

	for(my $csvn = 0; $csvn <= $#src_csv_list; $csvn++){
		my $cdp = $src_csv_list[$csvn];
		my $csv_data = $cdp->{csv_data};

		my $infop = $csv_info[$csvn];
		my $start = $infop->{date_start} // "UNDEF";
		my $end   = $infop->{date_end} // "UNDEF";
		dp::dp "marge [$csvn] date $start to $end\n" if($DEBUG);
		if($csvn == 0){
			my $date_list = $cdp->{date_list};
			@{$m_date_list} = @{$date_list}[$start..$end];
		}

		foreach my $k (keys %$csv_data){
			$src_csv->{$k} = $csvn;
			$m_key_items->{$k} = [$k];

			my $dp = $csv_data->{$k};
			$m_csv_data->{$k} = [];
			my $mdp = $m_csv_data->{$k};
			if(! defined $dp->[1]){
				dp::dp "WARNING: no data in [$k]\n" if(0);
			}
			for(my $i = 0; $i <= $dates; $i++){
				$mdp->[$i] = $dp->[$start + $i] // 0;		# may be something wrong
			}
			#@{$m_csv_data->{$k}} = @{$csv_data->{$k}}[$start..$end];
			#dp::dp ">> src" . join(",", $k, @{$csv_data->{$k}} ) . "\n";
			#dp::dp ">> dst" . join(",", $k, @{$m_csv_data->{$k}} ) . "\n";
		}
	} 
	&dump_cdp($marge, {ok => 1, lines => 5}) if($DEBUG);
}

#
#	Reduce CSV DATA with replace data set
#
sub	copy_cdp
{
	my($cdp, $dst_cdp) = @_;
	
	&reduce_cdp($cdp, $dst_cdp, $cdp->{load_order});
}

sub	reduce_cdp_target
{
	my ($cdp, $dst_cdp, $target_colp) = @_;

	my @target_keys = ();
	&select_keys($cdp, $target_colp, \@target_keys);
	&reduce_cdp($cdp, $dst_cdp, \@target_keys);
}

sub	reduce_cdp
{
	my($cdp, $dst_cdp, $target_keys) = @_;

	&new($dst_cdp);

	@{$dst_cdp->{load_order}} = @$target_keys;		

	my @arrays = ("date_list", "keys");
	my @hashs = ("order");
	my @hash_with_keys = ("csv_data", "key_items");

	%$dst_cdp = %$cdp;
	foreach my $array_item (@arrays){
		@{$dst_cdp->{$array_item}} = @{$cdp->{$array_item}};
	}
	foreach my $hash_item (@hashs){
		%{$dst_cdp->{$hash_item}} = %{$cdp->{$hash_item}};
	}

	foreach my $hwk (@hash_with_keys){
		my $src = $cdp->{$hwk};
		my $dst = $dst_cdp->{$hwk};
		foreach my $key (@$target_keys){
			@{$src->{$key}} = @{$dst->{$key}};
		}
	}
}

#
#	Add Average
#
sub	add_average
{
	my ($cdp, $target_col, $name) = @_;
	$name = $name // "avr";

	#
	#	Calc total
	#
	my $csv_data = $cdp->{csv_data};
	my $key_items = $cdp->{key_items};

	my $dates = $cdp->{dates};
	my @keys = @{$cdp->{keys}};						# Item No for gen HASH Key
	my $key_dlm = $cdp->{key_dlm} // $DEFAULT_KEY_DLM;
	my %ak_list = ();
	foreach my $key (keys %$csv_data){
		my @avr_key_items = (@{$key_items->{$key}});	# generate average key items
		$avr_key_items[$target_col] = $name;

		my @gen_key = ();							# generate average key
		foreach my $n (@keys){
			my $itm = $avr_key_items[$n];
			push(@gen_key, $itm);
		}
		my $ak = join($key_dlm, @gen_key);			# set key_name
		$ak_list{$ak}++;							# set average key list

		if(! defined $csv_data->{$ak}){				# initail average data
			$csv_data->{$ak}= [];					# set csv data
			$key_items->{$ak} = [@avr_key_items];	# set key data
		}

		my $csvp = $csv_data->{$key};				# add data to average
		my $avr_csvp = $csv_data->{$ak};
		for(my $i = 0; $i <= $dates; $i++){
			my $v = $csvp->[$i] // 0;
			my $va = $avr_csvp->[$i] // 0;
			$v = 0 if($v eq "");
			$va = 0 if($va eq "");
			#dp::dp "$i: $key -> [$v]  $ak -> [$va]\n";
			$avr_csvp->[$i] = $v + $va;
		}
	}

	#
	#	Total to average
	#
	foreach my $ak (keys %ak_list){
		my $avr_csvp = $csv_data->{$ak};
		for(my $i = 0; $i <= $dates; $i++){
			my $va = $avr_csvp->[$i];
			$avr_csvp->[$i] = $va / $ak_list{$ak};
		}
	}
	#&dump_cdp($cdp, {ok => 0});
}

#
#
#	&gen_html($cdp, $GRAPH_PARAMS);
#
sub	gen_html
{
	my ($cdp, $gdp) = @_;

	my $date_list = $cdp->{date_list};
	my $csv_data = $cdp->{csv_data};
	my $graph_params = $gdp->{graph_params};
	my $src_url = $cdp->{src_url};

	my $html_file = $gdp->{html_file};
	my $png_path = $gdp->{png_path};
	my $png_rel_path = $gdp->{png_rel_path};

	my $CSS = $config::CSS;
	my $class = $config::CLASS;

	open(HTML, ">$html_file") || die "Cannot create file $html_file";
	binmode(HTML, ":utf8");

	print HTML "<HTML>\n";
	print HTML "<HEAD>\n";
	print HTML "<TITLE> " . $gdp->{html_title} . "</TITLE>\n";
	print HTML $CSS;
	print HTML "</HEAD>\n";
	print HTML "<BODY>\n";
	my $now = csvlib::ut2d4(time, "/") . " " . csvlib::ut2t(time, ":");

	print HTML '<h3>Data Source： <a href="' . $cdp->{main_url} . '" target="blank"> ' . $gdp->{html_title} . "</a></h3>\n";

	foreach my $gp (@$graph_params){
		last if($gp->{dsc} eq $gdp->{END_OF_DATA});

		&csv2graph($cdp, $gdp, $gp);

		print HTML "<span class=\"c\">$now</span><br>\n";
		print HTML '<img src="' . $png_rel_path . "/" . $gp->{plot_png} . '">' . "\n";
		print HTML "<br>\n";
	
		#
		#	Lbale name on HTML for search
		#
		my $dst_dlm = $gdp->{dst_dlm} // "\t";
		my $csv_file = $gdp->{png_path} . "/" . $gp->{plot_csv};
		open(CSV, $csv_file) || die "canot open $csv_file";
		binmode(CSV, ":utf8");
		my $l = <CSV>;
		close(CSV);
		$l =~ s/[\r\n]+$//;
		my @lbl = split($dst_dlm, $l);
		shift(@lbl);

		my $lcount = 10;
		print HTML "<span class=\"c\">\n";
		print HTML "<table>\n<tbody>\n";
		for (my $i = 0; $i < $#lbl; $i += $lcount){
			print HTML "<tr>";
			for(my $j = 0; $j < $lcount; $j++){
				last if(($i + $j) > $#lbl);
				print HTML "<td>" . $lbl[$i+$j] . "</td>";
				#dp::dp "HTML LABEL: " . $lbl[$i+$j] . "\n";
			}
			print HTML "</tr>\n";
		}
		print HTML "</tbody>\n</table>\n";
		print HTML "</span>\n";

		print HTML "<span $class> <a href=\"$src_url\" target=\"blank\"> Data Source (CSV) </a></span>\n";
		#
		#	References
		#
		my @refs = (join(":", "PNG", $png_rel_path . $gp->{plot_png}),
					join(":", "CSV", $png_rel_path . $gp->{plot_csv}),
					join(":", "PLT", $png_rel_path . $gp->{plot_cmd}),
		);
		print HTML "<hr>\n";
		print HTML "<span $class>";
		foreach my $r (@refs){
			my ($tag, $path) = split(":", $r);
			print HTML "$tag:<a href=\"$path\" target=\"blank\">$path</a>\n"; 
		}
		print HTML "<br>\n" ;
		print HTML "</span>\n";
		print HTML "<br><hr>\n\n";
	}
	print HTML "</BODY>\n";
	print HTML "</HTML>\n";
	close(HTML);
}

sub	dup_csv
{
	my ($cdp, $work_csv, $target_keys) = @_;

	my $csv_data = $cdp->{csv_data};
	#dp::dp "dup_csv: cdp[$cdp] csv_data : $csv_data\n";
	$target_keys = $target_keys // "";
	if(! $target_keys){
		my @tgk = ();
		my $csv_data = $cdp->{csv_data};
		#dp::dp ">>dup_csv cdp[$cdp] csv_data[$csv_data]\n";
		foreach my $k (keys %$csv_data){
			push(@tgk, $k);
		}
		#@$target_keys = (keys %$csv_data);
		#dp::dp "DUP.... " . join(",", @tgk) . "\n";
		$target_keys = \@tgk;
		#exit;
	}
	foreach my $key (@$target_keys){						#
		$work_csv->{$key} = [];
		#dp::dp "$key: $csv_data->{$key}\n";
		push(@{$work_csv->{$key}}, @{$csv_data->{$key}});
	}
}

#
#	Generate Graph fro CSV_DATA and Graph Parameters
#
sub	csv2graph
{
	my($cdp, $gdp, $gp) = @_;
	my $csv_data = $cdp->{csv_data};

	#
	#	Set Date Infomation to Graph Parameter
	#
	my $start_date = &date_calc(($gp->{start_date} // ""), $FIRST_DATE, $cdp->{dates}, $cdp->{date_list});
	my $end_date   = &date_calc(($gp->{end_date} // ""),   $LAST_DATE, $cdp->{dates}, $cdp->{date_list});
	#dp::dp "START_DATE: $start_date, END_DATE: $end_date\n";
	$gp->{start_date} = $start_date;
	$gp->{end_date} = $end_date;
	&date_range($cdp, $gdp, $gp); 						# Data range (set dt_start, dt_end (position of array)

	#
	#	Set File Name
	#
	my $fname = $gp->{fname} // "";
	if(! $fname){
		$fname = join(" ", $gp->{dsc}, $gp->{static}, $gp->{start_date});
		$fname =~ s/[\/\.\*\ #]/_/g;
		$fname =~ s/\W+/_/g;
		$fname =~ s/__+/_/g;
		$fname =~ s/^_//;
		$gp->{fname} = $fname;
	}
	$gp->{plot_png} = $gp->{plot_png} // "$fname.png";
	$gp->{plot_csv} = $gp->{plot_csv} // "$fname-plot.csv.txt";
	$gp->{plot_cmd} = $gp->{plot_cmd} // "$fname-plot.txt";

	
	#
	#	select data and generate csv data
	#
	my @target_keys = ();
	&select_keys($cdp, $gp->{target_col}, \@target_keys);	# select data for target_keys
	if($#target_keys < 0){
		dp::dp "WARNING: No data $cdp->{title} / keys:" . join("; ", @{$gp->{target_col}}) . "\n";
		return 0;
	}

	my %work_csv = ();									# copy csv data to work csv
	&dup_csv($cdp, \%work_csv, \@target_keys);
	
	if($gp->{static} eq "rlavr"){ 						# Rolling Average
		&rolling_average($cdp, \%work_csv, $gdp, $gp);
	}
	elsif($gp->{static} eq "ern"){ 						# Rolling Average
		&ern($cdp, \%work_csv, $gdp, $gp);
	}

	#
	#	Sort target record
	#
	my @lank = ();
	@lank = (@{$gp->{lank}}) if(defined $gp->{lank});
	$lank[0] = 1 if(defined $lank[0] && ! $lank[0]);
	my $lank_select = (defined $lank[0] && defined $lank[1] && $lank[0] && $lank[1]) ? 1 : "";

	my @sorted_keys = ();								# sort
	if($lank_select){
		&sort_csv($cdp, \%work_csv, $gp, \@target_keys, \@sorted_keys);
	}
	else {
		my $load_order = $cdp->{load_order};
		@sorted_keys = @$load_order;		# no sort, load Order
	}

	my $order = $cdp->{order};							# set order of key
	my $n = 1;
	foreach my $k (@sorted_keys){
		$order->{$k} = ($lank_select) ? $n : 1;
		$n++;
	}

	#
	#	Genrarte csv file and graph (png)
	#
	my @output_keys = ();
	foreach my $key (@sorted_keys){
		next if($lank_select && ($order->{$key} < $lank[0] || $order->{$key} > $lank[1]));
		push(@output_keys, $key);
	}
	my $csv_for_plot = &gen_csv_file($cdp, $gdp, $gp, \%work_csv, \@output_keys);		# Generate CSV File

	&graph($csv_for_plot, $cdp, $gdp, $gp);					# Generate Graph
	return 1;
}


#
#	Generate CSV File
#
sub	gen_csv_file
{
	my($cdp, $gdp, $gp, $work_csvp, $output_keysp) = @_;
	my $fname = $gp->{fname};
	my $date_list = $cdp->{date_list};
	my $dst_dlm = $gdp->{dst_dlm};
	my $dt_start = $gp->{dt_start};
	my $dt_end = $gp->{dt_end};

	#dp::dp "[$dt_start][$dt_end]\n";
	my $csv_for_plot = $gdp->{png_path} . $gp->{plot_cmd}; #"/$fname-plot.csv.txt";
	#dp::dp "### $csv_for_plot\n";
	open(CSV, "> $csv_for_plot") || die "cannot create $csv_for_plot";
	binmode(CSV, ":utf8");

	my $order = $cdp->{order};
	my @csv_label = ();
	foreach my $k (@$output_keysp){
		my $label = join(":", $order->{$k}, $k);
		push(@csv_label, $label);
	}
	print CSV join($dst_dlm, "#date", @csv_label) . "\n";

	for(my $dt = $dt_start; $dt <= $dt_end; $dt++){
		my @w = ();
		foreach my $key (@$output_keysp){
			my $csv = $work_csvp->{$key};
			my $v = $csv->[$dt] // "";
			$v = 0 if($v eq "");
			push(@w, $v);
		}
		if(! defined $date_list->[$dt]){
			dp::dp "### undefined date_list : $dt\n";
		}
		print CSV join($dst_dlm, $date_list->[$dt], @w) . "\n";
	}
	close(CSV);

	return $csv_for_plot;
}

#
#	SORT
#
sub	sort_csv
{
	my ($cdp, $cvdp, $gp, $target_keysp, $sorted_keysp) = @_;
	my $dt_start = $gp->{dt_start};
	my $dt_end = $gp->{dt_end};

	my %SORT_VAL = ();
	my $src_csv = $cdp->{src_csv} // "";
	foreach my $key (@$target_keysp){
		if(! $key){
			dp::dp "WARING at sort_csv: empty key [$key]\n";
			next;
		}

		my $csv = $cvdp->{$key};
		my $total = 0;
		for(my $dt = $dt_start; $dt <= $dt_end; $dt++){
			my $v = $csv->[$dt] // 0;
			$v = 0 if(! $v);
			$total += $v ;
		}
		$SORT_VAL{$key} = $total;
		if($src_csv && (! defined $src_csv->{$key})){
			dp::dp "WARING at sort_csv: No src_csv definition for [$key]\n";
		}
	}
	if(! $src_csv){		# Marged CSV
		@$sorted_keysp = (sort {$SORT_VAL{$b} <=> $SORT_VAL{$a}} keys %SORT_VAL);
	}
	else {
		@$sorted_keysp = (sort {$src_csv->{$a} <=> $src_csv->{$b} or $SORT_VAL{$b} <=> $SORT_VAL{$a}} keys %SORT_VAL);
	}
}

#
#	Data range
#
sub	date_range
{
	my($cdp, $gdp, $gp) = @_;

	my $date_list = $cdp->{date_list};
	#dp::dp "DATE: " . join(", ", $gp->{start_date}, $gp->{end_date}, "#", @$date_list) . "\n";
	my $dt_start = csvlib::search_listn($gp->{start_date}, @$date_list);
	if($dt_start < 0){
		dp::dp "WARNING: Date $gp->{start_date} is not in the data\n";
		$dt_start = 1;
	}
	$dt_start--;
	$dt_start = 0 if($dt_start < 0 || $dt_start > $cdp->{dates});
	my $dt_end   = csvlib::search_listn($gp->{end_date},   @$date_list);
	if($dt_end < 0){
		dp::dp "WARNING: Date $gp->{start_date} is not in the data\n";
		$dt_end = $dt_end + 1;
	}
	$dt_end--;
	$dt_end = $cdp->{dates} if($dt_end < 0 || $dt_end > $cdp->{dates});
	$gp->{dt_start} = $dt_start;
	$gp->{dt_end}   = $dt_end;
}


#
#	Select CSV DATA
#
sub	select_keys
{
	my($cdp, $target_colp, $target_keys) = @_;

	my @target_col = ();
	my @non_target_col = ();
	my $condition = 0;
	my $clm = 0;
	foreach my $sk (@$target_colp){
		#dp::dp "Target col $sk\n";
		if($sk){
			my ($tg, $ex) = split(/ *\! */, $sk);
			my @w = split(/\s*,\s*/, $tg);
			push(@target_col, [@w]);
			$condition++;

			@w = ();
			if($ex){
				@w = split(/\s*,\s*/, $ex);
			}
			push(@non_target_col, [@w]);
			#dp::dp "NoneTarget:[$clm] " . join(",", @w) . "\n";
		}
		else {
			push(@target_col, []);
			push(@non_target_col, []);
		}
		$clm++;
	}

	dp::dp "Condition: $condition " . join(", ", @$target_colp) . "\n";
	#dp::dp "Nontarget: " . join(",", @non_target_col) . "\n";
	my $key_items = $cdp->{key_items};
	foreach my $key (keys %$key_items){
		my $key_in_data = $key_items->{$key};
		my $res = &check_keys($key_in_data, \@target_col, \@non_target_col, $key);
		#dp::dp "[$key:$condition:$res]\n" if($res > 1);
		#dp::dp "### " . join(", ", (($res >= $condition) ? "#" : "-"), $key, $res, $condition, @$key_in_data) . "\n";
		next if ($res < 0);

		if($res >= $condition){
			push(@$target_keys, $key);
			if($VERBOSE){
				dp::dp "### " . join(", ", (($res >= $condition) ? "#" : "-"), $key, $res, $condition, @$key_in_data) . "\n";
			}
		}
	}
	#dp::dp "## TARGET_KEYS " . join(", ", @$target_keys) . "\n";
	return(scalar(@$target_keys) - 1);
}

#
#	Check keys for select
#
sub	check_keys
{
	my($key_in_data, $target_col, $non_target_col, $key) = @_;

	if(!defined $key_in_data){
		dp::dp "###!!!! key in data not defined [$key]\n";
	}
	#dp::dp "key_in_data: $key_in_data " . scalar(@$key_in_data) . " [$key]\n";
	my $kid = join(",", @$key_in_data);
	my $condition = 0;
	my $cols = scalar(@$target_col) - 1;

	for(my $kn = 0; $kn <= $cols; $kn++){
		next if(! ($target_col->[$kn] // ""));			# no key
		next if(! ($non_target_col->[$kn] // ""));		# no key
		
		#dp::dp ">>> " . join(",", $key_in_data->[$kn] . ":", @{$non_target_col->[$kn]}) . "\n" if($kid =~ /country.*Japan/);
		if(scalar(@{$non_target_col->[$kn]}) > 0){			# Check execlusion
			if(csvlib::search_listn($key_in_data->[$kn], @{$non_target_col->[$kn]}) >= 0){
				#dp::dp "EXECLUSION: $kid \n";
				$condition = -1;							# hit to execlusion
				last;
			}
			elsif(scalar(@{$target_col->[$kn]}) <= 0){		# Only execlusions were set (no specific target)
				$condition++;				
				next;
			}
		}

		#dp::dp join(", ", "data ", $kn, $key_in_data->[$kn], @{$target_col->[$kn]}) . "\n";# if($kid =~ /Tokyo/);
		if(csvlib::search_listn($key_in_data->[$kn], @{$target_col->[$kn]}) >= 0){
			$condition++ 									# Hit to target
		}
	}
	#dp::dp "----> $condition: $kid\n" if($kid =~ /country.*Japan/);
	return $condition;
}

#
#	Calc Rolling Average
#
sub	rolling_average
{
	my($cdp, $work_csvp, $gdp, $gp) = @_;

	my $avr_date = $cdp->{avr_date} // $DEFAULT_AVR_DATE;
	foreach my $key (keys %$work_csvp){
		my $dp = $work_csvp->{$key};
		for(my $i = scalar(@$dp) - 1; $i >= $avr_date; $i--){
			my $tl = 0;
			for(my $j = $i - $avr_date + 1; $j <= $i; $j++){
				my $v = $dp->[$j] // 0;
				$v = 0 if(!$v);
				$tl += $v;
			}
			#dp::dp join(", ", $key, $i, $csv->[$i], $tl / $avr_date) . "\n";
			my $avr = sprintf("%.3f", $tl / $avr_date);
			$dp->[$i] = $avr;
		}
	}
}	

#
#	combert csv data to ERN
#
sub	comvert2rlavr
{
	my($cdp, $p) = @_;

	my $gdp = {};
	my $gp = {};
	my %work_csv = ();
	my $work_csvp = \%work_csv;

	&dup_csv($cdp, $work_csvp, "");
	#&dump_csv_data($work_csvp, {ok => 1, lines => 5, message => "comver2rlavr:dup"}) if(1);
	&rolling_average($cdp, $work_csvp, $gdp, $gp);
	#&dump_csv_data($work_csvp, {ok => 1, lines => 5, message => "comver2rlavr:ern"}) if(1);
	$cdp->{csv_data} = "";
	$cdp->{csv_data} = $work_csvp;
}

#
#	combert csv data to ERN
#
sub	comvert2ern
{
	my($cdp, $p) = @_;

	my $gp  = {
		lp => $p->{lp} // $config::RT_LP,
		ip => $p->{ip} // $config::RT_IP,
	};
	my $gdp = {};
	my %ern_csv = ();
	my $ern_csvp = \%ern_csv;

	&dup_csv($cdp, $ern_csvp, "");
	#&dump_csv_data($ern_csvp, {ok => 1, lines => 5, message => "comver2ern:dup"}) if(1);

	&ern($cdp, $ern_csvp, $gdp, $gp);
	#&dump_csv_data($ern_csvp, {ok => 1, lines => 5, message => "comver2ern:ern"}) if(1);
	$cdp->{csv_data} = "";
	$cdp->{csv_data} = $ern_csvp;
}

#
#	ERN
#
sub	ern
{
	my($cdp, $work_csvp, $gdp, $gp) = @_;

	my $lp = $gp->{lp} // ($gdp->{lp} // $config::RT_LP);
	my $ip = $gp->{ip} // ($gdp->{ip} // $config::RT_IP);	# 5 感染期間
	my $avr_date = $cdp->{avr_date} // $DEFAULT_AVR_DATE;

	dp::dp "ERN: $lp, $ip\n";
	my %rl_avr = ();
	&rolling_average($cdp, $work_csvp, $gdp, $gp);

	my $date_number = $cdp->{dates};
	my $rate_term = $date_number - $ip - $lp;
	my $date_term = $rate_term - 1;
	foreach my $key (keys %$work_csvp){
		my $dp = $work_csvp->{$key};
		my @ern = ();
		my $dt = 0;
		for($dt = 0; $dt < $rate_term; $dt++){
			my $ppre = $ip * $dp->[$dt+$lp+$ip];
			my $pat = 0;
			for(my $d = $dt + 1; $d <= ($dt + $ip); $d++){
				$pat += $dp->[$d];
			}
			# print "$country $dt: $ppre / $pat\n";
			if($pat > 0){
				$ern[$dt] =  int(1000 * $ppre / $pat) / 1000;
			}
			else {
				$ern[$dt] =  0;
			}
		}
		for(; $dt <= $date_number; $dt++){
			$ern[$dt] = "NaN";
		}
		@$dp = @ern;
		#dp::dp join(",", @$dp[0..5]). "\n";
	}

}	


#
#	Generate Glaph from csv file by gnuplot
#
sub	graph
{
	my($csv_for_plot, $cdp, $gdp, $gp) = @_;

	my $title = join(" ", $gp->{dsc}, $gp->{static}, "($LAST_DATE)");
	#dp::dp "#### " . join(",", "[" . $p->{lank}[0] . "]", @lank) . "\n";

	my $fname = $gdp->{png_path} . "/" . $gp->{fname};
	my $csvf = $fname . "-plot.csv.txt";
	my $pngf = $fname . ".png";
	my $plotf = $fname. "-plot.txt";

	my $dlm = $gdp->{dst_dlm};

	my $time_format = $gdp->{timefmt};
	my $format_x = $gdp->{format_x};
	my $term_x_size = $gdp->{term_x_size};
	my $term_y_size = $gdp->{term_y_size};

	my $start_date = $gp->{start_date} // "NONE";
	my $end_date = $gp->{end_date} // "NONE";

	my $start_ut = csvlib::ymds2tm($start_date);
	my $end_ut = csvlib::ymds2tm($end_date);
	my $dates = ($end_ut - $start_ut) / (60 * 60 * 24);
	my $xtics = 60 * 60 * 24 * 7;
	if($dates < 93){
		$xtics = 1 * 60 * 60 * 24;
	}
	elsif($dates < 120){
		$xtics = 2 * 60 * 60 * 24;
	}

	#dp::dp "ymin: [$gdp->{ymin}]\n";
	my $ymin = $gp->{ymin} // ($gdp->{ymin} // "");
	my $ymax = $gp->{ymax} // ($gdp->{ymax} // "");
	my $yrange = ($ymin ne ""|| $ymax ne "") ? "set yrange [$ymin:$ymax]" : "# yrange";
	my $ylabel = $gp->{ylabel} // ($gdp->{ylabel} // "");
	$ylabel = "set ylabel '$ylabel'"  if($ylabel);

	my $y2min = $gp->{y2min} // ($gdp->{y2min} // "");
	my $y2max = $gp->{y2max} // ($gdp->{y2max} // "");
	my $y2range = ($y2min ne ""|| $y2max ne "") ? "set y2range [$y2min:$y2max]" : "# y2range";
	my $y2label = $gp->{y2label} // ($gdp->{y2label} // "");
	$y2label = ($y2label) ? "set y2label '$y2label'" : "# y2label";
	my $y2tics = "set y2tics";		# Set y2tics anyway

	#
	#	Draw Graph
	#
	my $PARAMS = << "_EOD_";
#!/usr/bin/gnuplot
#csv_file = $csvf
set datafile separator '$dlm'
set xtics rotate by -90
set xdata time
set timefmt '$time_format'
set format x '$format_x'
set mxtics 2
set mytics 2
#set grid xtics ytics mxtics mytics
set key below
set title '$title' font "IPAexゴシック,12" enhanced
#set xlabel 'date'
$ylabel
$y2label
#
set xtics $xtics
set xrange ['$start_date':'$end_date']
set grid
$yrange
$y2range
$y2tics

set terminal pngcairo size $term_x_size, $term_y_size font "IPAexゴシック,8" enhanced
set output '/dev/null'
plot #PLOT_PARAM#
Y_MIN = GPVAL_Y_MIN
Y_MAX = GPVAL_Y_MAX

set output '$pngf'
#ARROW#
plot #PLOT_PARAM#
exit
_EOD_

	#
	#	Gen Plot Param
	#
	my @p= ();
	my $pn = 0;

	open(CSV, $csvf) || die "cannot open $csvf";
	binmode(CSV, ":utf8");
	my $l = <CSV>;
	close(CSV);
	$l =~ s/[\r\n]+$//;
	my @label = split(/$dlm/, $l);
	#dp::dp "### $csvf: $l\n";
	dp::dp "### $csvf\n";

	my $src_csv = $cdp->{src_csv} // "";
	my $y2_source = $gdp->{y2_source} // "";
	#dp::dp "soruce_csv[$src_csv] $y2_source\n";
	$src_csv = "" if($y2_source eq "");

	for(my $i = 1; $i <= $#label; $i++){
		my $key = $label[$i];
		$key =~ s/^[0-9]+://;
		#dp::dp "### $i: $key\n";
		$pn++;

		my $axis = "";
		my $dot = "";
		if($y2_source ne ""){		#####
			#dp::dp "csv_source: $key [" . $src_csv->{$key} . "]\n";
			#dp::dp "csv_source: $key [" . $src_csv . "]\n";
			$axis =	"axis x1y1";
			#dp::dp "$src_csv->{$key},$y2_source:\n";
			if($src_csv->{$key} == $y2_source) {
				$axis = "axis x1y2" ;
				$dot = "dt (7,3)";
			}
		}
		#dp::dp "axis:[$axis]\n";
		#my $pl = sprintf("'%s' using 1:%d $axis with lines title '%d:%s' linewidth %d $dot", 
		#				$csvf, $i + 1, $i, $label[$i], ($pn < 7) ? 2 : 1);
		my $pl = sprintf("'%s' using 1:%d $axis with lines title '%s' linewidth %d $dot", 
						$csvf, $i + 1, $label[$i], ($pn < 7) ? 2 : 1);
		push(@p, $pl);
	}
	#push(@p, "0 with lines dt '-' title 'base line'");
	my $additional_plot = $gp->{additional_plot} // ($gdp->{additional_plot} // "");
    if($additional_plot){
        #dp::dp "additional_plot: " . $additional_plot . "\n";
		push(@p, $additional_plot);
    }

	my $plot = join(",", @p);
	$PARAMS =~ s/#PLOT_PARAM#/$plot/g;

	my $date_list = $cdp->{date_list};
	my $dt_start = $gp->{dt_start};
	my $dt_end = $gp->{dt_end};
	#dp::dp join(",", @$date_list) . "\n";
	#dp::dp "###" . join(",", $dt_start, $dt_end, $date_list->[$dt_start], $date_list->[$dt_end], scalar(@$date_list)) . "\n";
	if(1){
		my $RELATIVE_DATE = 7;
		my @aw = ();

		for(my $dn = $gp->{dt_end} - $RELATIVE_DATE; $dn > $gp->{dt_start}; $dn -= $RELATIVE_DATE){
			my $mark_date = $date_list->[$dn];
			
			#dp::dp "ARROW: $dn, [$mark_date]\n";
			my $a = sprintf("set arrow from '%s',Y_MIN to '%s',Y_MAX nohead lw 1 dt (3,7) lc rgb \"dark-red\"",
				$mark_date,  $mark_date);
			push(@aw, $a);
		}
		my $arw = join("\n", @aw);
		#dp::dp "ARROW: $arw\n";
		$PARAMS =~ s/#ARROW#/$arw/;	
	}

	open(PLOT, ">$plotf") || die "cannto create $plotf";
	binmode(PLOT, ":utf8");
	print PLOT $PARAMS;
	close(PLOT);

	#system("cat $plotf");
	dp::dp "gnuplot $plotf\n";
	system("gnuplot $plotf");
	#dp::dp "-- Done\n";
}

sub	date_calc
{
	my($date, $default, $max, $list) = @_;
			
	$date = $date // "";
	$date = $default if($date eq "");

	#dp::dp "[[$date,$default,$max,$list]]\n";
	if(! ($date =~ /[0-9][\-\/][0-9]/)){
		#dp::dp "[[$date]]\n";
		if($date < 0){
			$date = $max + $date;
		}
		if($date < 0 || $date > $max){
			dp::dp "Error at date $date\n";
			$date = 0;
		}
		#dp::dp "[[$date]]\n";
		$date = $list->[$date];
		#dp::dp "[[$date]]\n";
	}
	return $date;
}

1;
