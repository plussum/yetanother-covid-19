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
use csvlib;
use dp;

my $DEBUG = 1;
my $WIN_PATH = "";
my $NO_DATA = "NaN";
sub	csvgpl
{
	my ($para) = @_;
 
	$DEBUG = csvlib::valdef($para->{debug} , $DEBUG);
	if($DEBUG){
		print "###### csvgpl #####\n";
		open(PARA, "> param.txt") || die "param.txt";
		print PARA Dumper $para ;
		close(PARA);
	}


	$WIN_PATH = csvlib::valdef($para->{win_path}, "./");
	my $PNG_PATH = "$WIN_PATH/" . $para->{data_rel_path}; #MODE#.html";
	my $IMG_PATH = "./" . $para->{data_rel_path};

	my $clp = $para->{clp};
	my $grp = $para->{params};

my $CSS = << "_EOCSS_";
	<meta charset="utf-8">
	<style type="text/css">
	<!--
		span.c {font-size: 12px;}
	-->
	</style>
_EOCSS_

	my $TBL_SIZE = 10;
	my $class = "class=\"c\"";

	print "TITLE: $clp->{name} \n $clp->{htmlf}\n";
	open(HTML, "> $clp->{htmlf}") || die "Cannot create file $clp->{htmlf}";
	print HTML "<HTML>\n";
	print HTML "<HEAD>\n";
	print HTML "<TITLE> $clp->{name} </TITLE>\n";
	print HTML $CSS;
	print HTML "</HEAD>\n";
	print HTML "<BODY>\n";
	#print HTML "SOURCE: <a href = \"$WHO_PAGE\"> WHO situation Reports</a>\n<br>\n";

	foreach my $p (@$grp){
		# $p->{kind} = $clp->{name};
		my ($png, $plot, $csv, @legs) = &csv2graph($clp->{csvf}, $PNG_PATH, $clp->{name}, $p);
		print HTML "<img src=\"$IMG_PATH/$png\">\n";
		print HTML "<br>\n";
		if(defined $clp->{src_ref}){
			print HTML "<span $class> Data Source $clp->{src_ref} </span>\n";
		}
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
		print HTML "PNG:<a href=\"./cov_data/$png\">$png</a> CSV:<a type=\"text/plain\" href=\"./cov_data/$csv\">$csv</a> PLOT:<a href=\"./cov_data/$plot\">$plot</a>";
		print HTML "</span>\n";
		print HTML "<br><hr>\n";
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
	my ($csvf, $png_path, $kind, $p) = @_;

	dp::dp join(", ", $p->{ext}, $p->{start_day}, $p->{lank}[0], $p->{lank}[1], $p->{exclusion}), "\n" if($DEBUG > 1);
	
	my $ext = $p->{ext};
	$ext =~ s/#KIND#/$kind/;
	my $fname = $ext;
	$fname =~ s/#LD#//;
	$fname =~ s#/#-#g;
	$fname =~ s/[\(\) ]//g;
	

	my $plot_pngf = $png_path . "/" . $fname . ".png";
	my $plot_cmdf = $png_path . "/" . $fname . "-plot.txt";
	my $plot_csvf = $png_path . "/" . $fname . "-plot.csv.txt";
	dp::dp $plot_pngf , "\n" if($DEBUG > 1);		#### 
	dp::dp "SRC CSV [$csvf]\n" if($DEBUG);
	dp::dp "DST CSV [$plot_csvf]\n" if($DEBUG);
	dp::dp "DST CMD [$plot_cmdf]\n" if($DEBUG);
	dp::dp "DST PNG [$plot_pngf]\n" if($DEBUG);

#	$plot_pngf =~ s/[\(\) ]//g;
	#
	#	Read CSV DATA
	#
	my @COL = ();
	my @DATA = ();

	open(CSV, $csvf) || die "cannot open $csvf";
	my $cls = <CSV>; 
	$cls =~ s/,*[\r\n]+$//;
	for(split(/,/, $cls)){
		# s#[0-9]{4}/##;
		push(@COL,  $_);
	}
	shift(@COL);
	shift(@COL);
	dp::dp join(",", @COL), "\n" if($DEBUG > 2);

	my $DATE_NUMBER = $#COL;
	my $LAST_DATE = $COL[$DATE_NUMBER];
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
		dp::dp "     :" , join(",", @COL) , "\n";
		for($l = 0; $l < 5; $l++){		# $COUNTRY_NUMBER
			dp::dp $DATA[$l][0] . ": ";
			for(my $i = 2; $i <= $DATE_NUMBER + 2; $i++){
				# print "# " . $i . "  " . $COL[$i-2] .":" ;
				print $DATA[$l][$i] , ",";
			}
			print "\n";
		}
		dp::dp "-" x 20 , "\n";
	}

	#
	#	Graph Parameter set
	#
	my $std = defined($p->{start_day}) ? $p->{start_day} : 0;
	if($std =~ /[0-9]+\/[0-9]+/){
		my $n = csvlib::search_list($std, @COL);
		#print ">>>> $std: $n " . $COL[$n-1] . "\n";
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
	my $tgcs = $p->{lank}[0];						# 対象ランク
	my $tgce = $p->{lank}[1];						# 対象ランク 
	$tgce = $COUNTRY_NUMBER if($tgce > $COUNTRY_NUMBER);

	my @exclusion = split(/,/, $p->{exclusion});	# 除外国
	my @target = split(/,/, $p->{target});			# 明示的対象国

	dp::dp "TARGET: " , $p->{target}, "  " . $#target, "\n" if($DEBUG > 1);

	my @DATES = @COL[$std..$end];
	dp::dp "DATES: ", join(",", @DATES) , "\n" if($DEBUG > 1);

	my @LEGEND_KEYS = ();
	my $MAX_COUNT = 0;
	my $CNT = -1;
	my %CTG = ();
	my %COUNT_D = ();
	my %TOTAL = ();
	my @COUNTRY = ();
	#
	#	ソート用の配列の作成
	#
	for(my $cn = 0; $cn <= $COUNTRY_NUMBER; $cn++){
		my $country = $DATA[$cn][0];
		next if(! $country);

		my $tl = 0;
		for(my $dn = 0; $dn < $dates; $dn++){
			my $p = $dn+$std+2;
			my $c = csvlib::valdef($DATA[$cn][$p], 0);
			#print "($dn:$std:$p:$c)";
			$COUNT_D{$country}[$dn] = $c;
			$tl += $c;
		}
		$CTG{$country} = $tl;
		$TOTAL{$country} = $DATA[$cn][1];
		#dp::dp "$country : " . $TOTAL{$country} . "\n";
	}

	#
	#	グラフ用の配列の作成
	#
	my @Dataset = (\@DATES);
	foreach my $country (sort {$CTG{$b} <=> $CTG{$a}} keys %CTG){
		next if($#exclusion >= 0 && csvlib::search_list($country, @exclusion));
		next if($#target >= 0 && $#exclusion >= 0 && ! csvlib::search_list($country, @target));
		dp::dp "Yes, Target $CNT $tgcs $tgce\n" if($DEBUG > 1);

		$CNT++;
		next if($CNT < $tgcs || $CNT > $tgce);

		push(@LEGEND_KEYS, sprintf("%02d:%s", $CNT+1, $country));
		foreach my $dtn (@{$COUNT_D{$country}}){
			$MAX_COUNT = $dtn if(defined $dtn && $dtn > $MAX_COUNT);
		}
		push(@Dataset, [@{$COUNT_D{$country}}]);
		push(@COUNTRY, $country);
		dp::dp "COUNT_D: ", join (",", @{$COUNT_D{$country}}) , "\n" if($DEBUG > 1);
	}

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
	my @record = ();
	my $max_data = 0;
	for(my $dt = 0; $dt <= $#DATES; $dt++){
		my $dts  = $DATES[$dt];
		$dts =~ s#([0-9]{4})([0-9]{2})([0-9]{2})#$1/$2/$3#;
		#print "[[$DATES[$dt]][$dts]\n";
		my @data = ($dts);
		for (my $i = 1; $i <= $#Dataset; $i++){
			my $v = $Dataset[$i][$dt];
			my $country = $COUNTRY[$i-1];
			#print "### [$country]: ";
			my $item_number = $TOTAL{$country};
			if(defined $p->{average}){
				# print "$item_number : $dt";
				my $av = 0;
				if($dt > $item_number){
					$v = $NO_DATA;			# for FT, set nodata
				}
				else {
					for(my $ma = $dt - $p->{average}; $ma <= $dt; $ma++){
						my $d = $Dataset[$i][$dt];
						if($ma >= 0) {
							$d = $Dataset[$i][$ma];
						}
						$av += $d;
						#print "($i: $dt $ma $av)";
					}
					$v = int(0.5 + $av / $p->{average});
					$v = 1 if($v < 1 && defined $p->{logscale});
				}
				#print "--> $v\n";
			}
			push(@data, $v);
			$max_data = $v if($v > $max_data);
		}
		push(@record, join(",", @data));
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
	my $TITLE = $ext;
	my $XLABEL = "";
	my $YLABEL = "";
	my $START_DATE = $DATES[0];
	$LAST_DATE = $DATES[$#DATES];

	my $DATE_FORMAT = "set xdata time\nset timefmt '%m/%d'\nset format x '%m/%d'\n";
	my $XRANGE = "set xrange ['$START_DATE':'$LAST_DATE']";
	if(defined $p->{series}){
		$DATE_FORMAT = "";
		$XRANGE = "set xrange [1:" . $final_rec . "]";
	}
	my $TERM_XSIZE = csvlib::valdef($p->{term_xsize}, 1000) ;
	my $TERM_YSIZE = csvlib::valdef($p->{term_ysize}, 300);

my $PARAMS = << "_EOD_";
set datafile separator ','
set xtics rotate by -90
$DATE_FORMAT
set mxtics 2
set mytics 2
set grid xtics ytics mxtics mytics
set key below
# second ax
#set y2tics
#
set title '$TITLE'
set xlabel '$XLABEL'
set ylabel '$YLABEL'
#
set xtics #XTICKS#
#set xrange ['$START_DATE':'$LAST_DATE']
$XRANGE
set yrange [#YRANGE#]
set terminal pngcairo size $TERM_XSIZE, $TERM_YSIZE font "IPAexゴシック,8" enhanced
set #LOGSCALE#
set output '$plot_pngf'
plot #PLOT_PARAM#
exit
_EOD_

	my @w = ();
	for(my $i = 0; $i <= $#LEGEND_KEYS; $i++){
		my $country = $LEGEND_KEYS[$i];
		$country =~ s/'//g;
		push(@w, sprintf("'%s' using 1:%d with lines title '%s' linewidth %d ", 
					$plot_csvf, $i+2, $country, ($i < 5) ? 2 : 1)
			);
	}
	my $pn = join(",", @w); 
	if(defined $p->{additional_plot} && $p->{additional_plot}){
		$pn .= ", " . $p->{additional_plot};
	}
	$PARAMS =~ s/#PLOT_PARAM#/$pn/;	

	my $ymin = csvlib::valdef($p->{ymin}, "");
	my $ymax = csvlib::valdef($p->{ymax}, "");
	if(! $ymax ){
		$ymax = csvlib::calc_max($max_data, defined $p->{logscale});
	}
	$PARAMS =~ s/#YRANGE#/$ymin:$ymax/;	
	my $logs = "nologscale";
	$logs = "logscale " . $p->{logscale} if(defined $p->{logscale});
	$PARAMS =~ s/#LOGSCALE#/$logs/;

	my $xtics = 3600 * 24;
	if(defined $p->{series}){
		$xtics = csvlib::valdef($p->{y_label_skip}, 1);
	}
	else {
		if(defined $p->{label_skip}){
			$xtics = $p->{label_skip} * 3600 * 24;;
		}
	}
	$PARAMS =~ s/#XTICKS#/$xtics/;
#	print "[[[$PARAMS]]]\n";

	open(PLF, "> $plot_cmdf") || die "cannot create $plot_cmdf";
	print PLF $PARAMS;
	close(PLF);

	print ("gnuplot $plot_cmdf\n") if(1 || $DEBUG > 1);
	system("gnuplot $plot_cmdf");

	$plot_pngf =~ s#.*/##;
	$plot_cmdf =~ s#.*/##;
	$plot_csvf =~ s#.*/##;
#	return ("$fname.png", "$fname-plot.txt", "$fname-plot.csv", @LEGEND_KEYS);
	return ($plot_pngf, $plot_cmdf, $plot_csvf, @LEGEND_KEYS);
}
1;
