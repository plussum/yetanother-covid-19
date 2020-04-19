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

my $DEBUG = 1;
my $WIN_PATH = "";
my $NO_DATA = "NaN";
sub	csvgpl
{
	my ($para) = @_;
 
	$DEBUG = &valdef($para->{debug} , $DEBUG);
	if($DEBUG){
		print "###### csvgpl #####\n";
		open(PARA, "> param.txt") || die "param.txt";
		print PARA Dumper $para ;
		close(PARA);
	}


	$WIN_PATH = &valdef($para->{win_path}, "./");
	#$REPORT_CSVF = "$WIN_PATH/who_situation_report_"; # MODE#.csv";
	#$GRAPH_HTML = "$WIN_PATH/who_situation_report_"; #MODE#.html";
	my $PNG_PATH = "$WIN_PATH/" . $para->{data_rel_path}; #MODE#.html";
	my $IMG_PATH = "./" . $para->{data_rel_path};
	#$REPORT_MAIN = "$WIN_PATH/who_report_main2.html";

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
		print ">>>>>> loop [$clp->{csvf}]\n" if($DEBUG);
		# $p->{kind} = $clp->{name};
		my ($png, @legs) = &csv2graph($clp->{csvf}, $PNG_PATH, $clp->{name}, $p);
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

	print join(", ", $p->{ext}, $p->{start_day}, $p->{lank}[0], $p->{lank}[1], $p->{exclusion}), "\n" if($DEBUG > 1);
	
	#
	#	Read CSV DATA
	#
	my @COL = ();
	my @DATA = ();
	print "[$csvf]\n" if($DEBUG > 1);

	open(CSV, $csvf) || die "cannot open $csvf";
	my $cls = <CSV>; 
	$cls =~ s/,*[\r\n]+$//;
	for(split(/,/, $cls)){
		# s#[0-9]{4}/##;
		push(@COL,  $_);
	}
	shift(@COL);
	shift(@COL);

	my $DATE_NUMBER = $#COL;
	my $LAST_DATE = $COL[$DATE_NUMBER];

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
		print "CSV: DATA\n";
		print "     :" , join(",", @COL) , "\n";
		for($l = 0; $l < 5; $l++){		# $COUNTRY_NUMBER
			print $DATA[$l][0] . ": ";
			for(my $i = 2; $i <= $DATE_NUMBER + 2; $i++){
				# print "# " . $i . "  " . $COL[$i-2] .":" ;
				print $DATA[$l][$i] , ",";
			}
			print "\n";
		}
		print "-" x 20 , "\n";
	}

	#
	#	Graph Parameter set
	#
	my $ext = $p->{ext};
	$ext =~ s/#KIND#/$kind/;
	my $fname = $ext;
	$fname =~ s/#LD#//;
	$fname =~ s#/#-#g;
	$fname =~ s/[\(\) ]//g;

	$ext =~ s/#LD#/$LAST_DATE/;

	my $PNGF = $png_path . "/" . $fname . ".png";
	my $PLOTCMD = $png_path . "/" . $fname . "-plot.txt";
	my $PLOTCSV = $png_path . "/" . $fname . "-plot.csv";
	print $PNGF , "\n" if($DEBUG > 1);		#### 
