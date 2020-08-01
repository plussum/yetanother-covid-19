#!/usr/bin/perl
#
#
#
use strict;
use warnings;
use config;

my $BASE_DIR = "/home/masataka/who/COVID-19";
my $LOOK_UP = "$BASE_DIR/csse_covid_19_data/UID_ISO_FIPS_LookUp_Table.csv";
my $CCSE_DEATH = "$BASE_DIR/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv";

my $popf = $config::POPF . ".txt";

#
#
#
# 01	北海道	Hokkaido	5320	2506	2814
my $JAPAN = "popjp.txt";
my %ALIAS = ();
my %AC = ();
open(FD, $JAPAN) || die "Cannot open $JAPAN";
while(<FD>){
	chop;
	my ($no, $jp, $en, $pop, $popm, $popf) = split(/\t/, $_);
	$en =~ s/-.*//;
	$ALIAS{$en} = $jp;
}
close(FD);


#  0   1    2    3     4    5     6               7                8       9             10
# UID,iso2,iso3,code3,FIPS,Admin2,Province_State,Country_Region,Lat,Long_,Combined_Key,Population
# 4,AF,AFG,4,,,,Afghanistan,33.93911,67.709953,Afghanistan,38928341
# 84006037,US,USA,840,06037,Los Angeles,California,US,34.30828379,-118.2282411,"Los Angeles, California, US",10039107
# 39241,JP,JPN,392,,,Tokyo,Japan,35.711343,139.446921,"Tokyo, Japan",13920663
my %POP = ();
my @NAMES = ();
my $an = 0;
open(FD, $LOOK_UP) || die "Cannot open $LOOK_UP";
<FD>;
while(<FD>){
	s/[\r\n]+$//;
	s/"([^",]+), *([^",]+), *([^",]+)"/$1;$2;$3/g;	# ,"aa,bb,cc", -> aa-bb-cc
	s/"([^",]+), *([^"]+)"/$1;$2/g;	# ,"aa,bb", -> aa-bb 
	s/""//g;
	my($UID,$iso2,$iso3,$code3,$FIPS,$Admin2,$Province_State,$Country_Region,$Lat,$Long_,$Combined_Key,$Population) = split(/,/, $_);
	if(!$Population || $Population =~ /[^0-9]/){
		#print "[$Population] $_\n";
		next;
	}
	#print $_ . "\n" if($Combined_Key eq "Japan");
	#$POP{$Admin2} = $Population;
	#$POP{$Country_Region} = $Population;
	#$POP{$Province_State} = $Population;
	$POP{$Combined_Key} = $Population;
	if($Combined_Key =~ /;US/){				# Califonia;US -> Califonia
		#print "$Combined_Key \n";
		my @ww = split(/;/, $Combined_Key);
		if($#ww < 2){
			my $state = $ww[0];
			$POP{$state} = $Population;
			print "$state \n";
		}
	}
	foreach my $st ($Admin2, $Province_State){
		next if(! defined $ALIAS{$st});
		my $aln = $ALIAS{$st};
		$POP{$aln} = $Population;
		$AC{$st}++;
		$an++;
		#print "$an:$st:$aln  $Population\n";
	}
}
close(FD);

foreach my $al (keys %ALIAS){
	next if(defined $AC{$al});
	print "#### $al\n";
}
my $cnt = 0;
open(CSV, "> $popf") || die "cannot create $popf";
print CSV join(",", "name", "Population") . "\n";
foreach my $name (keys %POP){
	print CSV join(",", $name, $POP{$name}) . "\n";
	print join(",", $name, $POP{$name}) . "\n" if($name eq "Japan" );
	$cnt++;
}
close(CSV);

print "$cnt names are listed\n";

