#!/usr/bin/perl
#
#
#
use strict;
#use warnings;
use GD::Graph::lines;

my $DEBUG = 0;

my $file = "./csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv";

for(my $i; $i < $#ARGV; $i++){
	$DEBUG = 1 if(/^-debug/);
}

#
#	Open File
#
open(FD, $file) || die "Cannot open $file\n";
$_ = <FD>;
chop;
my @COL = ();
chop;
for(split(/,/, $_)){
	s#/[0-9]+$##;

	push(@COL, $_);
}

my $ITEMS = $#COL;
my $DT_S = 4;
for(my $i = 0; $i < $DT_S; $i++){
	shift(@COL);
}
my $DT_E = $#COL;

#my @COL = split(/,/, $_);
#print $#COL , "\n";
my @DATA = ();
my $rn = 0;
while(<FD>){
	print if($DEBUG > 2);
	if(/"/){
		s/"([^",]+),([^"]+)"/$1-$2/;
	}
	my @LINE = split(/,/, $_);
	for(my $cn = 0; $cn <= $ITEMS; $cn++){
		$DATA[$rn][$cn] = $LINE[$cn];
	}
	$rn++;
}
close(FD);

my $RN = $rn;

my $CR = 1; # "Country/Region";
my %COUNTRY = ();
my %COUNT = ();
my %COUNT_D = ();

for(; $DT_E > $DT_S; $DT_E--){
	last if($DATA[1][$DT_E] > 0);	# 最終カラムが日付だけのことがあるため
}

for(my $rn = 0; $rn <= $RN; $rn++){
	my $country = $DATA[$rn][$CR];
	for(my $dt = $DT_S; $dt <= $ITEMS; $dt++){
		$COUNT{$country}[$dt-$DT_S] += $DATA[$rn][$dt];
	}
	$COUNTRY{$country} += $DATA[$rn][$DT_E];
}

my $cn =  keys %COUNTRY;
print "country: " , join(", ", $cn),"\n";

#
#	Parameters
#

my $MIN_TOTAL = 100;
my $DLM = ",";
#
#	Daily data
#
my $CSVF = "/mnt/f/temp/cov_daily" .  &ut2d(time, "") . ".csv";
for(my $i = 0; $i < 100; $i++){
	print $CSVF . "\n";
	last if(open(CSV, "> $CSVF"));

	$CSVF = "/mnt/f/temp/cov_daily" .  &ut2d(time, "") . "-$i.csv";
}

print join($DLM, "Country", "Total", @COL), "\n" if($DEBUG);
print CSV join($DLM, "Country", "Total", @COL), "\n" ;

foreach my $country (sort {$COUNTRY{$b} <=> $COUNTRY{$a}} keys %COUNTRY){
	print join($DLM, $country, $COUNTRY{$country}), "\n" if($DEBUG);
	next if($country eq "Others" || $country eq "Mainland China");
	next if($COUNTRY{$country} < $MIN_TOTAL);
	print CSV $country. $DLM . $COUNTRY{$country}. $DLM;

	print join(", ", $country, $COUNTRY{$country}), "\n"  if($DEBUG);
	for(my $dt = 0; $dt <= $#COL; $dt++){
		my $dtn = $COUNT{$country}[$dt] - ($dt == 0 ? 0 : $COUNT{$country}[$dt-1]);
		$COUNT_D{$country}[$dt] = $dtn;
	}
	print CSV join($DLM, @{$COUNT_D{$country}}), "\n";
}
close(CSV);

#
#
#
#$img->add_font_path("/usr/share/fonts/truetype/");
#$img->add_font_path("/usr/share/fonts/ubuntu-font-family-0.83/");
#$img->load_font("Ubuntu-R/12");


my @PARAMS = (
	{ext => "all-122", start_day => 0, target_country =>[0, 20] , no_target => "Others"},
	{ext => "all-211", start_day => 20, target_country =>[0, 20] , no_target => "Others"},
	{ext => "top10", start_day => 20, target_country =>[0, 9] , no_target => "Others,China"},
	{ext => "10_20", start_day => 40, target_country =>[10, 20] , no_target => "Others,China"},
);
my $COUNTRY_NUMBER = keys %COUNTRY;