#	$PNGF =~ s/[\(\) ]//g;
	my $std = defined($p->{start_day}) ? $p->{start_day} : 0;
	if($std =~ /[0-9]+\/[0-9]+/){
		my $n = &search_list($std, @COL);
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

	print "TARGET: " , $p->{target}, "  " . $#target, "\n" if($DEBUG > 1);

	my @DATES = @COL[$std..$end];
	print "DATES: ", join(",", @DATES) , "\n" if($DEBUG > 1);

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
			my $c = &valdef($DATA[$cn][$dn+$std+2], 0);
			$COUNT_D{$country}[$dn] = $c;
			$tl += $c;
		}
		$CTG{$country} = $tl;
		$TOTAL{$country} = $DATA[$cn][1];
		#print "$country : " . $TOTAL{$country} . "\n";
	}

	#
	#	グラフ用の配列の作成
	#
	my @Dataset = (\@DATES);
	foreach my $country (sort {$CTG{$b} <=> $CTG{$a}} keys %CTG){
		next if($#exclusion >= 0 && &search_list($country, @exclusion));
		next if($#target >= 0 && $#exclusion >= 0 && ! &search_list($country, @target));
		print "Yes, Target $CNT $tgcs $tgce\n" if($DEBUG > 1);

		$CNT++;
		next if($CNT < $tgcs || $CNT > $tgce);

		push(@LEGEND_KEYS, sprintf("%02d:%s", $CNT+1, $country));
		foreach my $dtn (@{$COUNT_D{$country}}){
			$MAX_COUNT = $dtn if(defined $dtn && $dtn > $MAX_COUNT);
		}
		push(@Dataset, [@{$COUNT_D{$country}}]);
		push(@COUNTRY, $country);
		print "COUNT_D: ", join (",", @{$COUNT_D{$country}}) , "\n" if($DEBUG > 1);
	}

	if($DEBUG > 1){
		print "Dataset: " . $#Dataset, "\n";
		print join(",", "", "", @{$Dataset[0]}), "\n";
		for (my $i = 1; $i <= $#Dataset; $i++){
			print "Dataset[$i]:" . $Dataset[$i], "  ";
			print join(",", "$i", $LEGEND_KEYS[$i-1], @{$Dataset[$i]}), "\n";
		}
		print "-" x 20 , "\n";
	}

	#
	#	グラフの生成 CSV
	#
	my @record = ();
	my $max_data = 0;
	for(my $dt = 0; $dt <= $#DATES; $dt++){
		my @data = ($DATES[$dt]);
		for (my $i = 1; $i <= $#Dataset; $i++){
			my $v = $Dataset[$i][$dt];
			my $country = $COUNTRY[$i-1];
			#print "### [$country]: ";
			my $item_number = $TOTAL{$country};
			if(defined $p->{average}){
				# print "$item_number : $dt";
				my $av = 0;
				if($dt > $item_number){
					$v = $NO_DATA;
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

	print "#### " . $#record . ":$final_rec\n" if($DEBUG);
	open(DF, "> $PLOTCSV") || die "cannot create $PLOTCSV\n";
	print DF join(",", "#", @LEGEND_KEYS), "\n";
	for(my $i = 0; $i <= $final_rec; $i++){
		my $rr = $record[$i];
		print DF $rr , "\n";
	}
	close(DF);

	my $pltfile = "$WIN_PATH/plt.txt";
	my $TITLE = $ext;
	my $XLABEL = "";
	my $YLABEL = "";
	my $START_DATE = $DATES[0];
	$LAST_DATE = $DATES[$#DATES];
	

	my $DATE_FORMAT = "set xdata time\n set timefmt '%m/%d'\nset format x '%m/%d'\n";
	my $XRANGE = "set xrange ['$START_DATE':'$LAST_DATE']";
	if(defined $p->{series}){
		$DATE_FORMAT = "";
		$XRANGE = "set xrange [1:" . $final_rec . "]";
	}
	my $TERM_XSIZE = &valdef($p->{term_xsize}, 1000) ;
	my $TERM_YSIZE = &valdef($p->{term_ysize}, 300);

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
set output '$PNGF'
plot #PLOT_PARAM#
exit
_EOD_

	my @w = ();
	for(my $i = 0; $i <= $#LEGEND_KEYS; $i++){
		my $country = $LEGEND_KEYS[$i];
		$country =~ s/'//g;
		push(@w, sprintf("'%s' using 1:%d with lines title '%s' linewidth %d ", 
					$PLOTCSV, $i+2, $country, ($i < 5) ? 2 : 1)
			);
	}
	my $pn = join(",", @w); 
	if(defined $p->{additional_plot} && $p->{additional_plot}){
		$pn .= ", " . $p->{additional_plot};
	}
	$PARAMS =~ s/#PLOT_PARAM#/$pn/;	

	my $ymin = &valdef($p->{ymin}, "");
	my $ymax = &valdef($p->{ymax}, "");
	if(! $ymax ){
		$ymax = &calc_max($max_data, defined $p->{logscale});
	}
	$PARAMS =~ s/#YRANGE#/$ymin:$ymax/;	
	my $logs = "nologscale";
	$logs = "logscale " . $p->{logscale} if(defined $p->{logscale});
	$PARAMS =~ s/#LOGSCALE#/$logs/;

	my $xtics = 3600 * 24;
	if(defined $p->{series}){
		$xtics = &valdef($p->{y_label_skip}, 1);
	}
	else {
		if(defined $p->{label_skip}){
			$xtics = $p->{label_skip} * 3600 * 24;;
		}
	}
	$PARAMS =~ s/#XTICKS#/$xtics/;
#	print "[[[$PARAMS]]]\n";

	open(PLF, "> $PLOTCMD") || die "cannot create $pltfile";
	print PLF $PARAMS;
	close(PLF);

	print ("gnuplot $PLOTCMD\n") if(1 || $DEBUG > 1);
	system("gnuplot $PLOTCMD");

	return ($fname . ".png", @LEGEND_KEYS);
}

sub	valdef
{
	my ($v, $d) = @_;
	$d = 0 if(! defined $d);
	
	return defined $v ? $v : $d;
}
sub search_list
{
    my ($country, @w) = @_;
	my $n = 0;

    foreach my $ntc (@w){
        if($country =~ /$ntc/){
            print "search_list: $country:$ntc\n" if($DEBUG > 1);
            return $n+1;
        }
		$n++;
    }
    return "";
}
sub	calc_max
{
	my ($v, $log) = @_;

	my $digit = int(log($v)/log(10));
	my $max = 0;
	if(!$log){
		$max = (int(($v / 10**$digit)*10 + 9.999)/10) * 10**$digit;
	}
	else {
		$max = 10**($digit+1);
	}

	print "ymax:[$v:$max]\n";

	return $max;

}

1;
