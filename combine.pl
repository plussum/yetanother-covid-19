#!/usr/bin/perl
#
#
# tokyo_alert.json

use strict;
use warnings;

use config;
use	csvlib;
use dp;
use Data::Dumper;
use Time::Local 'timelocal';

my $DEBUG = 0;
my $VERBOSE = 0;

my %SRC_CSV = (
	"ccse-NC" => "$config::CSV_PATH/jhccse_NC_DAY.csv.txt",
	"ccse-ND" => "$config::CSV_PATH/jhccse_ND_DAY.csv.txt",
	"tko-NC"  => "$config::CSV_PATH/tko_NC_DAY.csv.txt",
	"tko-ND"  => "$config::CSV_PATH/tko_ND_DAY.csv.txt",
);

my $LT1 = "lines linewidth 1";
my $LT2 = "lines linewidth 1 dt (10,5)";
my $LTW = "lines linewidth 2";
my $BX1 = "boxes fill";

my $HTML_DIR = "$config::HTML_PATH";
my $IMG_DIR  = "$config::PNG_PATH";

my $IMG_REL_PATH = $config::PNG_REL_PATH;

my $HTMLF   = "$HTML_DIR/combine.html";
my $OUT_CSV = "$IMG_DIR/combine.csv.txt";
my $OUT_PNG = "$IMG_DIR/combine.png";

my @TARGET_COUNTRY = (
	{src => "ccse", title => "JHCCSE New Cases/Deathes", list => "Japan,US"},
	{src => "tko",  title => "Toyo Keizai New Cases/Deathes",list => "東京,大阪,北海道,神奈川,千葉,埼玉,愛知,沖縄,熊本,福岡"},
	{src => "ccse", title => "JHCCSE NEW Cases/Deathes", list => "France,United Kingdom,Italy,Germany,Belgium,Poland,Netherlands,Czechia,Romania,Switzerland,Portugal,Sweden"},
);


#
#	ADD EU 
#
my @PARAM_LIST = ();

foreach my $tgc (@TARGET_COUNTRY){
	my $src_nc = $tgc->{src} . "-NC";
	my $src_nd = $tgc->{src} . "-ND";
	my $title = $tgc->{title};
	foreach my $country (split(/,/, $tgc->{list})){
		my $p = {	
			title => "$tgc->{title} $country",
			time_from => "2020/03/01",
			time_till => "",
			avr_date => 7,
			plot => [
				{items => [$src_nc], target => $country, label => "NewCases", ymin => "", ymax => "", graph => $LTW},
				{items => [$src_nd], target => $country, label => "NewDeathes", ymin => "", ymax => "", graph => $LT1},
			],
		};
		push(@PARAM_LIST, $p);
	}
}
my @CSV_FILES = ();
my $last = "";

my @YMIN = 0;
my @YMAX = 0;

#
#	Set Color Table
#
my @COLORS = ("blue",  "coral",  "light-green", "grey50", "purple", "gold" );
my $COLOR_SET = "";
for(my $i = 0; $i <= $#COLORS; $i++){
	$COLOR_SET .= sprintf("set style line %d lc rgb \"%s\" \n", $i+1, $COLORS[$i]);
}
$COLOR_SET .= "set style increment user";
$COLOR_SET = "";
	

#				#$graph .= " linewidth 1 dt (10,4) ";
my $TMZ = -9;

my $CSS = << "_EOCSS_";
    <meta charset="utf-8">
    <style type="text/css">
    <!--
        span.c {font-size: 12px;}
    -->
    </style>
_EOCSS_

my $CLASS = "class=\"c\"";
my $DLM = "\t";

my $DL = 0;
my $MERGE = 0;

my @PARAMS = (@PARAM_LIST);		# Set Parameter
	
#
#	Argument Handling
#
my $FROM = "";
for(@ARGV){
	if(/-p/){	# sensor:from:till, -p:co2:-1d:
		dp::dp "[$_]\n";
		s/-p:*//;
		my ($sensor, $from, $till) = split(":", $_);
		my $title = join(",", $sensor, $from, $till);
		dp::dp "##### $title\n";
		my $ymin = "";
		my $ymax = "";
	}
	elsif(/-/){
		dp::dp "Unkown option $_\n";
		exit;
	}
}

