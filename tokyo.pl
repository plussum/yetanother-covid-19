#!/usr/bin/perl
#
#
#	https://github.com/tokyo-metropolitan-gov/covid19.git
#

# 13101_daily_visitors.json
# 13104_daily_visitors.json
# agency.json
# daily_positive_detail.json
#		{ 'weekly_gain_ratio' => undef, 'untracked_percent' => undef, 'diagnosed_date' => '2020-01-20',
#		  'count' => 0, 'reported_count' => undef, 'missing_count' => undef, 'weekly_average_count' => undef},
#		{ "diagnosed_date": "2020-04-09", "count": 183, "missing_count": 128, "reported_count": 55, "weekly_gain_ratio": 2,
#            "untracked_percent": 71.6, "weekly_average_count": 123.1 },
#
# data.json
#		{ "日付": "2020-01-29T08:00:00.000Z", "曜日": 43859, "9-13時": 0, "13-17時": 0, "17-21時": 23, "date": "2020-01-29",
#          "w": 3, "short_date": "01\/29", "小計": 23 }
#
# metro.json
# monitoring_status.json
#		{ "（１）新規陽性者数": { "value": 56.9, "go_threshold": "―", "stop_threshold": "―" },
#         "（２）新規陽性者数における接触歴等不明率": { "value": 47.7, "go_threshold": "―", "stop_threshold": "―" },
#         "（３）週単位の陽性者増加比": { "value": 1.51, "go_threshold": "―", "stop_threshold": "―" },
#
# news.json
#		{ "date": "2020\/07\/01",
#          "url": "https:\/\/www.bousai.metro.tokyo.lg.jp\/taisaku\/saigai\/1007288\/1009642.html",
#          "text": "新たなモニタリングの方向性の公表（現在、新たなモニタリングの早期実施に向けて準備中）" },
#
# patient.json
#   	{ 'count' => 47, 'area' => "\x{7279}\x{5225}\x{533a}", 'ruby' => "\x{3061}\x{3088}\x{3060}\x{304f}", 
#		  'label' => "\x{5343}\x{4ee3}\x{7530}\x{533a}", 'code' => 131016 }
#			area => "特別区", ruby = "ちよだく", label => "千代田区"
#
# positive_by_diagnosed.json
#		{ "diagnosed_date": "2020-01-28", "count": 0 },
# positive_rate.json
#		{ "diagnosed_date": "2020-02-15", "positive_count": 8, "negative_count": 122, "positive_rate": 7.7 },
# positive_status.json
# 		{ 'severe_case' => 5, 'hospitalized' => 21, 'date' => '2020-02-28' },
# test.json
#		{}
# tokyo_alert.json

use strict;
use warnings;

use config;
use	csvlib;
use dp;
use JSON qw/encode_json decode_json/;
use Data::Dumper;

my $VERBOSE = 1;
my $DEBUG = 0;
my $TKY_GIT = "$config::WIN_PATH/tokyo/covid19"; # "/home/masataka/who/tokyo/covid19";
my $TKY_DIR = "$config::WIN_PATH/tokyo/covid19"; # "/home/masataka/who/tokyo/covid19";
my $POSITIVE = "$TKY_DIR/data/positive_rate.json";		# 新規感染者数
my $CSS = $config::CSS;
my $IMG_PATH = $config::PNG_REL_PATH;
my $class = $config::CLASS;
my $IMG_REL_PATH = $config::PNG_REL_PATH;

my $plotf = "tpr-plot.txt";
my $htmlf = "tokyo.html";
my $pngf = "tpr_avr#avr#.png";
my $csvf = "tpr_avr#avr#.csv.txt";

my $avr_date = 0;
my $DLM = "\t";


