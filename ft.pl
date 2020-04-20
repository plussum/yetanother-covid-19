#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、感染率のグラフを作成する
#
#	beoutbreakprepared
#	https://github.com/beoutbreakprepared/nCoV2019
#
#
use strict;
#use warnings;
use lib qw(../gsfh);
use csvgpl;


#
#	初期化など
#
my $DEBUG = 0;
my $MIN_TOTAL = 100;
my $DLM = ",";

my $WIN_PATH = "/mnt/f/OneDrive/cov";
#my $file = "./COVID-19/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv";
#my $file = "./csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv";
my $BASE_DIR = "/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series";
my $file = "";
my $MODE = "";

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$MODE = "ND" if(/-ND/);
	$MODE = "NC" if(/-NC/);
	if(/-copy/){
		system("cp $BASE_DIR/*.csv $WIN_PATH");
		exit(0);
	}
}
if($MODE eq "NC"){
	$file = "$BASE_DIR/time_series_covid19_confirmed_global.csv";
}
elsif($MODE eq "ND"){
	$file = "$BASE_DIR/time_series_covid19_deaths_global.csv";
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
my %ABS = ();

for(; $DT_E > $DT_S; $DT_E--){
	#last if($DATA[1][$DT_E] > 0);	# 最終カラムが日付だけのことがあるため
	last if(defined $DATA[1][$DT_E]);	# 最終カラムが日付だけのことがあるため
}

for(my $rn = 0; $rn <= $RN; $rn++){
	my $country = $DATA[$rn][$CR];
	if($country eq "Japan" || $country =~ /Korea/){
		print "01: " , join(",", $country, @{$DATA[$rn]}), "\n";
	}
	for(my $dt = $DT_S; $dt <= $ITEMS; $dt++){
		$COUNT{$country}[$dt-$DT_S] += $DATA[$rn][$dt];		# 複数のレコードになっている国があるので += 
	}
	$COUNTRY{$country} += $DATA[$rn][$DT_E];
}
print "02: ", join(",", "Japan", @{$COUNT{Japan}}), "\n";
print "02: ", join(",", "Koria", @{$COUNT{"Korea- South"}}), "\n";

my $cn =  keys %COUNTRY;
print "country: " , join(", ", $cn),"\n" if($DEBUG);

#
#	日次csvの作成
#
#my $REPORT_CSVF = "$WIN_PATH/cov_daily_$MODE" .  &ut2d(time, "") . ".csv";
my $FT_CSVF = "$WIN_PATH/cov_ft_$MODE" . ".csv";
my $ABS_CSVF = "$WIN_PATH/cov_ftabs_$MODE" . ".csv";
my $GRAPH_HTML = "$WIN_PATH/COVID-19_ft_$MODE.html";
my %DIFF = ();
my %FIRST = ();
my $MIN_FIRST = $#COL;
my $AVR_DAY = 7;
my $THRESH_DAY = ($MODE eq "NC") ? 9 : 1;	# 10 : 1
my $THRESH_TOTAL = ($MODE eq "NC") ? 100 : 10;	# 10 : 1
open(ABS, "> $ABS_CSVF") || die "Cannot create $ABS_CSVF\n";

print join($DLM, "Country", "Total", @COL), "\n" if($DEBUG);
print ABS join($DLM, "Country", "Total", @COL), "\n" ;
my $ln = 0;
foreach my $country (sort {$COUNTRY{$b} <=> $COUNTRY{$a}} keys %COUNTRY){
    print join($DLM, $country, $COUNTRY{$country}), "\n" if($DEBUG);
    print ABS $country. $DLM . $COUNTRY{$country}. $DLM;

    print join(", ", $country, $COUNTRY{$country}, @{$COUNT{$country}}[0..$#COL]), "\n"  if($ln < 3 && $DEBUG > 1);
    for(my $dt = 0; $dt <= $#COL; $dt++){
        $DIFF{$country}[$dt] = $COUNT{$country}[$dt] - ($dt > 0 ? &valdef($COUNT{$country}[$dt-1], 0) : 0);
    }
	my $total = 0;
    for(my $dt = 0; $dt <= $#COL; $dt++){
        my $dtn = $DIFF{$country}[$dt];
		$total += $dtn;
        for(my $i = $dt - $AVR_DAY + 1; $i < $dt; $i++){
            $dtn += ($i >= 0 ? $DIFF{$country}[$i] : $DIFF{$country}[$dt]);
        }
        my $avr = int(0.999999 + $dtn / $AVR_DAY);
		if($avr >= $THRESH_DAY && !defined $FIRST{$country}){
		#if($total >= $THRESH_TOTAL && !defined $FIRST{$country}){
			$FIRST{$country} = $dt;
			$MIN_FIRST = $dt if($dt < $MIN_FIRST);
		}
		$ABS{$country}[$dt] = $avr;
		if(defined $FIRST{$country}){
			$ABS{$country}[$dt] = 0 if($avr < 1);
		}
    }
    print ABS join($DLM, @{$ABS{$country}}), "\n";
    print join(", ", $country, $COUNTRY{$country}, @{$ABS{$country}}[0..$#COL]), "\n" x 2  if($ln < 3 && $DEBUG > 1);
    $ln++;
}
close(ABS);

#
#
#
my $ITEM_COUNT = 0;
foreach my $country (sort {$COUNTRY{$b} <=> $COUNTRY{$a}} keys %COUNTRY){
	my $first = $FIRST{$country};
	my $ic = $#COL - $first;

	$ITEM_COUNT = $ic if($ic > $ITEM_COUNT);
}


my $end = $#COL - $MIN_FIRST;
open(FT, "> $FT_CSVF") || die "Cannot create $FT_CSVF\n";
print FT join($DLM, "Country", "Total");
for(my $i = 0; $i <= $ITEM_COUNT; $i++){
		print FT ",$i";
}
print FT "\n";
foreach my $country (sort {$COUNTRY{$b} <=> $COUNTRY{$a}} keys %COUNTRY){
	my $first = $FIRST{$country};
	if($country =~ /Japan/){
		print "first: $country: $first,$end,$#COL,$MIN_FIRST  " ;
		print join($DLM, @{$ABS{$country}}[$first..$end]), "\n";
		print join($DLM, @{$ABS{$country}}), "\n";
	}
	#print FT $country. $DLM . $COUNTRY{$country}. $DLM;
	print FT $country. $DLM . ($#COL - $first) . $DLM;
	print FT join($DLM, @{$ABS{$country}}[$first..$#COL]), "\n";
}
close(FT);

#
#	グラフとHTMLの作成
#

my $TD = "($COL[$#COL]) src Johns Hopkins CSSE";
$TD =~ s#/#.#g;
my $mode = ($MODE eq "NC") ? "RATE NEW CASES" : "RATE NEW DEATHS" ;

#my $EXCLUSION = "Others,China,USA";
my $EXCLUSION = "Others";

my $scc = 'linecolor "#808080"';
my $ymin = '10';
my $guide = "";
for(my $d = 2; $d <= 10; $d++){
	my $base = 2**(1/$d);
	my $p10 = 0;
	my $b10 = 0;
	for($p10 = 6; $p10 < 100; $p10 += 1){
		$b10 = $base**$p10;
		last if($b10 >= 10);
	}
	for(; $p10 > 0; $p10 -= 0.001 ){
		$b10 = $base**$p10;

		last if($b10 <= 10);
	}
	#printf("[%d:%.3f:%3f]\n", $d, $p10, $b10);

	$guide .= sprintf("(%.6f**(x+%.3f)) with lines title '%dday' $scc," , $base, $p10, $d);
#	printf(">>> $d (%.6f**(x+%.3f)) with lines title '%dday' $scc,\n" , $base, $p10, $d);
}
$guide =~ s/,$//;
#print "[$guide]\n";
#exit 0;

#$guide =  "(1.148698**(x+16)) with lines title '5day' $scc,  1.122462**(x+20) with lines title '6day' $scc,  1.10409**(x+23.5) with lines title '7day' $scc, 1.090508**(x+27) with lines title '8day' $scc";

my @PARAMS = (
	{ext => "$mode Japn Koria FT $TD", start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => "Japan,Korea- South", label_skip => 2, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600, ft => 1, ymin => $ymin, additional_plot => $guide},
	{ext => "$mode Japan and others FT $TD", start_day => 0, lank =>[0, 999] , exclusion => $EXCLUSION, 
			target => "Japan,Korea- South,US,Spain,Italy,France,Germany,United Kingdom,Iran,Turkey,Belgium,Switzeland",
		 	label_skip => 2, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600, ft => 1,  ymin => $ymin, additional_plot => $guide},
	{ext => "$mode TOP10 $TD", start_day => 0, lank =>[0, 10] , exclusion => $EXCLUSION, target => "", 
		label_skip => 7, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600, ft => 1, ymin => $ymin, additional_plot => $guide},
	{ext => "$mode 10-20 $TD", start_day => 0, lank =>[10, 19] , exclusion => $EXCLUSION, 
		target => "", label_skip => 7, graph => "lines", series => 1, average => 7, logscale => "y", term_ysize => 600, ft => 1, ymin => $ymin, additional_plot => $guide},
#	{ext => "$mode Japan Koria 0301 log $TD",   start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "R0,Japan,Korea- South", label_skip => 2, graph => "lines", logscale => "y"},
#	{ext => "$mode Focusing area from 0301 $TD",   start_day => 39, lank =>[0, 99] , exclusion => $EXCLUSION, 
#		target => "R0,Russia,Canada,Ecuador,Brazil,India", label_skip => 3, graph => "lines", ymax => 10},
#	{ext => "$mode TOP 10 from 0301 $TD",   start_day => 39, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", ymax => 10},
#	{ext => "$mode TOP 10 3w $TD",   start_day => -7, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines", ymax => 10},

);
my @csvlist = (
    { name => "NEW CASE", csvf => $FT_CSVF, htmlf => $GRAPH_HTML, kind => "NC"},
#    { name => "NEW DETH", csvf => $FT_CSVF, htmlf => $GRAPH_HTML, kind => "ND"},
);

foreach my $clp (@csvlist){
    my %params = (
        debug => $DEBUG,
        win_path => $WIN_PATH,
		data_rel_path => "cov_data",
        clp => $clp,
        params => \@PARAMS,
    );
    csvgpl::csvgpl(\%params);
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

sub valdef
{
    my ($v, $d) = @_;

    $d = 0 if(! defined $d);                                                                                                                     
    return (defined $v) ? $v : $d; 
}
