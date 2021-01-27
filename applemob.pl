#!/usr/bin/perl
#
#	Apple Mobile report
#	https://covid19.apple.com/mobility
#
#	Complete Data
#	https://covid19-static.cdn-apple.com/covid19-mobility-data/2025HotfixDev13/v3/en-us/applemobilitytrends-2021-01-25.csv
#
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
my $END_OF_DATA = "###EOD###";
my $TERM_X_SIZE = 1000;
my $TERM_Y_SIZE = 350;

my $DOWN_LOAD = 0;
my $DST_DLM = "\t";
my $AVR_DATE = 7;
my $MAIN_URL = "https://covid19.apple.com/mobility";
my $SRC_URL_TAG = "https://covid19-static.cdn-apple.com/covid19-mobility-data/2025HotfixDev13/v3/en-us/applemobilitytrends-%04d-%02d-%02d.csv";
my $SRC_CSVF =  "$config::WIN_PATH/applemobile/applemobilitytrends.csv.txt";
my $TITLE_HEAD = "Apple Mobility Trends";

my $DST_FILE = "$config::PNG_PATH/applemobile";
my $HTMLF = "$config::HTML_PATH/applemobile.html";

for(@ARGV){
}

my @PARAMS = (
# 	{dst => $END_OF_DATA},
	{dst => "Japan",  target_range => [1,999], graph => "AVR,RLAVR", target_area => "Japan", exclusion_are => "",},
);

my @OUTPUT_FILES = ();


#
#	Down Load CSV 
#


if($DOWN_LOAD){
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $src_url = sprintf($SRC_URL_TAG, $year + 1900, $mon + 1, $mday);
	my $wget = "wget $src_url -O $SRC_CSVF";
	dp::dp $wget ."\n" if($VERBOSE);
	system($wget);
}

#
#	Lpad CSV File
#
my %DATA = ();
my %REGION = ();
my %TRANSPORT = ();