#
#	CSVファイルのダウンロード	RAW/
#
my @ITEMS = ();
my %ITEM_FLAG = ();
my %COUNTRY = ();
my %COUNTRY_FLAG = ();
my %DATES = ();
my $pn = 0;
foreach my $p (@PARAMS){
	dp::dp $p->{title} . "\n";
	my $csvf =  $p->{title} ;
	$csvf .= "rl_avr " . $p->{avr_date} if(defined $p->{avr_date});
	$csvf =~ s/[ \/,.]/_/g;
	$p->{dst} = "$csvf";

	my @ys = &get_csvfile($p);
	$p->{items_end} = [@ys];

	dp::dp "$csvf.csv.txt\n" if($DEBUG);
	open(OUT_CSV, "> $IMG_DIR/$csvf.csv.txt" ) || die "Cannot create $IMG_DIR/$csvf.csv.txt";

	my @LABEL = ();
	foreach my $item (@ITEMS){
		foreach my $country (sort keys %COUNTRY_FLAG){
			push(@LABEL, "$item-$country");
		}
	}
	print OUT_CSV join($DLM, "# date", @LABEL) . "\n";

	my @dts = (sort keys %DATES);
	for(my $d = 0; $d < $#dts; $d++){
		my $dt = $dts[$d];
		my @record = ("2020/" . $dt);
		my $avr_date = $p->{avr_date} // "";
		foreach my $item (@ITEMS){
			foreach my $country (sort keys %COUNTRY_FLAG){
				my $v = $COUNTRY{$item}{$country}{$dt} // 0;
				if($avr_date){
					my $i = ($d < $avr_date) ? 0 : $d - $avr_date + 1; 
					for(;$i < $d; $i++){
						my $d_avr = $dts[$i];
						$v += $COUNTRY{$item}{$country}{$d_avr} // 0;
					}
					$v /= $avr_date;
				}
				push(@record, $v);
			}
		}
		print OUT_CSV join($DLM, @record) . "\n";
	}
	close(OUT_CSV);

	print "-" x 80 . "\n" if($DEBUG);
	#system("cat $csvf.csv.txt");
	$pn++;
}

#
#	Generate HTML
#
open(HTML, "> $HTMLF") || die "cannot create $HTMLF";
print HTML "<HTML>\n";
print HTML "<HEAD>\n";
print HTML "<TITLE> NETATMO </TITLE>\n";
print HTML $CSS;
print HTML "</HEAD>\n";
print HTML "<BODY>\n";
my $now = csvlib::ut2d4(time, "/") . " " . csvlib::ut2t(time, ":");

foreach my $p (@PARAMS){
	#last if(! $p->{src});

	print $p->{title} . "\n" if($VERBOSE);
	my $dst = $p->{dst};

	&combine_graph($p);

	print HTML "<!-- $p->{title}  -->\n";
	print HTML "<span class=\"c\">$now</span><br>\n";
	print HTML "<a link img src=\"$IMG_REL_PATH/$dst.png\">\n";
	print HTML "<img src=\"$IMG_REL_PATH/$dst.png\"> </a>\n";
	print HTML "<br>\n";

	print HTML "<span class=\"c\">\n";
	print HTML "csv:<a href=\"$IMG_REL_PATH/$dst.csv.txt\" target=\"blank\">$IMG_REL_PATH/$dst.csv.txt</a><br>"; 
	print HTML "plot:<a href=\"$IMG_REL_PATH/$dst-plot.txt\" target=\"blank\">$IMG_REL_PATH/$dst-plot.txt</a><br>\n"; 
	print HTML "</span>\n";
#	print HTML "<br>\n";
#	print HTML "<span $CLASS> Data Source TOKYO OPEN DATA </span>\n";
	print HTML "<hr>\n";
}

print HTML "</BODY>\n";
print HTML "</HTML>\n";
close(HTML);

exit(0);

