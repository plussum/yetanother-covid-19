#!/usr/bin/perl
#
#
#
#   SRC: https://mobaku.jp/covid-19/download/%E5%A2%97%E6%B8%9B%E7%8E%87%E4%B8%80%E8%A6%A7.csv
#
#
use strict;
use warnings;
use utf8;
use Encode 'decode';
use config;
use csvlib;

#use open IN => ":utf8";

my $SRC_URL = "https://mobaku.jp/covid-19/download/%E5%A2%97%E6%B8%9B%E7%8E%87%E4%B8%80%E8%A6%A7.csv";
my $CSVF =  "$config::WIN_PATH/docomo/docomo.csv.txt";
my $wget = "wget $SRC_URL -O $CSVF";
dp::dp $wget ."\n";
system($wget);

open(FD, $CSVF) || die "Cannot open $CSVF";
my $ln = 0;
<FD>;
chop;
$_ = decode('Shift_JIS', $_);
my @LAVEL = split(/,/, $_);

while(<FD>){
	chop;
	$_ = decode('Shift_JIS', $_);
	my ($area, $mesh, $zouka, @data) = split(/,/, $_);
	$DOCOMO{$area}{$mesh}{$kind} = [@data];
	dp::dp join(",", "前年同月比", @w) . "\n";
}

close(FD);

sub	gen_graph
{

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
