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
#	CSV_DEF
#		src_url => source_url of data,
#		src_csv => download csv data,
#		keys => [1, 2],		# region, transport
#		date_start => 6,	# 2020/01/13
#		html_title => "Apple Mobility Trends",
#	GRAPH_PARAMN
#		dsc => "Japan"
#		lank => [1,999],
#		graph => "LINE | BOX",
#		statics => "RLAVR",
#		target_area => "Japan,XXX,YYY", 
#		exclusion_are => ""
#
#
use strict;
use warnings;
use utf8;
use Encode 'decode';
use Data::Dumper;
use config;
use csvlib;

binmode(STDOUT, ":utf8");

my $VERBOSE = 0;

my $DOWN_LOAD = 0;
my $DEFAULT_AVR_DATE = 7;

my $SRC_URL_TAG = "https://covid19-static.cdn-apple.com/covid19-mobility-data/2025HotfixDev13/v3/en-us/applemobilitytrends-%04d-%02d-%02d.csv";
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $src_url = sprintf($SRC_URL_TAG, $year + 1900, $mon + 1, $mday);

my $CSV_DEF = {
	title => "Apple Mobility Trends",
	main_url =>  "https://covid19.apple.com/mobility",
	csv_file =>  "$config::WIN_PATH/applemobile/applemobilitytrends.csv.txt",
	src_url => $src_url,		# set

	down_load => \&download,

	src_dlm => ",",
	dst_dlm => "\t",
	keys => [1,2],
	data_start => 6,

	csv_data => [],
	key_list => [],
	label => [],

};
	
my $END_OF_DATA = "###EOD###";
my $GRAPH_PARAMS = {
	html_tilte => $CSV_DEF->{title},
	png_path   => "$config::PNG_PATH",
	png_rel_path => "../";
	html_file => "$config::HTML_PATH/apple_mobile.html",

	avr_date => 7,

	timefmt => '%Y/%m/%d',
	formati_x => '%m/%d',

	term_x_size => 1000,
	term_y_size => 350,

	default_graph => "line",
	END_OF_DATA => $END_OF_DATA,
	graph_params => [
		{dsc => "Japan", lank => [1,999], static => "rlavr", target => "Japan", exclusion => "", start_date => "", end_date => ""},
		{dsc => $END_OF_DATA},
	],
};


#
#	Down Load CSV 
#
sub	download
{
	my ($cdp) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $src_url = $cdp->{src_url};
	my $wget = "wget $src_url -O " . $cdp->{csv_file};
	dp::dp $wget ."\n" if($VERBOSE);
	system($wget);
	return 1;
}

#
#	Lpad CSV File
#
my $cdp = $CSV_DEF;
if($DOWN_LOAD){
	my $download = $cdp->{download};
	$download->($cdp);
}

my $csv_file = $cdp->{csv_file};
my $data_start = $cdp->{data_start};
my $src_dlm = $cdp->{src_dlm};
my $label = $cdp->{csv_data};
my $key_list = $cdp->{key_list};
my $csv_data = $cdp->{csv_data};

my $KEY_DLM = "#-#";					# Initial key items
my @key_items = $cdp->{keys};
for(my $i = 0; $i <= $#key_items; $i++){
	$key_list->[$i] = {};
}

#
#	Load CSV DATA
#
open(FD, $csv_file) || die "Cannot open $csv_file";
my $line = <FD>;
$line =~ s/[\r\n]+$//;
$line = decode('utf-8', $line);
@$label = split(/$src_dlm/, $line);
my $FIRST_DATE = $label->[$data_start];
my $LAST_DATE = $label->[scalar(@$label)-1];

