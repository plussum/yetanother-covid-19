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
use Data::Dumper;
use config;
use csvlib;

#binmode(STDOUT, ":utf8");

my $VERBOSE = 0;
my $DEFAULT_AVR_DATE = 7;
my $KEY_DLM = "-";					# Initial key items
our $CDP = {};

my $FIRST_DATE = "";
my $LAST_DATE  = "";

sub	new
{
	my ($cdp) = @_;
	
	$CDP = $cdp;

	$CDP->{csv_data} = {},
	$CDP->{date_list} = [],
	$CDP->{dates} = 0,
	$CDP->{order} = {},
	$CDP->{key_items} = {};
	$CDP->{avr_date} = ($CDP->{avr_date} // $DEFAULT_AVR_DATE),

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
	if($direct =~ /vertical/i){
		&load_csv_vertical($cdp);
	}
	else {
		&load_csv_holizontal($cdp);
	}

	#
	#	DEBUG: Dump data 
	#
	&dyump_csv($cdp) if(0);
	
	return 0;
}

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
	$cdp->{dates} = scalar(@$date_list) - 1;
	$FIRST_DATE = $date_list->[0];
	$LAST_DATE = $date_list->[$#w - $data_start];

	#dp::dp join(",", "# " . $TGK, @LABEL) . "\n";
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
		my $k = join($KEY_DLM, @gen_key);				# set key_name
		$csv_data->{$k}= [@items[$data_start..$#items]];	# set csv data
		$key_items->{$k} = [@items[0..($data_start - 1)]];	# set csv data
		
		$ln++;
		#last if($ln > 50);
	}
	close(FD);
	return 0;
}

sub	load_csv_vertical
{
	my ($cdp) = @_;

	my $csv_file = $cdp->{csv_file};
	my $data_start = $cdp->{data_start};
	my $src_dlm = $cdp->{src_dlm};
	my $date_list = $cdp->{date_list};
	my $csv_data = $cdp->{csv_data};
	my $key_items = $cdp->{key_items};
	my @keys = @{$cdp->{keys}};
	my $timefmt = $cdp->{timefmt} // "%Y-%m-%d";

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
		$csv_data->{$k}= [];		# set csv data array
		$key_items->{$k} = [$k];
	}
	#dp::dp join(",", "# " , @key_list) . "\n";

	my $ln = 0;
	while(<FD>){
		s/[\r\n]+$//;
		my $line = decode('utf-8', $_);
		my ($date, @items) = split(/$src_dlm/, $line);
	
		$date =~ s#/#-#g if($timefmt eq "%Y/%m/%d");
		$date_list->[$ln] = $date;
		#dp::dp "date:$ln $date\n";
	
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

sub	dump_csv
{
	my ($cdp, $ok) = @_;

	$ok = $ok // "";
	my $csv_data = $cdp->{csv_data};
	my $key_items = $cdp->{key_items};
	dp::dp "Dump CSV Data\n";
	foreach my $k (keys %$csv_data){
		my @w = @{$csv_data->{$k}};
		my @k = @{$key_items->{$k}};
		next if($#w < 0);

		dp::dp "[$k](" . join(",", @k) . "]";
		if(! defined $w[1]){
			dp::dp " --> csv_data is not assigned\n";
		}
		if($ok){
			dp::dp join(", ", $k, @w[0..5]) . "\n";
		}
	}
}
#
#	Marge csvdef
#
sub	marge_csv
{
	my ($marge, @src_csv) = @_;

	&new($marge);

	my @csv_info = ();
	my $date_start = "0000-00-00";
	foreach my $cdp (@src_csv){
		my $dt = $cdp->{date_list}->[0];
		dp::dp "[$dt]\n";
		$date_start = $dt if($dt gt $date_start );
	}
	my $date_end = "9999-99-99";
	foreach my $cdp (@src_csv){
		my $dates = $cdp->{dates};
		my $dt = $cdp->{date_list}->[$dates];
		$date_end = $dt if($dt le $date_end );
	}
	dp::dp join(", ", $date_start, $date_end) . "\n";

	#
	#	Check Start date(max) and End date(min)
	#
	for(my $i = 0; $i < $#src_csv; $i++){
		$csv_info[$i] = {};
		my $infop = $csv_info[$i];
		my $cdp = $src_csv[$i];
		my $date_list = $cdp->{date_list};

		my $dt_start = csvlib::search_list($date_start, @$date_list);
		if(! $dt_start){
			dp::dp "WARNING: Date $date_start is not in the data\n";
			$dt_start = 1;
		}
		$dt_start--;
		$infop->{date_start} = $dt_start;

		my $dt_end = csvlib::search_list($date_end, @$date_list);
		if(! $dt_end){
			dp::dp "WARNING: Date $date_end is not in the data\n";
			$dt_end = 1;
		}
		$dt_end--;
		$infop->{date_end} = $dt_end;
	
		#dp::dp join(", ", $dt_start, $dt_end) . "\n";
	}

	#
	#	Marge
	#
	my $m_csv_data = $marge->{csv_data};
	my $m_date_list = $marge->{date_list};
	my $m_key_items = $marge->{key_items};

	my $infop = $csv_info[0];
	my $start = $infop->{date_start};
	my $end   = $infop->{date_end};
	my $dates = $end - $start;
	$marge->{dates} = $dates;

	my $date_list = $src_csv[0]->{date_list};
	@{$m_date_list} = @{$date_list}[$start..$end];
	#dp::dp "start:$start, end:$end dates:$dates\n";
	#dp::dp "## src:" . join(",", @{$date_list} ) . "\n";
	#dp::dp "## dst:" . join(",", @{$m_date_list} ) . "\n";

	for(my $csvn = 0; $csvn <= $#src_csv; $csvn++){
		my $cdp = $src_csv[$csvn];
		my $csv_data = $cdp->{csv_data};
		my $infop = $csv_info[$csvn];
		
		foreach my $k (keys %$csv_data){
			$m_csv_data->{$k} = [];
			my $dp = $csv_data->{$k};
			my $mdp = $m_csv_data->{$k};
			if(! defined $dp->[1]){
				dp::dp "WARNING: no data in [$k]\n";
			}
			for(my $i = 0; $i < $dates; $i++){
				$mdp->[$i] = $dp->[$i] // 0;		# may be something wrong
			}
			#@{$m_csv_data->{$k}} = @{$csv_data->{$k}}[$start..$end];
			#dp::dp ">> src" . join(",", $k, @{$csv_data->{$k}} ) . "\n";
			#dp::dp ">> dst" . join(",", $k, @{$m_csv_data->{$k}} ) . "\n";
		}
	} 
	
	&dump_csv($marge, 1);
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

		my $start_date = &date_calc(($gp->{start_date} // ""), $FIRST_DATE, $cdp->{dates}, $cdp->{date_list});
		my $end_date   = &date_calc(($gp->{end_date} // ""),   $LAST_DATE, $cdp->{dates}, $cdp->{date_list});
		#dp::dp "START_DATE: $start_date, END_DATE: $end_date\n";

		$gp->{start_date} = $start_date;
		$gp->{end_date} = $end_date;

		my $fname = join(" ", $gp->{dsc}, $gp->{static}, $start_date);

		$fname =~ s/[\/\.\*\ ]/_/g;
		$gp->{fname} = $fname;

		&csv2graph($cdp, $gdp, $gp);

		print HTML "<span class=\"c\">$now</span><br>\n";
		print HTML "<img src=\"../PNG/$fname.png\">\n";
		print HTML "<br>\n";
		print HTML "<span $class> <a href=\"$src_url\" target=\"blank\"> Data Source (CSV) </a></span>\n";
		print HTML "<hr>\n";
	
		print HTML "<span $class>";

		my @refs = (join(":", "PNG", $png_rel_path . "/$fname.png"),
					join(":", "CSV", $png_rel_path . "/$fname-plot.csv.txt"),
					join(":", "PLT", $png_rel_path . "/$fname-plot.txt"),
		);
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


sub	csv2graph
{
	my($cdp, $gdp, $gp) = @_;

	my $csv_data = $cdp->{csv_data};
	my $fname = $gp->{fname};
	my $dst_dlm = $gdp->{dst_dlm};

	my @lank = ();
	@lank = (@{$gp->{lank}}) if(defined $gp->{lank});

	my %cvd = ();
	my $cvdp = \%cvd;
	foreach my $key (keys %$csv_data){
		$cvdp->{$key} = [];
		push(@{$cvdp->{$key}}, @{$csv_data->{$key}});
	}

	#
	#	Rolling Average
	#
	if($gp->{static} eq "rlavr"){
		my $avr_date = $cdp->{avr_date} // $DEFAULT_AVR_DATE;
		my %sort_value = ();	
		foreach my $key (keys %$cvdp){
			my $csv = $cvdp->{$key};
			for(my $i = scalar(@$csv) - 1; $i >= $avr_date; $i--){
				my $tl = 0;
				for(my $j = $i - $avr_date + 1; $j <= $i; $j++){
					my $v = $csv->[$j] // 0;
					$v = 0 if(!$v);
					$tl += $v;
				}
				#dp::dp join(", ", $key, $i, $csv->[$i], $tl / $avr_date) . "\n";
				my $avr = sprintf("%.3f", $tl / $avr_date);
				$csv->[$i] = $avr;
			}
		}
	}
	
	#
	#	Data range
	#
	my $date_list = $cdp->{date_list};
	#dp::dp "DATE: " . join(", ", $gp->{start_date}, $gp->{end_date}, "#", @$date_list) . "\n";
	my $dt_start = csvlib::search_list($gp->{start_date}, @$date_list);
	if(! $dt_start){
		dp::dp "WARNING: Date $gp->{start_date} is not in the data\n";
		$dt_start = 1;
	}
	$dt_start--;
	$dt_start = 0 if($dt_start < 0 || $dt_start > $cdp->{dates});
	my $dt_end   = csvlib::search_list($gp->{end_date},   @$date_list);
	if(! $dt_end){
		dp::dp "WARNING: Date $gp->{start_date} is not in the data\n";
		$dt_end = $dt_end + 1;
	}
	$dt_end--;
	$dt_end = $cdp->{dates} if($dt_end < 0 || $dt_end > $cdp->{dates});
	$gp->{dt_start} = $dt_start;
	$gp->{dt_end}   = $dt_end;

	#
	#	Select by target_col
	#
	my @target_col = ();
	my @non_target_col = ();
	my $condition = 0;
	foreach my $sk (@{$gp->{target_col}}){
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
		}
		else {
			push(@target_col, []);
			push(@non_target_col, []);
		}
	}

	my @target_keys = ();
	my $key_items = $cdp->{key_items};
	foreach my $key (keys %$cvdp){
		#dp::dp "--- " . join(", ", $key, $order->{$key}, @lank, @tga) . "\n" if($key =~ /Japan/);
		my $key_in_data = $key_items->{$key};
		my $res = &check_keys($key_in_data, \@target_col, \@non_target_col);
		#dp::dp "[$key:$condition:$res]\n";
		#dp::dp "### " . join(", ", (($res >= $condition) ? "#" : "-"), $key, $res, $condition, @$key_in_data) . "\n";
		next if($res < $condition);

		push(@target_keys, $key);
	}

	#
	#	Sort 
	#
	my %SORT_VAL = ();
	my @sorted_keys = ();
	my $lank_select = (defined $lank[0] && defined $lank[1] && $lank[0] && $lank[1]) ? 1 : "";
	#dp::dp "### $lank_select\n";
	if($lank_select){
		foreach my $key (@target_keys){
			my $csv = $cvdp->{$key};
			my $total = 0;
			for(my $dt = $dt_start; $dt <= $dt_end; $dt++){
				my $v = $csv->[$dt] // 0;
				$v = 0 if(! $v);
				$total += $v ;
			}
			$SORT_VAL{$key} = $total;
		}
		@sorted_keys = (sort {$SORT_VAL{$b} <=> $SORT_VAL{$a}} keys %SORT_VAL);
	}
	else {
		@sorted_keys = (sort keys %$cvdp);
	}

	my $order = $cdp->{order};
	my $n = 1;
	foreach my $k (@sorted_keys){
		#dp::dp join(":", $k, $n, $SORT_VAL{$k}) . "\n";
		$order->{$k} = ($lank_select) ? $n : 1;
		$n++;
	}
	#my @tga = split(/ *, */, $gp->{target});
	#my @exc = split(/ *, */, $gp->{exclusion});

	#
	#	Genrarte csv file for plot
	#
	my $csv_for_plot = $gdp->{png_path} . "/$fname-plot.csv.txt";
	dp::dp "### $csv_for_plot\n";

	my @target_lank = ();
	foreach my $key (@sorted_keys){
		next if($lank_select && ($order->{$key} < $lank[0] || $order->{$key} > $lank[1]));
		push(@target_lank, $key);
	}
	open(CSV, "> $csv_for_plot") || die "$csv_for_plot";
	binmode(CSV, ":utf8");
	print CSV join($dst_dlm, "#date", @target_lank) . "\n";
	for(my $dt = $dt_start; $dt <= $dt_end; $dt++){
		my @w = ();
		foreach my $key (@target_lank){
			my $csv = $cvdp->{$key};
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

	&graph($csv_for_plot, $cdp, $gdp, $gp);
	return 1;
}

sub	check_keys
{
	my($key_in_data, $target_col, $non_target_col) = @_;

	my $condition = 0;
	my $cols = scalar(@$target_col) - 1;
	for(my $kn = 0; $kn <= $cols; $kn++){
		next if(! ($target_col->[$kn] // ""));			# no key
		next if(! ($non_target_col->[$kn] // ""));		# no key
		
		#return 0 if(csvlib::search_list($key_in_data->[$kn], @{$non_target_col->[$kn]}) eq "");

		#dp::dp join(", ", "data ", $kn, $key_in_data->[$kn], @{$target_col->[$kn]}) . "\n";
		$condition++ if(csvlib::search_list($key_in_data->[$kn], @{$target_col->[$kn]}));
	}
	#dp::dp "----> $condition\n";
	return $condition;
}

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
	my $ylabel = "%";

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
set ylabel '$ylabel'
#
set xtics $xtics
set xrange ['$start_date':'$end_date']
set grid
set yrange [#YRANGE#]
set y2range [#YRANGE#]
set y2tics

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

	for(my $i = 1; $i <= $#label; $i++){
		my $key = $label[$i];
		#dp::dp "### $i: $key\n";
		$pn++;
		my $pl = sprintf("'%s' using 1:%d with lines title '%d:%s' linewidth %d ", 
						$csvf, $i + 1, $i, $label[$i], ($pn < 7) ? 2 : 1);
		push(@p, $pl);
	}
	#push(@p, "0 with lines dt '-' title 'base line'");
	my $additional_plot = $gp->{additional_plot} // ($gdp->{additional_plot} // "");
    if($additional_plot){
        #dp::dp "additional_plot: " . $gplitem->{additional_plot} . "\n";
		push(@p, $additional_plot);
    }
	my $plot = join(",", @p);
	$PARAMS =~ s/#PLOT_PARAM#/$plot/g;

	my $ymin = $gp->{ymin} // ($gdp->{ymin} // "");
	my $ymax = $gp->{ymax} // ($gdp->{ymax} // "");
	#dp::dp "YRANGE: [$ymin:$ymax]\n";
	$PARAMS =~ s/#YRANGE#/$ymin:$ymax/g;	

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

	#dp::dp "-- Do gnuplot $plotf\n";
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
