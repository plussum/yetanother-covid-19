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

my $lp = 5;	# 5 潜伏期間
my $ip = 8;	# 8 感染期間

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
my %RATE = ();
my $DELAY = 12;

for(; $DT_E > $DT_S; $DT_E--){
	#last if($DATA[1][$DT_E] > 0);	# 最終カラムが日付だけのことがあるため
	last if(defined $DATA[1][$DT_E]);	# 最終カラムが日付だけのことがあるため
}

for(my $rn = 0; $rn <= $RN; $rn++){
	my $country = $DATA[$rn][$CR];
	if($country eq "Japan"){
		print "01: " , join(",", $country, @{$DATA[$rn]}), "\n";
	}
	for(my $dt = $DT_S; $dt <= $ITEMS; $dt++){
		$COUNT{$country}[$dt-$DT_S] += $DATA[$rn][$dt];		# 複数のレコードになっている国があるので += 
	}
	$COUNTRY{$country} += $DATA[$rn][$DT_E];
}
print "02: ", join(",", "Japan", @{$COUNT{Japan}}), "\n";

my $cn =  keys %COUNTRY;
print "country: " , join(", ", $cn),"\n" if($DEBUG);

#
#	日次csvの作成
#
#my $REPORT_CSVF = "$WIN_PATH/cov_daily_$MODE" .  &ut2d(time, "") . ".csv";
my $RATE_CSVF = "$WIN_PATH/cov_rate_$MODE" . ".csv";
my $ABS_CSVF = "$WIN_PATH/cov_abs_$MODE" . ".csv";
my $GRAPH_HTML = "$WIN_PATH/COVID-19_rate_$MODE.html";
my %DIFF = ();
my $AVR_DAY = 5;
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
	for(my $dt = 0; $dt <= $#COL; $dt++){
		my $dtn = $DIFF{$country}[$dt];
		for(my $i = $dt - $AVR_DAY + 1; $i < $dt; $i++){
			$dtn += ($i >= 0 ? $DIFF{$country}[$i] : $DIFF{$country}[$dt]);
		}
		my $avr = int(0.5 + $dtn / $AVR_DAY);
		$ABS{$country}[$dt] = $avr;
	}
	print ABS join($DLM, @{$ABS{$country}}), "\n";
	print join(", ", $country, $COUNTRY{$country}, @{$ABS{$country}}[0..$#COL]), "\n" x 2  if($ln < 3 && $DEBUG > 1);
	$ln++;
}
close(ABS);

#
#
#
open(RATE, "> $RATE_CSVF") || die "Cannot create $RATE_CSVF\n";
print RATE join($DLM, "Country", "Total", @COL[0..($#COL - $ip - $lp)]), "\n" ;
#print RATE join($DLM, "R0=1.0", " ");
#for(my $i = 0; $i <= $#COL - $ip - $lp; $i++){
#		print RATE ",1";
#}
#print RATE "\n";
foreach my $country (sort {$COUNTRY{$b} <=> $COUNTRY{$a}} keys %COUNTRY){
	print RATE $country. $DLM . $COUNTRY{$country}. $DLM;
	for(my $dt = 0; $dt <= ($#COL - $ip - $lp) ; $dt++){
		my $ppre = $ip * $ABS{$country}[$dt+$lp+$ip];
		my $pat = 0;
		for(my $dp = $dt + 1; $dp <= $dt + $ip; $dp++){
			$pat += $ABS{$country}[$dp], ;
		}
		# print "$country $dt: $ppre / $pat\n";
		if($pat > 0){
			$RATE{$country}[$dt] =  int(1000 * $ppre / $pat) / 1000;
		}
		else {
			$RATE{$country}[$dt] =  0;
		}
	}
	print RATE join($DLM, @{$RATE{$country}}), "\n";
}
close(RATE);

#
#	グラフとHTMLの作成
#

my $TD = "($COL[$#COL]) src Johns Hopkins CSSE";
$TD =~ s#/#.#g;
my $mode = ($MODE eq "NC") ? "RATE NEW CASES" : "RATE NEW DEATHS" ;

my $EXCLUSION = "Others";
my @PARAMS = (
	{ext => "$mode Japan 0301 $TD",   start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "R0,Japan", label_skip => 2, graph => "lines", additional_plot => "1 with lines title 'R0=0'"},
	{ext => "$mode Japan 3weeks $TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "R0,Japan", label_skip => 1, graph => "lines", additional_plot => "1 with lines title 'R0=0'"},
	{ext => "$mode Germany 0301 $TD",   start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "R0,Germany", label_skip => 2, graph => "lines", additional_plot => "1 with lines title 'R0=0'"},
	{ext => "$mode Germany 3weeks $TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "R0,Germany", label_skip => 1, graph => "lines", additional_plot => "1 with lines title 'R0=0'"},
	{ext => "$mode Forcus area 01 3weeks $TD",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "R0,Germany,US,Italy,Spain,France", label_skip => 1, graph => "lines", additional_plot => "1 with lines title 'R0=0'"},
#	{ext => "$mode Japan Koria 0301 log $TD",   start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "R0,Japan,Korea- South", label_skip => 2, graph => "lines", logscale => "y", additional_plot => "1 with lines title 'R0=0'"},
#	{ext => "$mode Japan Koria 0301 log $TD",   start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "R0,Japan,Korea- South", label_skip => 1, graph => "lines", logscale => "y", additional_plot => "1 with lines title 'R0=0'"},
	{ext => "$mode Focusing area from 0301 $TD",   start_day => 39, lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => "R0,Russia,Canada,Ecuador,Brazil,India", label_skip => 3, graph => "lines", ymax => 10, additional_plot => "1 with lines title 'R0=0'"},
	{ext => "$mode TOP 01-05 from 0301 $TD",   start_day => 39, lank =>[0, 4] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", ymax => 10, additional_plot => "1 with lines title 'R0=0'"},
	{ext => "$mode TOP 06-10 from 0301 $TD",   start_day => 39, lank =>[5, 9] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", ymax => 10, additional_plot => "1 with lines title 'R0=0'"},
	{ext => "$mode TOP 10 3w $TD",   start_day => -21, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines", ymax => "", additional_plot => "1 with lines title 'R0=0'"},
	{ext => "$mode TOP 10 2w $TD",   start_day => -14, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines", ymax => "", additional_plot => "1 with lines title 'R0=0'"},
	{ext => "$mode TOP 10 1w $TD",   start_day => -7, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines", ymax => "", additional_plot => "1 with lines title 'R0=0'"},

);
my $src_url = "https://github.com/beoutbreakprepared/nCoV2019";
my $src_ref = "<a href=\"$src_url\">$src_url</a>";
my @csvlist = (
    { name => "COV19 RATE NEW CASE", csvf => $RATE_CSVF, htmlf => $GRAPH_HTML, kind => "NC", src_ref => $src_ref },
#    { name => "NEW DETH", csvf => $RATE_CSVF, htmlf => $GRAPH_HTML, kind => "ND"},
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
