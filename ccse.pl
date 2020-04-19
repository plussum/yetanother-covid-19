#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、CSVとグラフを生成する
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
my $POP = "";
my %NO_POP = ();

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$MODE = "ND" if(/-ND/);
	$MODE = "NC" if(/-NC/);
	$MODE = "FT" if(/-FT/);
	$MODE = "RT" if(/-RT/);
	$POP  = "-POP" if(/-POP/);
	
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
elsif($MODE eq "FT"){
	system("./ft.pl");
	exit(0);
}
elsif($MODE eq "RT"){
	system("./rate.pl");
}
else {
	system("$0 -NC ");
	system("$0 -ND ");
	system("$0 -NC -POP");
	system("$0 -ND -POP");
	system("$0 -FT ");
	system("$0 -RT ");
	exit(0);
}

my %CNT_POP = ();
if($POP){
	&cnt_pop();
	print "###### $POP\n";
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
print "country: " , join(", ", $cn),"\n" if($DEBUG);

#
#	日次csvの作成
#
#my $REPORT_CSVF = "$WIN_PATH/cov_daily_$MODE" .  &ut2d(time, "") . ".csv";
my $REPORT_CSVF = "$WIN_PATH/cov_daily_$MODE" . "$POP" . ".csv";
my $GRAPH_HTML = "$WIN_PATH/COVID-19_$MODE" . "$POP.html";
open(CSV, "> $REPORT_CSVF") || die "Cannot create $REPORT_CSVF\n";

print join($DLM, "Country", "Total", @COL), "\n" if($DEBUG);
print CSV join($DLM, "Country", "Total", @COL), "\n" ;
my $ln = 0;
foreach my $country (sort {$COUNTRY{$b} <=> $COUNTRY{$a}} keys %COUNTRY){
	print join($DLM, $country, $COUNTRY{$country}), "\n" if($DEBUG);
	next if($country =~ /Diamond Princess/ || $country =~ /MS Zaandam/);
#	next if($country eq "Others" || $country eq "Mainland China");
#	next if($COUNTRY{$country} < $MIN_TOTAL);
	next if(! $country || !$country =~ /^[A-Za-z]/);

	print CSV $country. $DLM . $COUNTRY{$country}. $DLM;

	print join(", ", $country, $COUNTRY{$country}, @{$COUNT{$country}}[0..$#COL]), "\n"  if($ln < 3 && $DEBUG > 1);
	for(my $dt = 0; $dt <= $#COL; $dt++){
		my $dtn = $COUNT{$country}[$dt] - ($dt == 0 ? 0 : $COUNT{$country}[$dt-1]);
		if($POP){
			if(defined $CNT_POP{$country}){
				#print "#### HIT POP: [$country], [$CNT_POP{$country}]\n";
				$dtn = $dtn / ($CNT_POP{$country} / (1000*1000));
			}
			else {
				$NO_POP{$country}++;
				#print "##### No population [$country]\n";
				$dtn = 999999;
			}
		}
		$COUNT_D{$country}[$dt] = $dtn;
	}
	print CSV join($DLM, @{$COUNT_D{$country}}), "\n";
	print join(", ", $country, $COUNTRY{$country}, @{$COUNT_D{$country}}[0..$#COL]), "\n" x 2  if($ln < 3 && $DEBUG > 1);
	$ln++;
}
close(CSV);

foreach my $c (sort %NO_POP){
	print "#### Nopoulatopn [$c], [$NO_POP{$c}]\n";
}

#
#	グラフとHTMLの作成
#

my $TD = "($COL[$#COL]) src Johns Hopkins CSSE";
$TD =~ s#/#.#g;
my $mode = ($MODE eq "NC") ? "NEW CASES" : "NEW DEATHS" ;
$mode .= $POP;

#my $EXCLUSION = "Others,China,USA";
my $EXCLUSION = "Others,US";
my @PARAMS = (
	{ext => "$mode US $TD", start_day => 39,  lank =>[0, 100] , exclusion => "Others", 
		target => "US", label_skip => 2, graph => "lines"},
	{ext => "$mode China Japan Korea4w $TD", start_day => 39,  lank =>[0, 100] , exclusion => $EXCLUSION, 
		target => "Japan,China,Korea", label_skip => 2, graph => "lines"},
	{ext => "$mode ASIA 3w $TD", start_day => $DT_E - 21,  lank =>[0, 100] , exclusion => $EXCLUSION, 
		target => "Malaysia,Japan,Philippines,Singapore,Vietnam,China,Taiwan", label_skip => 2, graph => "lines"},
	{ext => "$mode Taiwan 3w $TD", start_day => 38,  lank =>[0, 100] , exclusion => $EXCLUSION, 
		target => "Taiwan", label_skip => 2, graph => "lines"},
	{ext => "$mode Focusing area from 0301 $TD",   start_day => 39, lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => "Russia,Canada,Ecuador,Brazil,India", label_skip => 3, graph => "lines"},

	{ext => "$mode all-211 ALL $TD", start_day => 0, lank =>[0, 19] , exclusion => "Others", target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode all-211 ALL logscale $TD", start_day => 0, lank =>[0, 19] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", logscale => "y", average => 5},
	{ext => "$mode no China US -211 no China US $TD", start_day => 0, lank =>[0, 19] , exclusion => "Others,China,US", target => "", label_skip => 3, graph => "lines"},

#	{ext => "$mode all-211 $TD", start_day => 0, lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode TOP20-218 $TD", start_day => 27, lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},

	{ext => "$mode 01-10 from 0301 $TD",   start_day => 38, lank =>[0,  9] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 11-20 from 0301 $TD",   start_day => 38, lank =>[10, 19] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 21-30 from 0301 $TD",   start_day => 38, lank =>[20, 29] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 31-40 from 0301 $TD",   start_day => 38, lank =>[30, 39] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 41-50 from 0301 $TD",   start_day => 38, lank =>[40, 49] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines"},

	{ext => "$mode 3weeks 01-05 $TD", start_day => -21, lank =>[0, 4] , exclusion => $EXCLUSION, target => "", graph => "lines"},
	{ext => "$mode 3weeks 06-10 $TD", start_day => -21, lank =>[5, 9] , exclusion => $EXCLUSION, target => "", graph => "lines"},
	{ext => "$mode 3weeks 11-20 $TD", start_day => -21, lank =>[10,19] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 3weeks 21-30 $TD", start_day => -21, lank =>[20,29] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 3weeks 31-40 $TD", start_day => -21, lank =>[30,39] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 3weeks 41-50 $TD", start_day => -21, lank =>[40,49] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 3weeks 51-60 $TD", start_day => -21, lank =>[50,59] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 3weeks 61-70 $TD", start_day => -21, lank =>[60,69] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode 3weeks 71-80 $TD", start_day => -21, lank =>[70,79] , exclusion => $EXCLUSION, target => "", label_skip => 1, graph => "lines"},
	{ext => "$mode Japan-122 $TD", start_day => 0, lank =>[0, 9999] , exclusion => $EXCLUSION, target => "Japan", label_skip => 3, graph => "bars"},
	{ext => "$mode Japan 2weeks $TD", start_day => -21, lank =>[0, 9999] , exclusion => $EXCLUSION, target => "Japan", label_skip => 1, graph => "bars"},
);

my $EXC_POP = "San Marino,Holy See";
my @PARAMS_POP = (
	{ext => "$mode Japan-122 $TD", start_day => 0, lank =>[0, 9999] , exclusion => $EXC_POP, target => "Japan", label_skip => 3, graph => "bars"},
	{ext => "$mode Japan 2weeks $TD", start_day => -21, lank =>[0, 9999] , exclusion => $EXC_POP, target => "Japan", label_skip => 1, graph => "bars"},
	{ext => "$mode US $TD", start_day => 39,  lank =>[0, 100] , exclusion => "Others", target => "US", label_skip => 2, graph => "lines"},
	{ext => "$mode China $TD", start_day => 0,  lank =>[0, 100] , exclusion => "Others", target => "China", label_skip => 2, graph => "lines"},

	{ext => "$mode 01-05 -218 $TD($EXC_POP)", start_day => 27, lank =>[0, 4] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 06-10 -218 $TD($EXC_POP)", start_day => 27, lank =>[5, 9] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 11-15 -218 $TD($EXC_POP)", start_day => 27, lank =>[10, 14] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 16-20 -218 $TD($EXC_POP)", start_day => 27, lank =>[15, 19] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 01-05 from 0301 $TD($EXC_POP)", start_day => 38, lank =>[0,  4] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 06-10 from 0301 $TD($EXC_POP)", start_day => 38, lank =>[5,  9] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 10-15 from 0301 $TD($EXC_POP)", start_day => 38, lank =>[10, 14] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 16-20 from 0301 $TD($EXC_POP)", start_day => 38, lank =>[15, 19] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 3weeks 01-05 $TD($EXC_POP)", start_day => -21, lank =>[0, 4] , exclusion => $EXC_POP, target => "", graph => "lines"},
	{ext => "$mode 3weeks 06-10 $TD($EXC_POP)", start_day => -21, lank =>[5, 9] , exclusion => $EXC_POP, target => "", graph => "lines"},
	{ext => "$mode 3weeks 11-15 $TD($EXC_POP)", start_day => -21, lank =>[10,14] , exclusion => $EXC_POP, target => "", graph => "lines"},
	{ext => "$mode 3weeks 16-20 $TD($EXC_POP)", start_day => -21, lank =>[15,19] , exclusion => $EXC_POP, target => "", graph => "lines"},

	{ext => "$mode TOP20-218 $TD", start_day => 27, lank =>[0, 19] , exclusion => "", target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 01-10 from 0301 $TD",   start_day => 38, lank =>[0,  9] , exclusion => "", target => "", label_skip => 3, graph => "lines"},
	{ext => "$mode 3weeks 01-05 $TD", start_day => -21, lank =>[0, 4] , exclusion => "", target => "", graph => "lines"},

);
my $src_url = "https://github.com/beoutbreakprepared/nCoV2019";
my $src_ref = "<a href=\"$src_url\">$src_url</a>";   
my @csvlist = (
    { name => "COV19 CASES NEW", csvf => $REPORT_CSVF, htmlf => $GRAPH_HTML, kind => "NC", src_ref => $src_ref},
    { name => "COV19 DEATHS NEW", csvf => $REPORT_CSVF, htmlf => $GRAPH_HTML, kind => "ND", src_ref => $src_ref},
);

foreach my $clp (@csvlist){
   next if($clp->{kind} ne $MODE); 
	my $parap = ($POP) ? \@PARAMS_POP : \@PARAMS;
    my %params = (
        debug => $DEBUG,
        win_path => $WIN_PATH,
        clp => $clp,
        params => $parap,
		data_rel_path => "cov_data",
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

#
#	Country Population		(WHOは国が多すぎるのとPDFベースなので、不一致が多くあきらめた)
#
sub	cnt_pop
{
	my $popf = "COV/pop.csv";

	my %JHU_CN = ();
	my %WHO_CN = ();
	open(FD, $popf) || die "cannot open $popf\n";
	<FD>;
	while(<FD>){
		chop;
		
		my($jhu, $who, $un, $pn, @w) = split(",", $_);

		$JHU_CN{$jhu}++;
		$WHO_CN{$who}++;
		$CNT_POP{$un} = $pn;
		foreach my $sn (@w){
			$CNT_POP{$sn} = $pn;
		}
	}
	close(FD);

	foreach my $c (sort keys %JHU_CN){
		if(defined $CNT_POP{$c}){
			#print "$c\t" . $CNT_POP{$c}, "\n";
		}
		else {
			#print $c , "\n";
		}
	}
	foreach my $c (sort keys %WHO_CN){
		if(defined $CNT_POP{$c}){
			#print "$c\t" . $CNT_POP{$c}, "\n";
		}
		else {
			#print $c , "\n";
		}
	}
}