my @PARAMS = (
    {	
		src => "$TKY_DIR/data/positive_rate.json",
		date => "diagnosed_date",
		dst => "tky_pr",
		title => "Tokyo Positive Rate",
		ylabel => "daiagnosed count",
		y2label => "positive rate",
		items => [qw (diagnosed_date positive_count negative_count positive_rate)],
		y2max => "positive_rate",
		dt_start => "0000-00-00",
		plot => [
			{colm => '($2+$3)', axis => "x1y1", graph => "boxes fill",  item_title => "test total"},
			{colm => '2', axis => "x1y1", graph => "boxes fill",  item_title => "positive count"},
			{colm => '4', axis => "x1y2", graph => "lines linewidth 2",  item_title => "positive rate"},
		],
	},
    {	
		src => "$TKY_DIR/data/positive_status.json",
		date => "date",
		dst => "tky_st",
		title => "Tokyo Number of Critical and Hospitalized",
		ylabel => "hospitalized",
		y2label => "serevre",
		items => [qw(date hospitalized severe_case)], 
		t2max => "severe_case",
		dt_start => "0000-00-00",
		plot => [
			{colm => '3', axis => "x1y2", graph => "boxes fill",  item_title => "severe"},
			{colm => '2', axis => "x1y1", graph => "lines linewidth 2",  item_title => "hospitalized"},
		],
	},
	### Graph from 2020-03-12
	{	
		src => "$TKY_DIR/data/positive_rate.json",
		date => "diagnosed_date",
		dst => "tky_pr",
		title => "Tokyo Positive Rate (2020-03-12)",
		ylabel => "daiagnosed count",
		y2label => "positive rate",
		items => [qw (diagnosed_date positive_count negative_count positive_rate)],
		y2max => "positive_rate",
		dt_start => "2020-03-12",
		ext => "0312",
		plot => [
			{colm => '($2+$3)', axis => "x1y1", graph => "boxes fill",  item_title => "test_total"},
			{colm => '2', axis => "x1y1", graph => "boxes fill",  item_title => "positive_count"},
			{colm => '4', axis => "x1y2", graph => "lines linewidth 2",  item_title => ""},
		],
	},
	{	
		src => "$TKY_DIR/data/positive_status.json",
		date => "date",
		dst => "tky_st",
		title => "Tokyo Number of Critical and Hospitalized",
		ylabel => "hospitalized",
		y2label => "serevre",
		items => [qw(date hospitalized severe_case)], 
		t2max => "severe_case",
		dt_start => "2020-03-12",
		ext => "0312",
		plot => [
			{colm => '3', axis => "x1y2", graph => "boxes fill",  item_title => "severe"},
			{colm => '2', axis => "x1y1", graph => "lines linewidth 2",  item_title => "hospitalized"},
		],
	},
);
	
#
#
#
dp::dp "tokyo.pl " . join(",", @ARGV) . "\n" if($DEBUG);
for(@ARGV){
	if(/-DL/){
		dp::dp ("(cd $TKY_GIT; git pull origin development)\n");
		system("(cd $TKY_GIT; git pull origin development)");
		#system("(cd ../tokyo/covid19; git pull origin master)");
		#system("(cd ../tokyo/covid19; git clone origin master)");
	}
	elsif(/-S$/){
		$VERBOSE = 0;
		#dp::dp "### VERBOSE OFF\n";
	}
	elsif(/-av/){
		s/-av//;
		$avr_date = $_;
	}
}
my $HTMLF = $config::HTML_PATH . "/$htmlf";
open(HTML, "> $HTMLF") || die "cannot create $HTMLF";
print HTML "<HTML>\n";
print HTML "<HEAD>\n";
print HTML "<TITLE> TOKYO OPEN DATA </TITLE>\n";
print HTML $CSS;
print HTML "</HEAD>\n";
print HTML "<BODY>\n";
my $now = csvlib::ut2d4(time, "/") . " " . csvlib::ut2t(time, ":");

foreach my $p (@PARAMS){
	foreach my $avr_date(0, 7){
		dp::dp $p->{title} . "avr_date $avr_date \n" if($VERBOSE);
		my $dst = &tokyo_info($p, $avr_date);

		print HTML "<!-- avr_date $avr_date -->\n";
		print HTML "<span class=\"c\">$now</span><br>\n";
		print HTML "<a link img src=\"$IMG_REL_PATH/$dst.png\">\n";
		print HTML "<img src=\"$IMG_REL_PATH/$dst.png\"> </a>\n";

		print HTML "<span class=\"c\">\n";
		print HTML "csv:<a href=\"$IMG_REL_PATH/$dst-plot.csv.txt\" target=\"blank\">$IMG_REL_PATH/$dst-plot.csv.txt</a><br>\n"; 
		print HTML "plot:<a href=\"$IMG_REL_PATH/$dst-plot.txt\" target=\"blank\">$IMG_REL_PATH/$dst-plot.txt</a><br>\n"; 
		print HTML "</span>\n";
		print HTML "<br>\n";
		print HTML "<span $class> Data Source TOKYO OPEN DATA </span>\n";
		print HTML "<hr>\n";
	}
}
print HTML "</BODY>\n";
print HTML "</HTML>\n";
close(HTML);

