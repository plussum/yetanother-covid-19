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
use JSON qw/encode_json decode_json/;
use Data::Dumper;

my $TKY_DIR = "/home/masataka/who/tokyo/covid19";
my $POSITIVE = "$TKY_DIR/data/positive_rate.json";		# 新規感染者数
my $CSS = $config::CSS;
my $IMG_PATH = $config::PNG_REL_PATH;
my $class = $config::CLASS;

my $pngf = "tpr_avr#avr#.png";
my $plotf = "tpr-plot.txt";
my $htmlf = "tokyo.html";
my $csvf = "tpr.csv.txt";

my $avr_date = 0;
my $DLM = "\t";

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
foreach my $avr_date(0, 7){
	my $pngff = $pngf;
	$pngff =~ s/#avr#/$avr_date/;
	my $pngfp = $config::PNG_PATH . "/$pngff";
	my $csvfp = $config::CSV_PATH . "/$csvf";
	my $plotfp = $config::PNG_PATH . "/$plotf";

	&tokyo_info($avr_date, $csvfp, $pngfp, $plotfp);

	print HTML "<!-- avr_date $avr_date -->\n";
	print HTML "<span class=\"c\">$now</span><br>\n";
	print HTML "<img src=\"$IMG_PATH/$pngff\">\n";
	print HTML "<br>\n";
	print HTML "<span $class> Data Source TOKYO OPEN DATA </span>\n";
	print HTML "<hr>\n";
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
	my ($avr_date, $csvf, $pngf, $plotf) = @_;
	my $JSON = "";
	open(FD, $POSITIVE) || die "cannot open $POSITIVE";
	while(<FD>){
		$JSON .= $_;
	}
	close(FD);

	my $positive = decode_json($JSON);
	#print Dumper $positive;
	my @KEYS = qw(diagnosed_date positive_count negative_count positive_rate);


	my @data = ();
	my $y2 = 0;
	my $rec = 0;
	my @data0 = (@{$positive->{data}});
	foreach my $dt (@data0) {
		foreach my $k (@KEYS){
			my $v = csvlib::valdef($dt->{$k});
			if($k ne "diagnosed_date" && $avr_date > 0){
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
		}
		$y2 = $dt->{positive_rate} if($dt->{positive_rate} > $y2);
		$rec++;
	}

	open(CSV, "> $csvf") || die "cannto create $csvf";
	print CSV join(",", "#" . $positive->{date}, @KEYS) . "\n"; 
	foreach my $dt (@data){
		my @line = ();
		foreach my $k (@KEYS){
			push(@line, $dt->{$k});
		}
		print CSV join($DLM , @line) . "\n";
	}
	close(CSV);
	my $de = scalar(@data);

	$y2 = int($y2 * 100 + 99.9) / 100;
	my $last_date = $data[$rec-1]{diagnosed_date};
	my $xrange = sprintf("['%s':'%s']", $data[$avr_date]{diagnosed_date}, $last_date);
	my $date_sec = 3600 * 24 * 7;

	my $PARAMS = << "_EOD_";
set datafile separator '$DLM'
set style fill solid 0.2
set xtics rotate by -90
set xdata time
set timefmt '%Y-%m-%d'
set format x '%Y-%m-%d'
set xrange $xrange
set y2range [0:$y2]
set mxtics 2
set mytics 2
set grid xtics ytics mxtics mytics
set key below
set title 'Tokyo Positive rate ($last_date)' font "IPAexゴシック,12" enhanced
set xlabel 'date'
set ylabel 'ylabel'
#
set xtics $date_sec
set terminal pngcairo size 1000, 300 font "IPAexゴシック,8" enhanced
set y2tics
set output '$pngf'
plot #PLOT_PARAM#
exit
_EOD_

	my @p= ();
	for(my $i = 1; $i <= $#KEYS; $i++){
		my $y = ($i < $#KEYS) ? "y1" : "y2";
		my $s;
		$s = "'$csvf' using 1:" . '($2+$3)' . " axis x1$y with boxes title '" . $KEYS[$i] . "' fill " if($i == 1);
		$s = "'$csvf' using 1:2 axis x1$y with boxes title '" . $KEYS[$i] . "' fill " if($i == 2);
		$s = "'$csvf' using 1:4 axis x1$y with lines title '" . $KEYS[$i] . "' linewidth 2" if($i == 3);
		push(@p, $s);
	}
	my $plot = join(",", @p);
	$PARAMS =~ s/#PLOT_PARAM#/$plot/;

	open(PLOT, ">$plotf") || die "cannto create $plotf";
	print PLOT $PARAMS;
	close(PLOT);
	#print $PARAMS;

	system("gnuplot $plotf");

}
sub	valdef
{
	my($v) = @_;

	$v = 0 if(!defined $v);
	return $v;
}
