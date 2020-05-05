#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、感染率のグラフを作成する
#
#	beoutbreakprepared
#	https://github.com/beoutbreakprepared/nCoV2019
#
#
package csvrate;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(csvrate);

use strict;
#use warnings;
use csvgpl;
use csvlib;


#
#	初期化など
#
my $DEBUG = 0;
my $MIN_TOTAL = 100;
my $DLM = ",";

my $lp = 5;	# 5 潜伏期間
my $ip = 10;	# 8 感染期間

my $WIN_PATH = "/mnt/f/OneDrive/cov";
#my $file = "./COVID-19/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv";
#my $file = "./csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv";
my $BASE_DIR = "/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series";
my $file = "";
my $MODE = "";
my $DT_S = 4;
my $DATA = "";



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