exit(0);
#
#
#

sub	tokyo_info
{
	my ($p, $avr_date) = @_;

	my $dt_start = &valdef($p->{dt_start}, "0000-00-00"); 
	my $dt_end   = &valdef($p->{dt_end},   "9999-99-99");

	my $ext = &valdef($p->{ext}, "none");
	my $dst = $ext . $p->{dst} . "_avr$avr_date" ;
	dp::dp "[$dst]\n" if($DEBUG);
	my $pngf = $config::PNG_PATH . "/$dst.png";
	my $csvf = $config::PNG_PATH . "/$dst-plot.csv.txt";
	my $plotf = $config::PNG_PATH . "/$dst-plot.txt";
	my @items = @{$p->{items}};

	my @data = ();
	my $rec = 0;
	my $date_name = "";

	#
	#	Read from JSON file
	#
	my $JSON = "";
	open(FD, $p->{src}) || die "cannot open " . $p->{src};
	my $ln = 0;
	my $head_flag = 0;
	while(<FD>){
		$ln++;
#		if($head_flag){
#			dp::dp  "$ln:HEAD: $_";
#			if(/^>>>>/){
#				dp::dp "HEAD--> OFF\n";
#				$head_flag = 0;
#			}
#		}
#		elsif(/^<<<<.*HEAD/){
#			$head_flag = 1;
#		}
#		else {
#			$JSON .= $_;
#		}
		$JSON .= $_;
	}
	close(FD);

	dp::dp $p->{src} . "\n" if($VERBOSE);
	#dp::dp $JSON . "\n";
	my $positive = decode_json($JSON);
	#print Dumper $positive;

	my @data0 = (@{$positive->{data}});
	#print Dumper $positive;
	my %max = ();
	$date_name = $items[0];
	foreach my $dt (@data0) {

		my $total = 0;
		foreach (my $itn = 0; $itn <= $#items; $itn++){
			my $k = $items[$itn];
			my $v = csvlib::valdef($dt->{$k});
			#dp::dp "$itn: $k: $v\n";
			if($avr_date > 0 && $k ne $date_name){
				if($rec < $avr_date){
					$v = 0;
				}
				else {
					for(my $i = 1; $i < $avr_date; $i++){
						$v += csvlib::valdef($data0[$rec - $i]{$k});
					}
					$v /= $avr_date;
				}
			}
			$data[$rec]{$k} = $v;
			$max{$k} = $v if(!defined $max{$k} || ($itn > 0 && $v > $max{$k}));
		}
		$rec++ 
	}
	my $y2k = $p->{y2max};
	my $y2 = (defined $y2k && $y2k) ? $max{$y2k} : "";

	open(CSV, "> $csvf") || die "cannto create $csvf";
	#dp::dp $csvf . "\n";
	print CSV join($DLM, "#" . $positive->{date}, @items) . "\n"; 
	
	foreach my $dt (@data){
		my @line = ();
		next if($dt->{$date_name} lt $dt_start || $dt->{$date_name} gt $dt_end);

		#dp::dp $dt->{date} . "\n";

		foreach my $k (@items){
			push(@line, $dt->{$k});
		}
		#dp::dp join($DLM , @line) . "\n";
		print CSV join($DLM , @line) . "\n";
	}
	close(CSV);
	my $de = scalar(@data);

	my $first_date = $data[$avr_date]{$date_name};
	$first_date = $dt_start if($dt_start && $dt_start gt $first_date); 
	my $last_date = $data[$rec-1]{$date_name};
	$last_date = $dt_end if($dt_end && $dt_end lt $last_date); 

	my $gpara = {
		csvf => $csvf,
		pngf => $pngf,
		plotf => $plotf,
		first_date => $first_date, 
		last_date   => $last_date,
		xtics => 60 * 60 * 24 * 7,
		dlm => $DLM,
		p => $p,
		y2 => (defined $p->{y2items}) ? int($y2 + 0.999) : "",
	};	
	&graph($gpara);
	return ("$dst");
}