#
#	CSVファイルのリストを作成
#		title => "JHCCSE New Cases/Deathes",
#		time_from => "-1d",
#		time_till => "",
#		graph => [
#			{items => [qw(ccse-NC)], terget => "", label => "NewCases", ymin => "", ymax => "", graph => $LT1},
#			{items => [qw(ccse-ND)], terget => "", label => "NewDeathes", ymin => "", ymax => "", graph => $LTW},
#		],
#		my @target = split(/,/, csvlib::valdefs($gplitem->{target}, ""));			# 明示的対象国
#
sub	get_csvfile
{
	my ($p) =  @_;

	@ITEMS = ();
	%ITEM_FLAG = ();
	%COUNTRY = ();
	%COUNTRY_FLAG = ();
	%DATES = ();

	dp::dp "### TITLE: " . $p->{title}  . "\n" if($DEBUG);
	my @graph = @{$p->{plot}};
	my @yy = ();
	my $yn = 0;
	foreach my $gp (@graph){
		dp::dp "### LABEL:" . $gp->{label}  . "\n" if($DEBUG);
		my @items = @{$gp->{items}};
		my @target = split(/,/, csvlib::valdefs($gp->{target} // "", ""));			# 明示的対象国

		$yy[$yn] = 0;
		foreach my $item (@items){
			dp::dp "### ITEM:" . $item  . "\n" if($DEBUG);
			if(! defined $SRC_CSV{$item}){
				dp::dp "### No CSV definition for $item\n";
				next;
			}
			if(! defined $ITEM_FLAG{$item}){
				push(@ITEMS, $item);
			}
			$ITEM_FLAG{$item}++;

			open(FD, $SRC_CSV{$item}) || die "Cannot open $SRC_CSV{$item} for $item";
			$_ = (<FD>);
			s/[\r\n]+$//;
			my ($country_l, $total_l, @dates) = split(/$DLM/, $_);
			while(<FD>){
				s/[\r\n]+$//;
				my ($country, $total, @data) = split(/$DLM/, $_);
				next if($#target >= 0 && ! csvlib::search_list($country, @target));

				$yy[$yn]++;

				dp::dp "$country\n" if($DEBUG);
				for(my $d = 0; $d <= $#data; $d++){
					my $dt = $dates[$d];
					$COUNTRY{$item}{$country}{$dt} = $data[$d];
					$COUNTRY_FLAG{$country}++;
					$DATES{$dt}++;
				}
			}
			close(FD);
		}
		$yn++;
	}
	return ($yy[0], $yy[0]+$yy[1]);
}

#	{
#		[
#		src => $MAIN_CSV,
#		date => "tempture",
#		dst => "tempture",
#		title => "Netatmo Tempture",
#		ext => "0312",
#		ylabel => "Tempture",
#		y2label => "",
#		item1 => [qw (tempture)],
#		item2 => [],
#		y2max => "",
#		dt_start => "0000-00-00",
#		plot => [
#			{axis => "x1y1", graph => "boxes fill",  item_title => "test total"},
#			{axis => "x1y2", graph => "lines linewidth 2",  item_title => "positive rate"},
#		],
#	},
sub	combine_graph
{
	my ($p) = @_;


	my $dst = $p->{dst};
	print "[$dst]\n" if($DEBUG);
	my $pngf = "$dst.png";
	my $plotf = "$dst-plot.txt";

	my $time_from = $p->{time_from} // "";
	my $time_till = $p->{time_till} // "";

	my $gpara = {
		p => $p,
		csvf => "$IMG_DIR/$dst" . ".csv.txt",
		pngf => "$IMG_DIR/$pngf",
		plotf => "$IMG_DIR/$plotf",
		time_form => $time_from, 
		time_till   => $time_till,
#		xtics => $TERM,
		dlm => $DLM,
	};	
	&graph($gpara);
	return ("$dst");
}

#
#	$p
#	$gp
#		csvf: source csv data
#		pngf: Graph Image file
#		plotf: gnuplot command file
#
#		first_date: first date of drawing graph
#		last_date: last date of drawing graph
#
#		xtics: term of xtics, 
#		items1: items y1
#		items2: items y2, optional
#
#		dlm: delimitter of csv data ","
#		title: Graph title
#		ylabel: y axis label
#
#		y2_items: y2 items
#		y2:
#		y2_max:
#		
#
sub	graph
{
	my ($gp) = @_;

	my $p = $gp->{p};
	my $csvf = $gp->{csvf};
	my $pngf = $gp->{pngf};
	my $plotf = $gp->{plotf};
	my $time_till = $p->{time_till};
	my $time_from = $p->{time_from};
	my $xtics = $gp->{xtics};

	my @cols = ();
	my $dlm = $gp->{dlm};
	my $title = $p->{title}; 

	my @ymin = ();
	my @ymax = ();
	my @yrange = ();
	my @ylabel = ();

	my $plp_number = 0;
	for($plp_number = 0; $plp_number < 2; $plp_number++){
		last unless(defined $p->{plot}[$plp_number]);

		my $plp = $p->{plot}[$plp_number];
		$ylabel[$plp_number] = &valdef($plp->{label} // "", "---");
		$ymin[$plp_number]   = &valdef($plp->{ymin} // "", 0);
		$ymax[$plp_number]   = &valdef($plp->{ymax} // "", "");
	}
	
	open(CSV, $csvf) || die "cannot open $csvf";
	my $s = <CSV>;
	dp::dp $s if($DEBUG);
	$s =~ s/^#//;
	$s =~ s/[\r\n]+$//;
	my @CSV_ITEMS = split(/$DLM/, $s);
	shift(@CSV_ITEMS);

	my %STATS = ();
	for(my $i = 0; $i <= $#CSV_ITEMS; $i++){
		$STATS{MAX}[$i] = -99999999;
		$STATS{MIN}[$i] =  99999999;
		$STATS{TOTAL}[$i] = 0;
	}
	
	my $CSV_TIME_FROM = "";				# FIRST DATE
	my $CSV_TIME_TILL = "";	# LAST_DATE
	while(<CSV>){
		s/[\r\n]+$//;
		my @w = split(/$DLM/, $_);

		$CSV_TIME_TILL = &date2ut(shift(@w));
		$CSV_TIME_FROM = $CSV_TIME_TILL if(! $CSV_TIME_FROM);
		for(my $i = 0; $i <= $#w; $i++){
			my $v = $w[$i];
			next if($v eq "NaN");

			$STATS{MAX}[$i] = $v if($v > $STATS{MAX}[$i]);
			$STATS{MIN}[$i] = $v if($v < $STATS{MIN}[$i]);
			$STATS{TOTAL}[$i] += $v;
		}
	}
	close(CSV);

	dp::dp "CSV_TIME [$CSV_TIME_FROM:$CSV_TIME_TILL]\n" if($DEBUG);
	##### DEBUG for STATS
	foreach my $k (keys %STATS){
		my @w = ();
		for(my $i = 1; $i <= $#CSV_ITEMS; $i++){
			push(@w, $STATS{$k}[$i]);
		}
		dp::dp "==== $k " . join(", ", @w) . "\n" if($DEBUG);
	}
	#####

	my %PLP_STATS = ();
	my $ys = 0;
	for(my $i = 0; $i < $plp_number; $i++){
		my $plp = $p->{plot}[$i];
		$PLP_STATS{MAX}[$i] = -99999999;
		$PLP_STATS{MIN}[$i] =  99999999;
		$PLP_STATS{TOTAL}[$i] = 0;
	
		my @itm = @{$plp->{items}};
		dp::dp "#### " . join(",", @itm) . "\n" if($DEBUG);

		dp::dp "cols $i:" . join(",", @{$p->{items_end}}, $p->{items_end}->[1] ) . "\n" if($DEBUG);
		for(; $ys < $p->{items_end}->[$i]; $ys++){ 
			dp::dp ">>STATS ($ys) " . join(",", $STATS{MAX}[$ys], $STATS{MIN}[$ys], $STATS{TOTAL}[$ys]) . "\n" if($DEBUG);
			$PLP_STATS{MAX}[$i] = $STATS{MAX}[$ys] if($STATS{MAX}[$ys] > $PLP_STATS{MAX}[$i]);
			$PLP_STATS{MIN}[$i] = $STATS{MIN}[$ys] if($STATS{MIN}[$ys] < $PLP_STATS{MIN}[$i]);
			$PLP_STATS{TOTAL}[$i] += $STATS{TOTAL}[$ys];
		}
		dp::dp "PLP_STATS ($i) " . join(",", "MIN:" . $PLP_STATS{MIN}[$i], "MAX:" . $PLP_STATS{MAX}[$i], "TOTAL:" . $PLP_STATS{TOTAL}[$i]) . "\n" if($DEBUG);
	
		my $ymn = ($ymin[$i]) ? $ymin[$i] : $PLP_STATS{MIN}[$i];
		my $ymx = ($ymax[$i]) ? $ymax[$i] : $PLP_STATS{MAX}[$i];
		my $yr = abs($ymx - $ymn);
		my $yd = int(log($yr) / log(10) + 0.9999999999);
		my $ydn = 10 ** ($yd - 1) / 10;
	
		dp::dp "RANGE: $yr  DIGIT: $yd  -> $ydn\n" if($DEBUG);

		$ymn = int($ymn / $ydn - 0.999999) * $ydn if(! $ymin[$i]);
		$ymx = int(($ymx - $ymn) / $ydn + 0.999999999) * $ydn + $ymn if(! $ymax[$i]);

		$yrange[$i] = sprintf("set y%srange [$ymn:$ymx]", ($i == 0) ? "" : 2);
		$ylabel[$i] = sprintf("set y%slabel '%s'", ($i == 0) ? "" : 2, $ylabel[$i]);

		dp::dp "ymin,ymax [$yrange[$i]]\n" if($DEBUG);

		$YMIN[$i] = $ymn;
		$YMAX[$i] = $ymx;
	}

	my $yr  = $yrange[0];
	my $yl  = $ylabel[0];
	my $yr2 = ($yrange[1]) ? $yrange[1] : $yrange[0];
	$yr2 =~ s/yr/y2r/;
	my $yl2 = ($ylabel[1]) ? $ylabel[1] : $ylabel[0];
	$yl2 =~ s/yl/y2l/;
	#my $y2tics = ($ylabel[1]) ? "set y2tics" : "";	# set y2tics
	my $y2tics = "set y2tics";

	#
	#	Time Range
	#
	if(!$time_from && !$time_till){
		$time_from = "-2m";
		$time_till = "";
	}
	my $utime_from = &time_params($time_from, $CSV_TIME_TILL);
	my $time_base_till = $CSV_TIME_TILL;
	if($time_till =~ /^\+/){
		$time_base_till = $utime_from;
	}
	my $utime_till = &time_params($time_till, $time_base_till);
	if(! $time_till){
		$utime_till = $CSV_TIME_TILL;
		dp::dp "TIME_TILL: $time_till" . &ut2dt($utime_till) . "\n" if($DEBUG);
	}
	my $xrange = sprintf("['%s':'%s']", &ut2md($utime_from), &ut2md($utime_till));
	$title .=  sprintf(" (%s:%s)", &ut2md($utime_from), &ut2md($utime_till));

	#
	#	calculate xtics
	#
	my $graph_term = $utime_till - $utime_from;
	my $xt_number = 40;			# 表示する xticsの数
	my $xt_unit = 60 * 15;

	$xtics = $graph_term / $xt_number;
	my $hour = 60 * 60;
	my $day = 24 * $hour;
	my @ticses = (60, $hour, 2 * $hour, 4 * $hour, 6 * $hour, 24 * $hour, 7 * $day);
	foreach my $t (@ticses){
		if($xtics <= $t){
			$xtics = $t;
			last;
		}
	}
	my $max_data = 500;
	my $ev = int(($graph_term / (5 * 60)) / $max_data);
	my $every = ""; # ($ev > 0) ? "every $ev" : "";
	dp::dp  "### Every : " . join(",", $xtics, $max_data, $ev, $every) . "\n" if($DEBUG);
	#$xtics = int($xtics / $xt_unit) * $xt_unit;

	dp::dp $csvf . "\n" if($DEBUG);
	dp::dp $plotf . "\n" if($DEBUG);
	dp::dp join("\t", "from", $time_from, $utime_from, &ut2dt($utime_from)) ."\n" if($DEBUG);
	dp::dp join("\t", "till", $time_till, $utime_till, &ut2dt($utime_till)) ."\n" if($DEBUG);
	dp::dp join("\t", "xtics", $graph_term, $xt_number, $graph_term / $xt_number, $xtics) ."\n" if($DEBUG);

	my $PARAMS = << "_EOD_";
set datafile separator '$dlm'
$COLOR_SET
set style fill solid 0.2
set xtics rotate by -90
set xdata time
set timefmt '%Y/%m/%d'
#set format x '%m-%d %H:%M'
set format x '%m/%d'
set xrange $xrange
$yl
$yr
$yl2
$yr2
set mxtics 2
set mytics 2
set grid xtics ytics mxtics mytics
set key below
set title '$title' font "IPAexゴシック,12" enhanced
#set xlabel 'date'
#
set xtics $xtics
set terminal pngcairo size 1000, 300 font "IPAexゴシック,8" enhanced
$y2tics
set output '$pngf'
#ARROW#
plot #PLOT_PARAM#
exit
_EOD_

	my @p= ();
	#dp::dp join(",", $item_number, @$item_names) . ":\n";
	my $c = 0;
	for(my $i = 0; $i < $plp_number; $i++){
		my $plp = $p->{plot}[$i];
		my $axis = ($i == 0) ? "axis x1y1" : "axis x1y2";
		#dp::dp "plp :\n " . Dumper $plp;
		my $graph = $plp->{graph} // "lines lw 1";

		for(; $c < $p->{items_end}->[$i]; $c++){
			my $s = sprintf("'%s' using 1:%s $every %s with %s title '%s'", 
				$csvf, $c + 2, $axis, $graph, 
				$CSV_ITEMS[$c]
			);
			push(@p, $s);
		}
	}
	my $plot = join(",", @p);
	$PARAMS =~ s/#PLOT_PARAM#/$plot/;

	#
	#	Line 00:00:00 
	#
	my @arrows = ();
	my $lutf = $utime_from ;
	#my $arw_tm = int(($lutf + $day - 1)/$day) * $day + ($day + $TMZ * $hour); # % $day);
	my $arw_tm = int($lutf/$day) * $day;
	$arw_tm += $TMZ * $hour - $day; #$day if(($lutf % $day) >= (-$TMZ * $hour));
	dp::dp "#### " . join(", ", $utime_from, $lutf, $arw_tm, &ut2dt($utime_from), &ut2dt($arw_tm)) . "\n" if($DEBUG);
	for(; $arw_tm < $utime_till; $arw_tm += $day){
		next if($arw_tm < $utime_from);

		my $arw = sprintf("set arrow from '%s',%d to '%s',%d nohead lw 1 dt (10,5) lc rgb \"red\"", 
			&ut2dt($arw_tm), $YMIN[0], &ut2dt($arw_tm), $YMAX[0]);
		push(@arrows, $arw);
	}
	my $arrow_cmd = join("\n", @arrows);
	#dp::dp "\n" . $arrow_cmd . "\n";

	#$PARAMS =~ s/#ARROW#/$arrow_cmd/;

	dp::dp $plot . "\n" if($DEBUG);

	open(PLOT, ">$plotf") || die "cannto create $plotf";
	print PLOT $PARAMS;
	close(PLOT);

	#dp::dp $csvf. "\n";
	#dp::dp $PARAMS;

	system("gnuplot $plotf");
}


#
#
#
sub	item_val
{
	my ($hashp, $dlm, $itemp, $value) = @_;

	$value =~ s/[\r\n]+$//;
	my @vals = split(/$dlm/, $value);

	my $item_count = @$itemp;
	for(my $i =0; $i < $item_count; $i++){
		my $k = $itemp->[$i];
#		dp::dp "$i:[$k] <= $vals[$i]\n";
		$hashp->{$k} = $vals[$i];
	}

#	foreach my $k (keys %{$hashp}){
#		dp::dp join(":", $k, $hashp->{$k}). "\n";
#	} 
	return $item_count;
}

sub	item_val_line
{
	my ($hashp, $dlm, $item, $value) = @_;

	#dp::dp "item_val_line: " . join(", ", $hashp, $dlm, $item, $value) . "\n";
	$item =~ s/[\r\n]+$//;
	$item =~ s/"//g;
	my @items = split(/$dlm/, $item);

	if($value){
		return &item_val($hashp, $dlm, \@items, $value);
	}
	return "";

}

sub	valdef
{
	my($v, $d) = @_;

	$d = 0 if(!defined $d);	
	$v = $d if(!defined $v);
	return $v;
}

#
#
#	unix_time, ":", -> "01:23:45"
#
sub ut2dt
{
	my ($tm) = @_;

	#dp::dp "ut2dt: " . join(",", caller) . "\n";
	$tm = $tm // time;
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year + 1900, $mon+1, $mday, $hour, $min, $sec);
	return $s;
}

#
#
#	unix_time, ":", -> "01:23:45"
#
sub ut2md
{
	my ($tm) = @_;

	#dp::dp "ut2dt: " . join(",", caller) . "\n";
	$tm = $tm // time;
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%04d/%02d/%02d",  $year + 1900, $mon+1, $mday);
	return $s;
}
#
#	year, month, date, hour, min, sec -> unix_time
#
sub ymd2tm
{
	my ($y, $m, $d, $h, $mn, $s) = @_;

	$m = $m // 1;
	$d = $d // 1;
	$h = $h // 0;
	$mn = $mn // 0;
	$s = $s // 0;
	#dp::dp "ymd2tm: " . join("/", @_), "\n";

	#$y -= 2100 if($y > 2100);
	my $tm = timelocal($s, $mn, $h, $d, $m - 1, $y);
	# print "ymd2tm: " . join("/", $y, $m, $d, $h, $mn, $s), " --> " . &ut2d($tm, "/") . "\n";
	return $tm;
}

#
#	"2020/01/02/hh/mm/ss", "/", 0, 1, 2, 3, 4, 5, 6 -> unix_time
#
sub	date2ut
{
	my ($time_str) = @_;

	my ($y, $m, $d, $hh, $mm, $ss) = split(/[\/: ]/, $time_str);

	#dp::dp "date2ut: $time_str -> ". join(",", $y, $m, $d, $hh // 0, $mm // 0, $ss // 0) . "\n";
	return &ymd2tm($y, $m, $d, $hh // 0, $mm // 0, $ss // 0);
} 

#
#
#
sub	time_params
{
	my ($tms, $now) = @_;

	dp::dp "time_params[$tms:$now]\n" if($DEBUG);
	$now = $now // time;
	if($now =~ /\//){
		my @w = split(/\//, $now);
		$now = "2020/$now" if($#w < 2);
		dp::dp "<<$now:" .  &date2ut($now) . ">>\n" if($DEBUG);
		$now = &date2ut($now);
	}
	my $utime = $now;

	if($tms =~ /\//){
		#$utime = &dt2ut($tms);
		my @w = split(/\//, $tms);
		$tms = "2020/$tms" if($#w < 2);
		$utime = &date2ut($tms);
		dp::dp "<<$tms:" .  $utime . ">>\n" if($DEBUG);
	}
	elsif($tms =~ /^[-+]/){			# +1d, -1d 1w 1m
		$tms =~ /([\-\+][0-9]+)([a-zA-Z]+)/;
		my $tm = $1;
		my $unit = $2 // "d";	# default: date

		my $utm = 1;
		$utm = 60 * 60 if($unit =~ /h/i);
		$utm = 60 * 60 * 24 if($unit =~ /d/i);
		$utm = 60 * 60 * 24 * 7 if($unit =~ /w/i);
		$utm = 60 * 60 * 24 * 30 if($unit =~ /m/i);

		dp::dp ">>> " . join(",", $utime, $unit, $utm) . "\n" if($DEBUG);
	
		my $ltm = $now + $TMZ * 60 * 60;
		#$utime = $now - $tm * $utm; #+ $TMZ * 60 * 60;		
		$utime = $now + $tm * $utm; #+ $TMZ * 60 * 60;		
		#$utime = int($utime / $utm) * $utm + $TMZ * 60 * 60;
		dp::dp ">>> " . join(",", $utime, $unit, $utm) . "\n" if($DEBUG);
	}
	return $utime;
}