foreach my $p (@PARAMS){
	print join(", ", $p->{ext}, $p->{start_day}, 
			$p->{target_country}[0], $p->{target_country}[1], $p->{no_target}), "\n";

	my $PNGF = "/mnt/f/temp/cov_" . $p->{ext} . ".png";	
	my $std = defined($p->{start_day}) ? $p->{start_day} : 0;
	my $end = $#COL;
	my $tgcs = $p->{target_country}[0];
	my $tgce = $p->{target_country}[1];
	$tgce = $COUNTRY_NUMBER if($tgce > $COUNTRY_NUMBER);
	my @no_target = split(/,/, $p->{no_target});

	my @Label = ();
	foreach my $dt (@COL[$std..$end]){
		push(@Label, $dt);
	}

	print "Label: ", join(",", @Label) , "\n" if($DEBUG);
	my @Dataset = (\@Label);
	my $cn = 0;

	my @LEGEND_KEYS = ();
	my $MAX_COUNT = 0;
	my $CNT = -1;
	foreach my $country (sort {$COUNTRY{$b} <=> $COUNTRY{$a}} keys %COUNTRY){
		$CNT++;
		print "$CNT; $country \n" if($DEBUG);
		#next if($country eq "Others" || $country =~ /China/);
		my $f = 0;
		foreach my $ntc (@no_target){
			$f = 1 if($country =~ /$ntc/);
		}
		next if($f);
		print "Yes, Target $CNT $tgcs $tgce\n" if($DEBUG);

#		next if($COUNTRY{$country} < $MIN_TOTAL);
		next if($CNT < $tgcs || $CNT > $tgce);

		print "TARGET: $CNT, $country\n" if($DEBUG);
		push(@LEGEND_KEYS, $country);
		foreach my $dtn (@{$COUNT_D{$country}}){
			$MAX_COUNT = $dtn if($dtn > $MAX_COUNT);
		}
		print join("; ", $country, $std, $end, @{$COUNT_D{$country}}[$std..$end]), "\n" if($DEBUG);
		push(@Dataset, [@{$COUNT_D{$country}}[$std..$end]]);
	}

	if($DEBUG){
		print $#Dataset, "\n";
		print join(",", "date", @{$Dataset[0]}), "\n";
		for (my $i = 1; $i < $#Dataset; $i++){
			print "Dataset[$i]:" . $Dataset[$i], "  ";
			#print join(",", $LEGEND_KEYS[$i-1], @{$clp}), "\n";
			print join(",", "$i", $LEGEND_KEYS[$i-1], @{$Dataset[$i]}), "\n";
		}
	}


	my $graph = GD::Graph::lines->new(1000, 600);
	my $y_max_value = (int($MAX_COUNT /100) + 1) * 100;
	$graph->set(
		title => "COVID-19 " . $p->{ext},
		x_lable => "Date",
		y_lable => "Count",
		long_ticks     => 1,    
		x_ticks => 1,
		y_ticks => 1,
		y_min_value => 0,
		y_max_value => $y_max_value,
		x_label_skip => 7,
		line_width => 3,
	#	x_tick_number  => 10,  
	#	y_tick_number  => 7, 
	#	values_vertical => 1,
	#	y_number_format => \&y_format
	);
	$graph->set_legend(@LEGEND_KEYS);

	my $image = $graph->plot(\@Dataset);
	my $pngData = $image->png();
	open(IMG, ">$PNGF") || die "Caanot create $PNGF";
	binmode IMG;
	print IMG $pngData;
	close(IMG);
}

#
#
#
sub	y_format
{
	my $value = shift;
	return $value;
}
#
#
#
#


sub ut2t
{
	my ($tm, $dlm) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%02d%s%02d%s%02d", $hour, $dlm, $min, $dlm, $sec);
	return $s;
}
sub ut2d
{
	my ($tm, $dlm) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%02d%s%02d%s%02d", $year % 100, $dlm, $mon+1, $dlm, $mday);
	return $s;
}