sub	graph
{
	my ($gp) = @_;

	my $p = $gp->{p};
	my $csvf = $gp->{csvf};
	my $pngf = $gp->{pngf};
	my $plotf = $gp->{plotf};
	my $last_date = $gp->{last_date};
	my $first_date = $gp->{first_date};
	my $xrange = sprintf("['%s':'%s']", $first_date, $last_date);
	my $xtics = $gp->{xtics};

	my $item_names = $p->{items};
	my $item_number = scalar(@$item_names) - 1;
	my $dlm = $gp->{dlm};
	my $title = $p->{title} . "($last_date)";
	my $ylabel = $p->{ylabel};

	my $y2_items = $p->{y2_items};
	my $y2 = $gp->{y2};
	my $y2range = (defined $y2 && $y2) ? "set y2range [0:$y2]" : "";
	my $y2label = (defined $p->{y2label}) ? ("set y2label '" . $p->{y2label} . "'") : "";

	my $PARAMS = << "_EOD_";
set datafile separator '$dlm'
set style fill solid 0.2
set xtics rotate by -90
set xdata time
set timefmt '%Y-%m-%d'
set format x '%Y-%m-%d'
set xrange $xrange
$y2range
$y2label
set mxtics 2
set mytics 2
set grid xtics ytics mxtics mytics
set key below
set title '$title' font "IPAexゴシック,12" enhanced
set xlabel 'date'
set ylabel '$ylabel'
#
set xtics $xtics
set terminal pngcairo size 1000, 300 font "IPAexゴシック,8" enhanced
set y2tics
set output '/dev/null'
plot #PLOT_PARAM#

Y_MIN = 0
Y_MAX = GPVAL_Y_MAX
#ARROW#
set output '$pngf'
plot #PLOT_PARAM#
exit
_EOD_

	my @p= ();
	#dp::dp join(",", $item_number, @$item_names) . ":\n";
	for(my $i = 1; $i <= $item_number; $i++){
		my $plp = $p->{plot}[$i-1];
		#dp::dp "plp :\n " . Dumper $plp;
		my $s = sprintf("'%s' using 1:%s %s with %s title '%s'", 
				$csvf, $plp->{colm}, 
				(defined $plp->{axis}) ? ("axis " . $plp->{axis}) : "", 
				$plp->{graph}, 
				(defined $plp->{item_title} && $plp->{item_title}) ? $plp->{item_title} : $item_names->[$i]
		);
		push(@p, $s);
	}
	if(1){

		#dp::dp join(",", $first_date, $last_date) . "\n";
		my $first_utime = csvlib::ymds2tm($first_date);
		my $last_utime  = csvlib::ymds2tm($last_date);

		#dp::dp join(",", $first_utime, csvlib::ut2d4($first_utime), $last_utime, csvlib::ut2d4($last_utime)) . "\n";

		my $RELATIVE_DATE = 7 * 24 * 60 * 60;
		my @aw = ();

		my $last_date = $last_utime / (24 * 60 * 60);	# Draw arrow on sunday
		my $s_date = ($last_date - 2) % 7;
		$s_date = 7 if($s_date == 0);
		#dp::dp "DATE: " . $DATES[$date] . "  " . "$date -> $s_date -> " . ($date - $s_date) . "\n";
		$last_utime -= $s_date * (24 * 60 * 60);
		
		for(my $date = $last_utime; $date > $first_utime; $date -= $RELATIVE_DATE){
			my $mark_date  = csvlib::ut2d4($date, "-");
			#dp::dp "## $mark_date\n";
			my $a = sprintf("set arrow from '%s',Y_MIN to '%s',Y_MAX nohead lw 1 dt (3,7) lc rgb \"dark-red\"",
				$mark_date,  $mark_date);
			push(@aw, $a);
		}
		my $arw = join("\n", @aw);
		#dp::dp "ARROW: $arw\n";

		$PARAMS =~ s/#ARROW#/$arw/;	
	}
	my $plot = join(",", @p);
	$PARAMS =~ s/#PLOT_PARAM#/$plot/g;

	dp::dp $plotf . "\n";
	open(PLOT, ">$plotf") || die "cannto create $plotf";
	print PLOT $PARAMS;
	close(PLOT);

	#dp::dp $csvf. "\n";
	#dp::dp $PARAMS;

	system("gnuplot $plotf");
}

sub	valdef
{
	my($v, $d) = @_;

	$d = 0 if(!defined $d);	
	$v = $d if(!defined $v);
	return $v;
}
