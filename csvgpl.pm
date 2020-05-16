#!/usr/bin/perl
#
#
package csvgpl;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(csvgpl);

use strict;
use warnings;
use Data::Dumper;
use config;
use csvlib;
use dp;

my $DEBUG = 1;
my $VERBOSE = 0;
my $WIN_PATH = "";
my $NO_DATA = "NaN";

my %CNT_POP = ();

sub	csvgpl
{
	my ($csvgplp) = @_;
 
	$DEBUG = csvlib::valdef($csvgplp->{debug} , $DEBUG);
	if($DEBUG){
		print "###### csvgpl #####\n";
		open(PARA, "> param.txt") || die "param.txt";
		print PARA Dumper $csvgplp ;
		close(PARA);
	}
	my $aggr_mode = csvlib::valdefs($csvgplp->{aggr_mode});		# Added 05/03 for Population
	if($aggr_mode eq "POP"){
		#dp::dp( "###### $aggr_mode: " . $csvgplp->{src} . "\n") if(1 || $DEBUG > 1);
		if($csvgplp->{src} eq "ccse"){
			#dp::dp "POP:ccse\n";
			csvlib::cnt_pop(\%CNT_POP);
		}
		elsif($csvgplp->{src} eq "jag"){
			#dp::dp "POP:ccse\n";
			csvlib::cnt_pop_jp(\%CNT_POP);
		}
		else {
			dp::dp "ERROR at POP\n";
			exit 1;
		}
	}

	$WIN_PATH = $config::WIN_PATH;
	my $PNG_PATH = $config::PNG_PATH; 
	my $PNG_REL_PATH = $config::PNG_REL_PATH; 
	my $IMG_PATH = $config::PNG_REL_PATH;
	my $CSV_REL_PATH = $config::CSV_REL_PATH; 
	my $CSS = $config::CSS;
	my $class = $config::CLASS;

	my $clp = $csvgplp->{clp};
	my $gplp = $csvgplp->{gplp};
	my $mep = $csvgplp->{mep};

	my $src_url = $clp->{src_url};
    my $src_ref = "<a href=\"$src_url\">$src_url</a>";
	my $TBL_SIZE = 10;

	dp::dp "TITLE: $clp->{name} \n $clp->{htmlf}\n" if($VERBOSE);
	open(HTML, "> $clp->{htmlf}") || die "Cannot create file $clp->{htmlf}";
	print HTML "<HTML>\n";
	print HTML "<HEAD>\n";
	print HTML "<TITLE> $clp->{name} </TITLE>\n";
	print HTML $CSS;
	print HTML "</HEAD>\n";
	print HTML "<BODY>\n";
	my $now = csvlib::ut2d4(time, "/") . " " . csvlib::ut2t(time, ":");

	#print HTML "SOURCE: <a href = \"$WHO_PAGE\"> WHO situation Reports</a>\n<br>\n";

	foreach my $gplitem (@$gplp){
		# $gplitem->{kind} = $clp->{name};
		if($gplitem->{ext} eq "EOD"){
			print "#### EOD ###\n";
			last;
		}
		my ($png, $plot, $csv, @legs) = &csv2graph($clp->{csvf}, $PNG_PATH, $clp->{name}, $gplitem, $clp, $mep, $aggr_mode);

		print HTML "<!-- " . $gplitem->{ext} . " -->\n";
		print HTML "<span class=\"c\">$now</span><br>\n";
		print HTML "<img src=\"$IMG_PATH/$png\">\n";
		print HTML "<br>\n";
		print HTML "<span $class> Data Source $src_ref </span>\n";
		print HTML "<hr>\n";
		print HTML "<TABLE>";
		for(my $l = 0; $l <= $#legs; $l++){
			$_ = $legs[$l];
			print HTML "<TR>" if(($l % $TBL_SIZE) == 0);
			print HTML "<TD> <span class=\"c\"> $_ </span> </TD>";
			print HTML "</TR>\n" if($l == $#legs || ($l % $TBL_SIZE) == ($TBL_SIZE - 1));
		}
		print HTML "</TABLE>";
		print HTML "<span $class>";

		my $csvf = $clp->{csvf};
		my $srcf = csvlib::valdef($clp->{src_file}, "");
		dp::dp $srcf , "\n" if($srcf && $VERBOSE);
		$csvf =~ s#.*/##;
		$srcf =~ s#.*/##;
		my @refs = (join(":", "PNG", $PNG_REL_PATH, $png),
					join(":", "CSV", $PNG_REL_PATH, $csv),
					join(":", "PLT", $PNG_REL_PATH, $plot),
					join(":", "REF", $CSV_REL_PATH, $csvf),
					join(":", "SRC", $CSV_REL_PATH, $srcf),
		);
		#dp::dp "##### SRC:[$srcf][" . $clp->{srcf} . "]\n";
		#dp::dp "##### refs \n" . Dumper(@refs) . "]\n";
		foreach my $r (@refs){
			my ($tag, $path, $fn) = split(":", $r);
			#dp::dp "r:[$r]  $tag, $path, $fn\n";
			#dp::dp "$tag:<a href=\"$path/$fn\">$fn</a>\n"; 
			if($fn){
				print HTML "$tag:<a href=\"$path/$fn\">$fn</a>\n"; 
			}
			else {
				print HTML "$tag:\n"; 
			}
		}
		print HTML "</span>\n";
		print HTML "<br><hr>\n\n";
	}
	print HTML "</BODY>\n";
	print HTML "</HTML>\n";
	close(HTML);
}

#
#
#
sub	csv2graph
{
	my ($csvf, $png_path, $kind, $gplitem, $clp, $mep, $aggr_mode) = @_;

	dp::dp join(", ", $gplitem->{ext}, $gplitem->{start_day}, $gplitem->{lank}[0], $gplitem->{lank}[1], $gplitem->{exclusion}, 
			"[" . $clp->{src} . "]", $mep->{prefix}), "\n" if($DEBUG > 1);
	
	my $src = csvlib::valdefs($gplitem->{src}, "");
	my $ext = $mep->{prefix} . " " . $gplitem->{ext};
	$ext =~ s/#KIND#/$kind/;
	$ext =~ s/#SRC#/$src/;
	#dp::dp $ext . "\n";
	my $fname = $ext;
	$fname =~ s/#LD#//;
	$fname =~ s#/#-#g;
	$fname =~ s/[^0-9a-zA-Z]+/_/g;

	my $plot_pngf = $png_path . "/" . $fname . ".png";
	my $plot_cmdf = $png_path . "/" . $fname . "-plot.txt";
	my $plot_csvf = $png_path . "/" . $fname . "-plot.csv.txt";
	if($DEBUG){
		dp::dp $plot_pngf , "\n" ;		#### 
		dp::dp "SRC CSV [$csvf]\n" ;
		dp::dp "DST CSV [$plot_csvf]\n";
		dp::dp "DST CMD [$plot_cmdf]\n";
		dp::dp "DST PNG [$plot_pngf]\n";
	}

#	$plot_pngf =~ s/[\(\) ]//g;
	#
	#	Read CSV DATA
	#
	my @DATE_LABEL = ();
	my @DATA = ();
	my $DATE_COL_NO = 2;

	open(CSV, $csvf) || die "cannot open $csvf";
	my $cls = <CSV>; 
	$cls =~ s/,*[\r\n]+$//;
	for(split(/,/, $cls)){
		# s#[0-9]{4}/##;
		push(@DATE_LABEL,  $_);
	}
	for(my $i = 0; $i <$DATE_COL_NO; $i++){
		shift(@DATE_LABEL);
	}
	dp::dp join(",", @DATE_LABEL), "\n" if($DEBUG > 2);

	my $DATE_NUMBER = $#DATE_LABEL;
	my $LAST_DATE = $DATE_LABEL[$DATE_NUMBER];
	$ext =~ s/#LD#/$LAST_DATE/;

	my $l;
	for($l = 0; <CSV>; $l++){
		chop;
		my @w = split(/,/, $_); 
		for(my $i = 0; $i <= $#w; $i++){
			$DATA[$l][$i] = $w[$i];
		}
	}
	close(CSV);
	
	my $COUNTRY_NUMBER = $l;

	if($DEBUG > 1){
		dp::dp "CSV: DATA\n";
		dp::dp "     :" , join(",", @DATE_LABEL) , "\n";
		for($l = 0; $l < 5; $l++){		# $COUNTRY_NUMBER
			dp::dp $DATA[$l][0] . ": ";
			for(my $i = $DATE_COL_NO; $i <= $DATE_NUMBER + $DATE_COL_NO; $i++){
				# print "# " . $i . "  " . $DATE_LABEL[$i-$DATE_COL_NO] .":" ;
				print $DATA[$l][$i] , ",";
			}
			print "\n";
		}
		dp::dp "-" x 20 , "\n";
	}

	#
	#	Graph Parameter set
	#
	my $std = defined($gplitem->{start_day}) ? $gplitem->{start_day} : 0;
	if($std =~ /[0-9]+\/[0-9]+/){
		my $n = csvlib::search_list($std, @DATE_LABEL);
		#dp::dp ">>>> $std: $n " . $DATE_LABEL[$n-1] . "\n";
		#dp::dp ">>> " . join(",", @DATE_LABEL) . "\n";
		if($n > 0){
			$std = $n - 1;
		}
	}
	elsif($std < 0){
		$std = -$std;
		$std = $DATE_NUMBER - $std
	}	
	my $end = $DATE_NUMBER;
	my $dates = $end - $std + 1;
	my $tgcs = $gplitem->{lank}[0];						# 対象ランク
	my $tgce = $gplitem->{lank}[1];						# 対象ランク 
	$tgce = $COUNTRY_NUMBER if($tgce > $COUNTRY_NUMBER);

	my @exclusion = split(/,/, $gplitem->{exclusion});	# 除外国
	my @target = split(/,/, csvlib::valdefs($gplitem->{target}, ""));			# 明示的対象国
	my @add_target = split(/,/, csvlib::valdefs($gplitem->{add_target}, ""));	# 追加する対象国

	dp::dp "EXCLUS: " , $gplitem->{exclusion}, "  " . $#exclusion, "\n" if($DEBUG > 1);
	dp::dp "TARGET: " , $gplitem->{target}, "  " . $#target, "\n" if($DEBUG > 1);
	dp::dp "ADD_TARGET: " , $gplitem->{add_target}, "  " . $#add_target, "\n" if($DEBUG > 1);

	my @DATES = @DATE_LABEL[$std..$end];
	dp::dp "DATES: ", join(",", @DATES) , "\n" if($DEBUG > 1);

	my @LEGEND_KEYS = ();
	my $MAX_COUNT = 0;
	my %CTG = ();
	my %COUNT_D = ();
	my %TOTAL = ();
	my @COUNTRY = ();
	my $avr_date = csvlib::valdef($gplitem->{avr_date});

	#
	#	ソート用の配列の作成
	#
	for(my $cn = 0; $cn <= $COUNTRY_NUMBER; $cn++){
		my $country = $DATA[$cn][0];
		next if(! $country);

		#dp::dp join(",", @{$DATA[$cn]}) . "\n" if($country =~ /Sint/ || $country =~ /Japan/);
		my $tl = 0;
		for(my $dn = 0; $dn < $dates; $dn++){
			my $p = $dn+$std+$DATE_COL_NO;
			my $c = csvlib::valdef($DATA[$cn][$p], 0);
			if($c =~ /[^0-9]\-\./){
				dp::dp "($dn:$std:$p:$c:$csvf)\n";
			}
			if($c =~ /^[^0-9]+$/){			# Patch for bug of former data, may be
				dp::dp "DATA ERROR at $country($dn) $c\n" if($DEBUG);
				$tl = -1;
				last;
			}
			if($avr_date){
				my $pp = $p - $DATE_COL_NO;
				my $s = ($pp > $avr_date) ? ($p - $avr_date + 1): $DATE_COL_NO;
				my $e = $p;
				$c = csvlib::avr($DATA[$cn], $s, $e);
			}
			$COUNT_D{$country}[$dn] = $c;
			$tl += $c;
		}
		if($tl > 0){
			$CTG{$country} = $tl;
			$TOTAL{$country} = $DATA[$cn][1];
		}
		#dp::dp "$country : " . $TOTAL{$country} . "\n";
	}

	#
	#	グラフ用の配列の作成
	#
	my @Dataset = (\@DATES);
	my $CNT = -1;
	my $rn = 0;
	#open(POPT, "> $config::WIN_PATH/poptest.csv") || die "Cannot create $config::WIN_PATH/poptest.csv";
	foreach my $country (sort {$CTG{$b} <=> $CTG{$a}} keys %CTG){
		$rn++;
		next if($#exclusion >= 0 && csvlib::search_list($country, @exclusion));
		#next if($#target >= 0 && $#exclusion >= 0 && ! csvlib::search_list($country, @target));
		next if($#target >= 0 && ! csvlib::search_list($country, @target));
		dp::dp "Yes, Target $CNT $country [$tgcs, $tgce]\n" if($DEBUG && $#target >= 0);
		if($aggr_mode eq "POP"){			# if aggr_mode eq POP, ignore if country population < $POP_THRESH
			next if(!defined $CNT_POP{$country});
			# dp::dp "[$country][" . $CNT_POP{$country} . "]\n";
			next if($CNT_POP{$country} < $config::POP_THRESH);
		}

		$CNT++;
		if($CNT < $tgcs || $CNT > $tgce){
			next if($#add_target < 0);
			next if(! csvlib::search_list($country, @add_target));
			#my $cr = csvlib::search_list($country, @add_target);
			#dp::dp "[$cr] $country:" . join(",", @add_target) . "\n";
		}

		push(@LEGEND_KEYS, sprintf("%02d:%s", $rn, $country));
		#foreach my $dtn (@{$COUNT_D{$country}}){
		#dp::dp "COUNT: " .$#{$COUNT_D{$country}} . "\n";
		#print POPT join(",", $country, $CNT_POP{$country}) . "\n";
		#print POPT "ORG,", join (",", @{$COUNT_D{$country}}) . "\n" ;
		for(my $i = 0; $i <= $#{$COUNT_D{$country}}; $i++){
			my $dtn = $COUNT_D{$country}[$i];
			if($aggr_mode eq "POP"){
				$dtn /= ($CNT_POP{$country} / $config::POP_BASE) ;
				$COUNT_D{$country}[$i] = $dtn * $mep->{AGGR_MODE}{POP};
			}
			$MAX_COUNT = $dtn if(defined $dtn && $dtn > $MAX_COUNT);
		}
		#print POPT "POP,", join (",", @{$COUNT_D{$country}}) . "\n" ;
		push(@Dataset, [@{$COUNT_D{$country}}]);
		push(@COUNTRY, $country);
		dp::dp "COUNT_D: ", join (",", @{$COUNT_D{$country}}) , "\n" if($DEBUG > 1);
	}
	#close(POPT);

	if($DEBUG > 1){
		dp::dp "Dataset: " . $#Dataset, "\n";
		dp::dp join(",", "", "", @{$Dataset[0]}), "\n";
		for (my $i = 1; $i <= $#Dataset; $i++){
			print "Dataset[$i]:" . $Dataset[$i], "  ";
			print join(",", "$i", $LEGEND_KEYS[$i-1], @{$Dataset[$i]}), "\n";
		}
		dp::dp "-" x 20 , "\n";
	}

	#
	#	グラフの生成 CSV
	#
	#dp::dp "AVERAGE_DATE : [" . $gplitem->{average_date} . "]\n";
	my @record = ();
	my $max_data = 0;
	for(my $dt = 0; $dt <= $#DATES; $dt++){
		my $dts  = $DATES[$dt];
		$dts =~ s#([0-9]{4})([0-9]{2})([0-9]{2})#$1/$2/$3#;
		$dts = $dt if(defined $gplitem->{ft});
		#print "[[$DATES[$dt]][$dts]\n";
		my @data = ();
		for (my $i = 1; $i <= $#Dataset; $i++){
			my $v = $Dataset[$i][$dt];
			my $country = $COUNTRY[$i-1];
			#print "### [$country]: ";
			my $item_number = $TOTAL{$country};
			#dp::dp "###### $item_number : $dt";
			if(defined $gplitem->{average_date}){
				my $av = 0;
				if($dt > $item_number){
					$v = $NO_DATA;			# for FT, set nodata
				}
				else {
					for(my $ma = $dt - $gplitem->{average_date}; $ma <= $dt; $ma++){
						my $d = $Dataset[$i][$dt];
						if($ma >= 0) {
							$d = $Dataset[$i][$ma];
						}
						$av += $d;
						#dp::dp "($i: $dt $ma $av)";
					}
					$v = int(0.5 + $av) / $gplitem->{average_date};
					#$v = int(100 * $av / $gplitem->{average_date}) / 100;
					#$v = 1 if($v < 1 && defined $gplitem->{logscale});
				}
				#print "--> $v\n";
			}
			if($gplitem->{logscale}){
				$v = $NO_DATA if($v < 1);
			}
			push(@data, $v);
			$max_data = $v if($v > $max_data);
		}
		push(@record, join(",", $dts, @data));
	}

	#
	#	for FT, 全てデータなしの相対日をグラフに入れないための処理
	#
	my $final_rec = 0;
	for(my $i = 0; $i <= $#record; $i++){
		my $rr = $record[$i];
		$rr =~ s/^[0-9]+,//;
		if($rr =~ /[0-9]/){
			$final_rec = $i;
		}
	}

	#
	#	グラフ生成用のCSVの作成
	#
	dp::dp "#### " . $#record . ":$final_rec\n" if($DEBUG);
	open(DF, "> $plot_csvf") || die "cannot create $plot_csvf\n";
	print DF join(",", "#", @LEGEND_KEYS), "\n";
	for(my $i = 0; $i <= $final_rec; $i++){
		my $rr = $record[$i];
		print DF $rr , "\n";
	}
	close(DF);

	#
	#	グラフ生成
	#
	my $TITLE = $ext . "  src:" . $clp->{src};
	my $XLABEL = "";
	my $YLABEL = "";
	my $START_DATE = $DATES[0];
	$LAST_DATE = $DATES[$#DATES];

	my $DATE_FORMAT = "set xdata time\nset timefmt '%m/%d'\nset format x '%m/%d'\n";
	my $XRANGE = "set xrange ['$START_DATE':'$LAST_DATE']";
	if(defined $gplitem->{series}){
		$DATE_FORMAT = "";
		$XRANGE = "set xrange [1:" . $final_rec . "]";
	}
	my $TERM_XSIZE = csvlib::valdef($gplitem->{term_xsize}, 1000) ;
	my $TERM_YSIZE = csvlib::valdef($gplitem->{term_ysize}, 300);

my $PARAMS = << "_EOD_";
set datafile separator ','
set xtics rotate by -90
$DATE_FORMAT
set mxtics 2
set mytics 2
set grid xtics ytics mxtics mytics
set key below
# second ax
#
set title '$TITLE' font "IPAexゴシック,12" enhanced
set xlabel '$XLABEL'
set ylabel '$YLABEL'
#
set xtics #XTICKS#
#set xrange ['$START_DATE':'$LAST_DATE']
$XRANGE
set yrange [#YRANGE#]
set terminal pngcairo size $TERM_XSIZE, $TERM_YSIZE font "IPAexゴシック,8" enhanced
#LOGSCALE#
#LOGSCALE2#
set y2tics
set output '$plot_pngf'
plot #PLOT_PARAM#
exit
_EOD_

	my @w = ();
	for(my $i = 0; $i <= $#LEGEND_KEYS; $i++){
		my $country = $LEGEND_KEYS[$i];
		$country =~ s/'//g;
		push(@w, sprintf("'%s' using 1:%d with lines title '%s' linewidth %d ", 
					$plot_csvf, $i+$DATE_COL_NO, $country, ($i < 5) ? 2 : 1)
			);
	}
	my $pn = join(",", @w); 
	if(defined $gplitem->{additional_plot} && $gplitem->{additional_plot}){
		#dp::dp "additional_plot: " . $gplitem->{additional_plot} . "\n";
		$pn .= ", " . $gplitem->{additional_plot};
	}
	$PARAMS =~ s/#PLOT_PARAM#/$pn/;	

	my $ymin = csvlib::valdef($gplitem->{ymin}, 0);
	my $ymax = csvlib::valdef($gplitem->{ymax}, "");
	if($gplitem->{logscale}){
		$ymax = csvlib::calc_max($max_data, defined $gplitem->{logscale}) if(! $ymax);
		$ymin = 1 if($ymin < 1);
		# dp::dp "YRANGE [$ymin:$ymax]\n";
	}
	$PARAMS =~ s/#YRANGE#/$ymin:$ymax/;	
	my $logs = "nologscale";
	if(defined $gplitem->{logscale}){
		$logs = "logscale " . $gplitem->{logscale}; 
		$PARAMS =~ s/#LOGSCALE#/set $logs/;

		$logs = "logscale " . $gplitem->{logscale} . "2";
		$PARAMS =~ s/#LOGSCALE2#/set $logs/;
	}

	my $xtics = 3600 * 24;
	if(defined $gplitem->{series}){
		$xtics = csvlib::valdef($gplitem->{y_label_skip}, 1);
	}
	else {
		if(defined $gplitem->{label_skip}){
			$xtics = $gplitem->{label_skip} * 3600 * 24;;
		}
	}
	$PARAMS =~ s/#XTICKS#/$xtics/;
#	print "[[[$PARAMS]]]\n";

	open(PLF, "> $plot_cmdf") || die "cannot create $plot_cmdf";
	print PLF $PARAMS;
	close(PLF);

	print ("gnuplot $plot_cmdf\n") if($VERBOSE || $DEBUG > 1);
	system("gnuplot $plot_cmdf");

	$plot_pngf =~ s#.*/##;
	$plot_cmdf =~ s#.*/##;
	$plot_csvf =~ s#.*/##;
#	return ("$fname.png", "$fname-plot.txt", "$fname-plot.csv", @LEGEND_KEYS);
	return ($plot_pngf, $plot_cmdf, $plot_csvf, @LEGEND_KEYS);
}
1;