open(FD, $SRC_CSVF) || die "Cannot open $SRC_CSVF";
my $line = <FD>;
chop $line;
$line = decode('utf-8', $line);
my @LABEL = split(/,/, $line);
my $FIRST_DATE = $LABEL[4];
my $LAST_DATE = $LABEL[$#LABEL];

my $ln = 0;
while(<FD>){
	#last if($ln++ > 50);
	s/[\r\n]+$//;
	my $line = decode('utf-8', $_);
	my ($geo_type, $region, $transport, $alternative_name, $sub_reagion, @data) = split(/,/, $line);

	my $k = join(",", $region, $transport);
	$DATA{$region}{$transport} = [@data];
	$REGION{$area}++;
	$TRANSPORT{$kind}++;

	#dp::dp join(",", $area, $mesh, $kind) . "\n";
}
close(FD);

#
#
#
for(my $i = 0; $i < 5; $i++){
	shift(@LABEL);
}
#dp::dp join(",", "# " . $TGK, @LABEL) . "\n";

#
#	MAIN LOOP
#
&gen_html($HTMLF, @PARAMS);

exit 0;

#
#
#
sub	gen_html
{
	my ($htmlf, @params) = @_;

	my $CSS = $config::CSS;
	my $class = $config::CLASS;

	open(HTML, ">$htmlf") || die "Cannot create file $htmlf";
	binmode(HTML, ":utf8");

	print HTML "<HTML>\n";
	print HTML "<HEAD>\n";
	print HTML "<TITLE> $TITLE_HEAD </TITLE>\n";
	print HTML $CSS;
	print HTML "</HEAD>\n";
	print HTML "<BODY>\n";
	my $now = csvlib::ut2d4(time, "/") . " " . csvlib::ut2t(time, ":");

	print HTML "<h3>データソース： <a href=\"$MAIN_URL\" target=\"blank\"> $TITLE_HEAD </a></h3>\n";
	#print HTML "<a href=\"$MAIN_URL\" target =\"blank\">$MAIN_URL</a>\n";

	foreach my $p (@params){
		&csv2graph($p);

		my $name = $p->{dst};
		$name =~ s/[\/\.\*\ ]/_/g;

		print HTML "<span class=\"c\">$now</span><br>\n";
		print HTML "<img src=\"../PNG/$name.png\">\n";
		print HTML "<br>\n";
		print HTML "<span $class> <a href=\"$SRC_URL\" target=\"blank\"> Data Source (CSV) </a></span>\n";
		print HTML "<hr>\n";
	
		print HTML "<span $class>";

		my @refs = (join(":", "PNG", "../PNG/$name.png"),
					join(":", "CSV", "../PNG/$name-plot.csv.txt"),
					join(":", "PLT", "../PNG/$name-plot.txt"),
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
	my($param) = @_;

	my @MATRIX = ();
	$MATRIX[0] = [ "# " . $TGK, @LABEL];

	{dst => "Japan",  target_range => [1,999], graph => "AVR,RLAVR", target_area => "Japan", exclusion_are => "",},
	dp::dp "DOCOMO  [$TGK] " . $param->{dst} . " " . $param->{graph} . "\n" if($VERBOSE);
	#dp::dp join(",", @{$param->{target_area}}) . "\n";
	my $rn = 1;
	my $tga = $param->{target_area};
	my $exc = $param->{exclusion_are};
	my $start_date = $param->{start_date} // $FIRST_DATE;
	my $end_date = $param->{end_date} // "$LAST_DATE";

	#dp::dp "#### " . ($param->{start_date} // "--") . " / " . ($param->{end_date} // "--") . "($start_date, $end_date)\n";

	my $dst = $param->{dst};
	$dst =~ s/[ \/]/_/g;

	foreach my $area (sort keys %AREA){
		#dp::dp "## tga " . @$tga . "\n";
		next if(@$tga > 0 && csvlib::search_list($area, @$tga) eq "");
		next if(@$exc > 0 && csvlib::search_list($area, @$exc));
		#dp::dp ">>> $area \n";

		foreach my $kind (sort keys %KIND){
			next if($kind ne $TGK);
			#dp::dp "### $kind \n";

			my $k = join(",", $area, $kind);
			next if(! defined $DOCOMO{$k});

			my @w = split(",", $DOCOMO{$k});
			#dp::dp join(",",  $area, $kind,  @w) . "\n";
			$MATRIX[$rn++] = [$area, @w];
		}
	}

	if($rn <= 1){
		my $errmes = sprintf("No data found in this parameter [%s][%s][%s]" ,
			join(",", @{$param->{target_area}}),
			join(",", @{$param->{exclusion_are}}),
			join(",", @{$param->{target_kind}})
		);
		dp::dp $errmes . "\n"; 
		next;
	}

	#
	#
	#
	my @matrix = ();
	my $p = {};
	my $dst_file = "";

	my ($col, $row) = csvlib::matrix_convert(\@MATRIX, \@matrix);
	if($param->{graph} eq "RAW"){
		my @matrix_sorted = ();
		csvlib::maratix_sort_max(\@matrix, \@matrix_sorted);
		$dst_file = join("_", $DST_FILE, $dst);
		$p = {
			datap => \@matrix_sorted,
			dst_file => $dst_file,
			title => "$TITLE_HEAD [$TGK] " . $param->{dst} . " ",
			target_range => $param->{target_range},
			start_date => $start_date,
			end_date => $end_date,
		};
		&graph($p);
	}


	#
	#
	#
	if($param->{graph} eq "RLA"){
		my @matrix_avr = ();
		my @matrix_sorted = ();
		csvlib::matrix_roling_average(\@matrix, \@matrix_avr, $AVR_DATE);
		csvlib::maratix_sort_max(\@matrix_avr, \@matrix_sorted);
		$dst_file = $DST_FILE . $dst . "rlavr__maxval";
		$p = {
			datap => \@matrix_sorted,
			dst_file => $dst_file,
			title => "$TITLE_HEAD  [$TGK] " . $param->{dst} . " (rlavr-$AVR_DATE)",
			target_range => $param->{target_range},
			start_date => $start_date,
			end_date => $end_date,
		};
		&graph($p);
	}

	#
	#
	#
	if($param->{graph} =~ /AVR/){
		my @matrix_avr = ();
		my @matrix_rl_avr = ();
		my @matrix_sorted = ();
		my $matrixp = \@matrix_avr;
		my $title = "$TITLE_HEAD [$TGK] " . $param->{dst} . " (avr)";  

		my $sp = $param->{summary};
		#if($sp){
		#	dp::dp $sp, @$sp . "\n";
		#	dp::dp join(",", @$sp) . "\n";
		#}
	
		csvlib::matrix_average(\@matrix, \@matrix_avr, $param->{summary});
		$dst_file = $DST_FILE . $dst . "avr";

		if($param->{graph} =~ /RLAVR/){
			#dp::dp "Roling\n";
			$dst_file .= "rl";
			$title .= " (rlavr-$AVR_DATE)";

			csvlib::matrix_roling_average(\@matrix_avr, \@matrix_rl_avr, $AVR_DATE) ;
			csvlib::maratix_sort_max(\@matrix_rl_avr, \@matrix_sorted);
			$matrixp = \@matrix_sorted;
		}
		
		$p = {
			datap => $matrixp,
			dst_file => $dst_file,
			title => $title,
			target_range => $param->{target_range},
			start_date => $start_date,
			end_date => $end_date,
		};
		#dp::dp "#### ($start_date, $end_date)\n";
		&graph($p);
	}
	dp::dp $dst_file . "\n" if($VERBOSE);
	return ($dst_file);
}


sub	graph
{
	my ($p) = @_;

	my $datap = $p->{datap};
	my $col = @{$p->{datap}[0]};
	my $row = @{$p->{datap}};

	my $title = $p->{title} . "($LAST_DATE)";
	my @target_range = (0, 99999);
	@target_range = (@{$p->{target_range}}) if(defined $p->{target_range});
	#dp::dp "#### " . join(",", "[" . $p->{target_range}[0] . "]", @target_range) . "\n";

	my $dst_file = $p->{dst_file};
	my $csvf = $dst_file .  "-plot.csv.txt";
	my $pngf = $dst_file .  ".png";
	my $plotf = $dst_file . "-plot.txt";

	my $dlm = $DST_DLM;
	my $ylabel = "%";

	my $start_date = $p->{start_date} // "NONE";
	my $end_date = $p->{end_date} // "NONE";

	#dp::dp "#### $start_date -> $end_date\n";
	if(! ($start_date =~ /\//)){
		if($start_date < 0){
			my $sn = $#LABEL + $start_date;
			$sn = 3 if($sn < 3);
			$start_date = $LABEL[$sn];
			#dp::dp "---- $start_date : $sn\n";
		}
	}		

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
	#	Generate CSV Data
	#
	#dp::dp "row:$row col:$col\n";
	open(CSV, "> $csvf") || die "Cannot create $csvf";
	binmode(CSV, ":utf8");
	for(my $r = 0; $r < $row; $r++){
		#dp::dp    join($DST_DLM, @{$datap->[$r]}) . "\n";
		print CSV join($DST_DLM, @{$datap->[$r]}) . "\n";
	}
	close(CSV);

	#
	#	Draw Graph
	#
	my $PARAMS = << "_EOD_";
set datafile separator '$dlm'
set xtics rotate by -90
set xdata time
set timefmt '%Y/%m/%d'
set format x '%m/%d'
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
set terminal pngcairo size $TERM_X_SIZE, $TERM_Y_SIZE font "IPAexゴシック,8" enhanced
set output '$pngf'
plot #PLOT_PARAM#
exit
_EOD_

	my @p= ();
	my $pn = 0;
	for(my $i = 1; $i < $col; $i++){
		next if($i < $target_range[0] || $i > $target_range[1]);
		#dp::dp join(",", $i, @target_range) . "\n";

		$pn++;
		push(@p, sprintf("'%s' using 1:%d with lines title '$i:%s' linewidth %d ", 
						$csvf, $i + 1, $datap->[0][$i], ($pn < 7) ? 2 : 1)
		);
	}
	push(@p, "0 with lines dt '-' title 'base line'");
	my $plot = join(",", @p);
	$PARAMS =~ s/#PLOT_PARAM#/$plot/;

	open(PLOT, ">$plotf") || die "cannto create $plotf";
	binmode(PLOT, ":utf8");
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