my $ln = 0;
while(<FD>){
	#last if($ln > 50);
	s/[\r\n]+$//;
	my $line = decode('utf-8', $_);
	my @items = split(/$src_dlm/, $line);

	my @gen_key = ();
	foreach my $n (@key_items){		# set key list
		my $itm = $items[$n];
		push(@gen_key, $itm);
		$key_list->[$n]->{$itm} += 1;
	}
	my $k = join($KEY_DLM, @gen_key);				# set key_name
	$csv_data->{$k}= [@items[$data_start..$#items]];	# set csv data
	$ln++;
}
close(FD);

for(my $i = 0; $i < $data_start; $i++){
	shift(@$label);
}
#dp::dp join(",", "# " . $TGK, @LABEL) . "\n";

#
#	MAIN LOOP
#
&gen_html($cdp, $GRAPH_PARAMS);

exit 0;

#
#
#
sub	gen_html
{
	my ($cdp, $gdp) = @_;

	my $label = $cdp->{csv_data};
	my $key_list = $cdp->{key_list};
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

	print HTML "<h3>Data Source： <a href=\"$cdp->{main_url}\" target=\"blank\"> $cdp->{html_title} </a></h3>\n";

	foreach my $gp (@$graph_params){
		my $start_date = $gp->{start_date} // "";
		$start_date = $FIRST_DATE if(! $start_date);
		my $end_date = $gp->{end_date} // "";
		$end_date = $LAST_DATE if(! $end_date);

		$gp->{start_date} = $start_date;
		$gp->{end_date} = $end_date;

		my $fname = join(" ", $gp->{dsc}, $start_date, $gp->{static});

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

	my $rn = 1;
	#
	#	Rolling Average
	#
	if($gp->{static} eq "rlavr"){
		my $avr_date = $cdp->{avr_date} // $DEFAULT_AVR_DATE;
		my %sort_value = ();	
		foreach my $key (@$csv_data){
			my $csv = $csv_data{$key};
			for(my $i = @$csv; $i >= $avr_date; $i--){
				my $tl = 0;
				for(my $j = $i - $avr_date + 1; $j <= $i; $j++){
					$tl += $csv->[$j];
				}
				$csv->[$i] = $tl / $avr_date;
			}
		}
	}
	
	#
	#	Sort 
	#
	my %SORT_VAL = ();
	foreach my $key (@$csv_data){
		my $csv = $csv_data{$key};
		my $total = 0;
		foreach my $v (@$csv){
			$total += $v;
		}
		$SORT_VAL{$key} = $total;
	}
	my @taget = (sort {$SORT_VAL{$b} <=> $SORT_VAL{$a}} keys %SORT_VAL);
	
	#
	#	Genrarte csv file for plot
	#
	my $csv_for_plot = $gdp->{png_path} . "/$fname-plot.csv.txt";
	open(CSV, "> $csv_for_plot") || die "$csv_for_plot";
	print CSV join($dst_dlm, "#date", @taget) . "\n";
	for(my $dt = $start_date; $dt <= $end_date; $dt++){
		my @w = ();
		foreach my $key (@target){
			push(@w, $csv_data->{$key}->[$dt]);
		}
		print CSV join($dst_dlm, $label->[$dt], @w) . "\n";
	}
	close(CSV);

	&graph($csv_for_plot, $cdp, $gdp, $gp);
	return 1;
}


sub	graph
{
	my($csv_for_plot, $cdp, $gdp, $gp) = @_;

	my $title = $gp->{title} . "($LAST_DATE)";
	my @lank = (0, 99999);
	@lank = (@{$p->{lank}}) if(defined $p->{lank});
	#dp::dp "#### " . join(",", "[" . $p->{lank}[0] . "]", @lank) . "\n";


	my $fname = $p->{fname};
	my $csvf = $fname . "-plot.csv.txt";
	my $pngf = $fname . ".png";
	my $plotf = $fname. "-plot.txt";

	my $dlm = $gdp->{dst_dlm};
	my $ylabel = "%";

	my $time_format = $gdp->{timefmt};
	my $format_x = $gdp->{format_x};
	my $term_x_size = $gdp->{term_x_size};
	my $term_y_size = $gdp->{term_y_size};

	my $start_date = $p->{start_date} // "NONE";
	my $end_date = $p->{end_date} // "NONE";

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
set terminal pngcairo size $term_x_size, $term_y_size font "IPAexゴシック,8" enhanced
set output '$pngf'
plot #PLOT_PARAM#
exit
_EOD_

	#
	#	Gen Plot Param
	#
	my @p= ();
	my $pn = 0;
	my @tga = split(/ *, */, $gp->{target});
	my @exc = split(/ *, */, $gp->{exclusion});

	open(CSV, $csvf) || die "cannot open $csvf";
	my $l = <CSV>;
	close(CSV);
	$l =~ s/[\r\n]+$//;
	my @label = split(/$dlm/, $l);

	for(my $i = 1; $i < $#label; $i++){
		my $key = $label[$i];
		next if($#tga >= 0 && csvlib::search_list($key, @tga) eq "");
		next if($#exc >= 0 && csvlib::search_list($key, @exc));
		next if($i < $lank[0] || $i > $lank[1]);
		#dp::dp join(",", $i, @lank) . "\n";

		$pn++;
		push(@p, sprintf("'%s' using 1:%d with lines title '$i:%s' linewidth %d ", 
						$csvf, $i + 1, $label[i], ($pn < 7) ? 2 : 1)
		);
	}
	push(@p, "0 with lines dt '-' title 'base line'");
	my $plot = join(",", @p);
	$PARAMS =~ s/#PLOT_PARAM#/$plot/;

	open(PLOT, ">$plotf") || die "cannto create $plotf";
	binmode(PLOT, ":utf8");
	print PLOT $PARAMS;
	close(PLOT);

	system("gnuplot $plotf");

}

