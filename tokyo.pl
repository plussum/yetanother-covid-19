#!/usr/bin/perl
#
#
#
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

my $TKY_DIR = "/home/masataka/who/tokyo/covid19";
my $POSITIVE = "$TKY_DIR/data/positive_rate.json";		# 新規感染者数
my $CSS = $config::CSS;
my $IMG_PATH = $config::PNG_REL_PATH;
my $class = $config::CLASS;

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
			{colm => '($2+$3)', axis => "x1y1", graph => "boxes fill",  item_title => ""},
			{colm => '2', axis => "x1y1", graph => "boxes fill",  item_title => ""},
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
		plot => [
			{colm => '3', axis => "x1y2", graph => "boxes fill",  item_title => "severe"},
			{colm => '2', axis => "x1y1", graph => "lines linewidth 2",  item_title => "hospitalized"},
		],
	},

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
			{colm => '($2+$3)', axis => "x1y1", graph => "boxes fill",  item_title => ""},
			{colm => '2', axis => "x1y1", graph => "boxes fill",  item_title => ""},
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
for(@ARGV){
	if(/-DL/){
		system("(cd ../tokyo/covid19; git pull origin master)");
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
		print $p->{title} . "avr_date $avr_date \n";
		my $dst = &tokyo_info($p, $avr_date);

		print HTML "<!-- avr_date $avr_date -->\n";
		print HTML "<span class=\"c\">$now</span><br>\n";
		print HTML "<a link img src=\"$IMG_PATH/$dst.png\">\n";
		print HTML "<img src=\"$IMG_PATH/$dst.png\"> </a>\n";

		print HTML "<span class=\"c\">\n";
		print HTML "csv:<a href=\"$IMG_PATH/$dst.csv.txt\" target=\"blank\">$IMG_PATH/$dst.csv.txt</a><br>\n"; 
		print HTML "plot:<a href=\"$IMG_PATH/$dst.-plot.txt\" target=\"blank\">$IMG_PATH/$dst-plot.txt</a><br>\n"; 
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
	print "[$dst]\n";
	my $pngf = $config::PNG_PATH . "/$dst.png";
	my $csvf = $config::PNG_PATH . "/$dst.csv.txt";
	my $plotf = $config::PNG_PATH . "/$dst-plot.txt";
	my @items = @{$p->{items}};


	#
	#	Read from JSON file
	#
	my $JSON = "";
	open(FD, $p->{src}) || die "cannot open " . $p->{src};
	while(<FD>){
		$JSON .= $_;
	}
	close(FD);

	my $positive = decode_json($JSON);
	#print Dumper $positive;

	my @data = ();
	my $rec = 0;
	my @data0 = (@{$positive->{data}});
	my %max = ();
	my $date_name = $items[0];
	foreach my $dt (@data0) {

		foreach (my $itn = 0; $itn <= $#items; $itn++){
			my $k = $items[$itn];
			my $v = csvlib::valdef($dt->{$k});
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
	print CSV join($DLM, "#" . $positive->{date}, @items) . "\n"; 
	
	foreach my $dt (@data){
		my @line = ();
		next if($dt->{$date_name} lt $dt_start || $dt->{$date_name} gt $dt_end);

		foreach my $k (@items){
			push(@line, $dt->{$k});
		}
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
	my $plot = join(",", @p);
	$PARAMS =~ s/#PLOT_PARAM#/$plot/;

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
