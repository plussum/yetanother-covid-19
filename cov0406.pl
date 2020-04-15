#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、CSVとグラフを生成する
#
#	beoutbreakprepared
#	https://github.com/beoutbreakprepared/nCoV2019
#
#
use strict;
#use warnings;
use GD::Graph::lines;
use GD::Graph::bars;


#
#	初期化など
#
my $DEBUG = 0;
my $MIN_TOTAL = 100;
my $DLM = ",";

my $WIN_PATH = "/mnt/f/OneDrive/cov";
#my $file = "./COVID-19/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv";
#my $file = "./csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv";
my $file = "";
my $MODE = "";

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$MODE = "ND" if(/-ND/);
	$MODE = "NC" if(/-NC/);
	if(/-copy/){
		system("cp ./csse_covid_19_data/csse_covid_19_time_series/*.csv $WIN_PATH");
		exit(0);
	}
}
if($MODE eq "NC"){
	$file = "./csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv";
}
elsif($MODE eq "ND"){
	$file = "./csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv";
}
else {
	system("$0 -NC");
	system("$0 -ND");
	exit(0);
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
	#last if($DATA[1][$DT_E] > 0);	# 最終カラムが日付だけのことがあるため
	last if(defined $DATA[1][$DT_E]);	# 最終カラムが日付だけのことがあるため
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
#	日次csvの作成
#
my $CSVF = "$WIN_PATH/cov_daily_$MODE" .  &ut2d(time, "") . ".csv";
for(my $i = 0; $i < 100; $i++){
	print $CSVF . "\n";
	last if(open(CSV, "> $CSVF"));

	$CSVF = "$WIN_PATH/cov_daily_$MODE" .  &ut2d(time, "") . "-$i.csv";
}

print join($DLM, "Country", "Total", @COL), "\n" if(1 || $DEBUG);
print CSV join($DLM, "Country", "Total", @COL), "\n" ;
my $ln = 0;
foreach my $country (sort {$COUNTRY{$b} <=> $COUNTRY{$a}} keys %COUNTRY){
	print join($DLM, $country, $COUNTRY{$country}), "\n" if($DEBUG);
#	next if($country eq "Others" || $country eq "Mainland China");
#	next if($COUNTRY{$country} < $MIN_TOTAL);
	print CSV $country. $DLM . $COUNTRY{$country}. $DLM;

	print join(", ", $country, $COUNTRY{$country}, @{$COUNT{$country}}[0..$#COL]), "\n"  if($ln < 3 || $DEBUG);
	for(my $dt = 0; $dt <= $#COL; $dt++){
		my $dtn = $COUNT{$country}[$dt] - ($dt == 0 ? 0 : $COUNT{$country}[$dt-1]);
		$COUNT_D{$country}[$dt] = $dtn;
	}
	print CSV join($DLM, @{$COUNT_D{$country}}), "\n";
	print join(", ", $country, $COUNTRY{$country}, @{$COUNT_D{$country}}[0..$#COL]), "\n" x 2  if($ln < 3 || $DEBUG);
	$ln++;
}
close(CSV);

#
#	グラフとHTMLの作成
#

my $TD = "($COL[$#COL]) src beoutbreakprepared";
$TD =~ s#/#.#g;
my $mode = ($MODE eq "NC") ? "NEW CASES" : "NEW DEATHS" ;

#my $EXCLUSION = "Others,China,USA";
my $EXCLUSION = "Others,US";
my @PARAMS = (
	{ext => "$mode ASIA 3w $TD", start_day => $DT_E - 21,  lank =>[0, 100] , exclusion => $EXCLUSION, 
		target => "Malaysia,Japan,Philippines,Singapore,Vietnam", label_skip => 2, graph => "lines"},
#	{ext => "$mode ASIA from Jan-22 $TD", start_day => 0,  lank =>[0, 100] , exclusion => $EXCLUSION, 
#		target => "Malaysia,Japan,Philippines,Singapore,Vietnam", label_skip => 2, graph => "lines"},
#	{ext => "$mode US-JP 3w $TD", start_day => $DT_E - 21,  lank =>[0, 100] , exclusion => $EXCLUSION, target => "US,Japan", label_skip => 2, graph => "lines", y_max_value => 2000},
#	{ext => "$mode US-JP 6w $TD", start_day => $DT_E - 42,  lank =>[0, 100] , exclusion => $EXCLUSION, target => "US,Japan", label_skip => 2, graph => "lines", y_max_value => 2000},
#	{ext => "$mode Singapore $TD", start_day => 0,  lank =>[0, 100] , exclusion => $EXCLUSION, target => "Singa", label_skip => 7, graph => "lines"},
#	{ext => "$mode china max-1000 $TD", start_day => 0,  lank =>[0, 100] , exclusion => $EXCLUSION, target => "China,Japan", label_skip => 7, graph => "lines", y_max_value => 400},
#	{ext => "$mode china from 301 $TD", start_day => 39, lank =>[0, 100] , exclusion => $EXCLUSION, target => "China,Japan", label_skip => 3, graph => "lines"},
#	{ext => "$mode china week $TD", start_day => $DT_E-7,  lank =>[0, 100] , exclusion => $EXCLUSION, target => "China,Japan", label_skip => 1, graph => "lines"},

	{ext => "$mode Focusing area from 0301 $TD",   start_day => 39, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Russia,Canada,Ecuador,Brazil,India", label_skip => 3, graph => "lines"},

#	{ext => "$mode all-211 $TD", start_day => 27, lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},

	{ext => "$mode all-211 ALL $TD", start_day => 0, lank =>[0, 19] , exclusion => "Others", target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode no China US -211 no China US $TD", start_day => 0, lank =>[0, 19] , exclusion => "Others,China,US", target => "", label_skip => 3, graph => "lines"},

#	{ext => "$mode all-211 $TD", start_day => 0, lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode TOP20-218 $TD", start_day => 27, lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},

	{ext => "$mode 01-10 from 0301 $TD",   start_day => 39, lank =>[0,  9] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 11-20 from 0301 $TD",   start_day => 39, lank =>[10, 19] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 21-30 from 0301 $TD",   start_day => 39, lank =>[20, 29] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 31-40 from 0301 $TD",   start_day => 39, lank =>[30, 39] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 41-50 from 0301 $TD",   start_day => 39, lank =>[40, 49] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},

	{ext => "$mode 2weeks 01-10 $TD", start_day => $DT_E-14, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", graph => "lines"},
	{ext => "$mode 2weeks 11-20 $TD", start_day => $DT_E-14, lank =>[10,19] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 2weeks 21-30 $TD", start_day => $DT_E-14, lank =>[20,29] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 2weeks 31-40 $TD", start_day => $DT_E-14, lank =>[30,39] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 2weeks 41-50 $TD", start_day => $DT_E-14, lank =>[40,49] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 2weeks 51-60 $TD", start_day => $DT_E-14, lank =>[50,59] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 2weeks 61-70 $TD", start_day => $DT_E-14, lank =>[60,69] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 2weeks 71-80 $TD", start_day => $DT_E-14, lank =>[70,79] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode Japan-122 $TD", start_day => 0, lank =>[0, 9999] , exclusion => $EXCLUSION, target => "Japan", graph => "bars"},
	{ext => "Japan-211 $TD", start_day => 20, lank =>[0, 9999] , exclusion => $EXCLUSION, target => "Japan", graph => "bars"},
);
my $COUNTRY_NUMBER = keys %COUNTRY;

my $HTMLF = "$WIN_PATH/cov_$MODE.html";
open(HTML, "> $HTMLF") || die "Cannot create file $HTMLF";

print HTML "<HTML>\n";
print HTML "<HEAD>\n";
print HTML "</HEAD>\n";
print HTML "<BODY>\n";



foreach my $p (@PARAMS){
	print "GRAPH PARAM: " . join(", ", $p->{ext}, $p->{start_day}, 
			$p->{lank}[0], $p->{lank}[1], $p->{exclusion}), "\n";


	my $IMG_PATH = "./cov_data/cov_$MODE" . $p->{ext} . ".png";
	my $PNGF = "$WIN_PATH/cov_data/cov_$MODE" . $p->{ext} . ".png";	
	my $std = defined($p->{start_day}) ? $p->{start_day} : 0;
	my $end = $#COL;
	my $tgcs = $p->{lank}[0];
	my $tgce = $p->{lank}[1];
	$tgce = $COUNTRY_NUMBER if($tgce > $COUNTRY_NUMBER);
	my @exclusion = split(/,/, $p->{exclusion});
	my @target = split(/,/, $p->{target});

	print HTML "<img src=\"$IMG_PATH\">\n";
	print HTML "<br><br>\n";

	print "TARGET: " , $p->{target}, "  " . $#target, "\n" if($DEBUG);
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
	my %CTG = ();
	foreach my $country (keys %COUNTRY){
		my $tl = 0;
		foreach my $c (@{$COUNT_D{$country}}[$std..$end]){
			$tl += $c;
		}
		$CTG{$country} = $tl;
	}

	foreach my $country (sort {$CTG{$b} <=> $CTG{$a}} keys %CTG){
		$CNT++;
		print $CNT + 1 . ": $country, " if($DEBUG);
		#next if($country eq "Others" || $country =~ /China/);

        next if($#exclusion >= 0 && &search_list($country, @exclusion));
        next if($#target >= 0 && $#exclusion >= 0 && ! &search_list($country, @target));

#		next if($COUNTRY{$country} < $MIN_TOTAL);
		next if($CNT < $tgcs || $CNT > $tgce);

		print "TARGET: $CNT, $country\n" if($DEBUG);
		push(@LEGEND_KEYS, sprintf("%02d:%s", $CNT+1, $country));
		foreach my $dtn (@{$COUNT_D{$country}}[$std..$end]){
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


	my $graph;
	my @color_scale = ();
	if($p->{graph} eq "bars"){ 
		$graph = GD::Graph::bars->new(1000, 400);
		@color_scale = qw(dblue green orange purple gray dbrown gold pink marine dyellow),
	}
	else {
		$graph = GD::Graph::lines->new(1000, 400);
		@color_scale = qw(orange green dblue purple gray dbrown gold pink marine dyellow),
	}

	$graph->set_title_font("/usr/share/fonts/ubuntu-font-family-0.83/Ubuntu-R.ttf", 16);
	$graph->set_legend_font("/usr/share/fonts/ubuntu-font-family-0.83/Ubuntu-R.ttf", 9);

	my $y_max_value = 0;
	my $max_digit = 0;
	if(defined $p->{y_max_value}) {
		$y_max_value =  $p->{y_max_value};
    	$max_digit = 10 ** int(log($y_max_value) / log(10));
	}
	else {
		$y_max_value = (int($MAX_COUNT /100) + 1) * 100;
    	$max_digit = 10 ** int(log($MAX_COUNT) / log(10));
    	$y_max_value = (int(($MAX_COUNT+$max_digit-1) /$max_digit)) * $max_digit;
	}
    my $mn = $y_max_value / $max_digit;
    print "####### $y_max_value, $max_digit $mn\n" if($DEBUG);

	my $y_tick_number = $mn;
	if($y_tick_number > 6) {
		$y_tick_number /= 2;
	}
	elsif($y_tick_number <= 3){
		$y_tick_number *= 2;
	}

	$graph->set(
		title => "COVID-19 " . $p->{ext},
		x_lable => "Date",
		y_lable => "Count",
		long_ticks     => 1,    
		x_ticks => 1,
		y_ticks => 1,
		y_tick_number => $y_tick_number,
		y_min_value => 0,
		y_max_value => $y_max_value,
		x_label_skip => $p->{label_skip},
		line_width => 3,
		line_types => [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4], 
	#	line_types => [1, 1, 1, 1, 1, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2], 
		dclrs => \@color_scale,
		boxclr => "white",
	#	dclrs => [ qw(orange green dblue purple gray dbrown gold pink marine dyellow) ],
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

	print HTML "<TABLE><TH>";
	foreach my $leg (@LEGEND_KEYS){
		print HTML "<TD>$leg</TD>";
	}
	print HTML "</TH></TABLE>\n";
	print HTML "<HR>\n";
}
print HTML "</BODY>\n";
print HTML "</HTML>\n";
close(HTML);

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
sub search_list
{
    my ($country, @w) = @_;

    foreach my $ntc (@w){
        if($country =~ /$ntc/){
            print "search_list: $country:$ntc\n";
            return 1;
        }
    }
    return "";
}
