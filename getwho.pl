#!/usr/bin/perl
#
#	WHO のデータ(pdf)をWHOからダウンロードして、CSVを生成する
#
use strict;
use warnings;

use lib qw(../gsfh);
use csvgpl;
use params;

my $DOWNLOAD = 0;
my $DEBUG = 0;
my $MODE = ""; # ND or NC;

my $WIN_PATH = "/mnt/f/OneDrive/cov";
my $WHO_PAGE = "https://www.who.int/emergencies/diseases/novel-coronavirus-2019/situation-reports/";
my $REPORT_MAIN = "$WIN_PATH/who_report_main.html";
my $BASE_URL = "https://www.who.int";
my $DL_DIR = "./data";

my $START_DATE = 20200301;	# 20200220以前はフォーマットが違う
my $END_DATE   = 99999999;		

my @HTML_LIST = ();
my @DLF_LIST = ();

my %TOTAL_CASE = ();
my %NEW_CASE = ();
my %TOTAL_DETH = ();
my %NEW_DETH = ();
my %DATES = ();
my %COUNTRY = ();
my $date = "";
my %POP = ();
my $PP = "";

my $dl = "";
for(my $i = 0;  $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$MODE = "ND" if(/-ND/);
	$MODE = "NC" if(/-NC/);
	$MODE = "DR" if(/-DR/);
	$PP   = $_ if(/-PP/);
	$dl = "-dl" if(/-dl/);
}
if($MODE eq "") {
	system("$0 -ND $PP $dl");
	system("$0 -NC $PP $dl");
	#	system("$0 -DR");
	exit;
}
$DOWNLOAD = 1 if($dl);

print ">> DOWNLOAD: $DOWNLOAD\n";

my $REPORT_CSVF = "$WIN_PATH/who_situation_report_$MODE.csv.txt";
my $GRAPH_HTML = "$WIN_PATH/who_situation_report_$MODE.html";

my $LAST_DATE = 0;

#
#
#
#&get_population();
&get_situation_list();


for(my $i = 0; $i <= $#HTML_LIST; $i++){
	my $html = "$BASE_URL/" . $HTML_LIST[$i];
	my $dlf  = "$DL_DIR/" . $DLF_LIST[$i];
	my $txtf = $dlf;
	$date = $DLF_LIST[$i];
	$date =~ s/-.*$//;
	$DATES{$date}++;
	$LAST_DATE = $date if($date > $LAST_DATE);

	$txtf =~ s/\.pdf/.txt/;
	my $txtd = $txtf;
	$txtd =~ s/.txt/-d.txt/;
	print $txtf , "\n" if($DEBUG > 2);

	print "DL: $html\n" if($DEBUG > 2);
	system("wget $html -O $dlf")    if(! -f $dlf);
	system("ps2ascii $dlf > $txtf") if(! -f $txtf);
	&molding($txtf, $txtd, $date)   if(! -f $txtd);

	open(TXT, $txtd) || die "Cannot open $txtd";
	while(<TXT>){
		chop;
		my @w = ();
		my $region;
		my $country;
		($region, $country, @w)  = split(/,/, $_);
		next if($country =~ /regions International/i);
		next if($country =~ /regions/);
		$country = "Iran" if($country =~ /Iran/);
		$country = "USA"  if($country =~ /United States of America/);
		$country = "UK"  if($country =~ /The United Kingdom/);
		$country =~ s/ *transmission *//;
		print "### COUNTRY($date):" . join(",", $region, $country, @w) . " \n" if($country =~ /^[0-9]+$/);

		my $k = join("\t", $date, $country);

		my $c;
		if($MODE eq "NC" || $MODE eq "ND"){
			$c = &valdef($w[1]) if($MODE eq "NC");
			$c = &valdef($w[3]) if($MODE eq "ND");
			if($c =~ /transmission/ || $c =~ /[67][5289] /){
				dp::dp "find trasnmission [$c][$txtd] $_\n";
			}
			$COUNTRY{$country} += $c;	# 累計
		}
		elsif($MODE eq "DR"){
			$c = 0;
			$c = sprintf("%.2f", 100 * &valdef($w[2]) / &valdef($w[0])) if(&valdef($w[0]) > 0);
			$COUNTRY{$country} = $c;	# 累計
		}

		$TOTAL_CASE{$k} = &valdef($w[0]);	# Total case
		$NEW_CASE{$k}   = &valdef($w[1]);	# new case
		$TOTAL_DETH{$k} = &valdef($w[2]);	# Total deth
		$NEW_DETH{$k}   = &valdef($w[3]);	# new death 
	}
	close(TXT);
}
printf "#### LAST_DATE : $LAST_DATE\n";
	
#print "#### " . $COUNTRY{Plurinational} , "###\n";
#print join("\n", keys %COUNTRY);
#for(keys %COUNTRY){
#	print $_ . "\n" if(/International/);
#}

#
#	CSV の作成
#
my %NODATA = ();
my @COL = ();
my %COUNT_D = ();

unlink($REPORT_CSVF) || print STDERR "cannot remove $REPORT_CSVF\n";
open(CSV, ">$REPORT_CSVF") || die "cannot create $REPORT_CSVF\n";

foreach my $dt (sort keys %DATES){
	#push(@COL, join("/", substr($dt, 0, 4), substr($dt, 4, 2), substr($dt, 6, 2)));
	push(@COL, join("/", substr($dt, 4, 2), substr($dt, 6, 2)));
}
print CSV join(",", "", "total", @COL), "\n";

#print CSV join(",", "", "total", sort keys %DATES), "\n";
foreach my $country (sort {$COUNTRY{$b} <=> $COUNTRY{$a}} keys %COUNTRY){
	next if($country =~ /total/);

	print CSV $country . "," . $COUNTRY{$country} . "," ;
	my $i = 0;
	foreach my $dt (sort keys %DATES){
		my $k = join("\t", $dt, $country);
		my $c;
		$c = &valdef($NEW_CASE{$k}) if($MODE eq "NC");
		$c = &valdef($NEW_DETH{$k}) if($MODE eq "ND");
		if($PP){
			if(defined $POP{$country}){
				$c /= $POP{$country};
			}
			else {
				#print "No population data for [$country]\n" if(! defined $NODATA{$country});
				print "$country\n" if(! defined $NODATA{$country});
				$NODATA{$country}++;
			}
		}
		
		if($MODE eq "DR"){
			$c = 0;
			$c = int(10000 * &valdef($TOTAL_DETH{$k}) / &valdef($TOTAL_CASE{$k})/100) if(&valdef($TOTAL_CASE{$k}) > 0);
		
			print join("," , $dt, $country, &valdef($TOTAL_DETH{$k}), &valdef($TOTAL_CASE{$k}), $c) , "\n" if($DEBUG);
		}
		print CSV $c , ",";
		$COUNT_D{$country}[$i] = $c;
		$i++;
	}
	print CSV "\n";
}
close(CSV);

#
#	Create graph and HTMl by command
#
#
#my $cmd = "./csv2graph.pl";
#my $cmd = "./csvgpl.pl";
#$cmd .= " -PP" if($PP);
#print $cmd , "\n";
#system($cmd );

#
#	Create graph and HTML by Lib
#
my $src = "src WHO situation report";

my $LOCAL_EXC = "Others,China,USA";
my @LOCAL_PARAMS = (
    {ext => "#KIND# Japan 0301 (#LD#) $src", start_day => "03/01", lank =>[0, 9999] , exclusion => $LOCAL_EXC, target => "Japan", label_skip => 2, graph => "lines"},
);

my @PARAMS = (params::common() , @LOCAL_PARAMS);


my $src_url = "https://www.who.int/emergencies/diseases/novel-coronavirus-2019/situation-reports";
my $src_ref = "WHO SITUATION REPORT: <a href=\"$src_url\"> $src_url</a>";
my @csvlist = (
    { name => "WHO CASES NEW",  src => "src WHO situation report", csvf => $REPORT_CSVF, htmlf => $GRAPH_HTML, kind => "NC", src_ref => $src_ref, srcf => $REPORT_CSVF},
    { name => "WHO DEATHS NEW", src => "src WHO situation report", csvf => $REPORT_CSVF, htmlf => $GRAPH_HTML, kind => "ND", src_ref => $src_ref, srcf => $REPORT_CSVF},
);

foreach my $clp (@csvlist){
	next if($clp->{kind} ne $MODE);
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
sub	get_situation_list
{
	system("wget $WHO_PAGE -O $REPORT_MAIN") if($DOWNLOAD);	# WHO situation reports main page

	#
	#
	#
	open(HTML, $REPORT_MAIN) || die "cannot open $REPORT_MAIN";
	while(<HTML>){
		while(s/"[^"]+\.pdf\?[^"]+"//){
			my $pdf = $&;

			$pdf =~ s/"([^"]+)"/$1/;

			my $dlf = $pdf;
			$dlf =~s#.+/(.+pdf)\?.*$#$1#;
			print length($_) . " " , $pdf . "\n", $dlf . "\n" if($DEBUG > 1);
		
			my $date = $dlf;
			$date =~ s/-.*$//;
			next if($date < $START_DATE || $date > $END_DATE);		# 2/20 以前はフォーマットが違うため

			push(@HTML_LIST, $pdf);
			push(@DLF_LIST, $dlf);	
		}
	}
}

sub	molding
{
	my ($txtf, $txtd, $date) = @_;

	my $REGION = "---";
	my @RECORD = ();
	my $LAST_W = -1;

	my $dataf = 0;
	my $ln = 0;
	my $post_c = "";

	print "##### $txtf\n";

	open(TXT, $txtf) || die "cannot open $txtf\n";
	while(<TXT>){
		s/ *[\r\n]+$//;
		if(/^ +Community$/){
			print "#" x 20 . "Community\n";
			next;
		}
		s/^ +//;
		if(/Region of the Americas/){
			print "-" x 20 , $_ , "\n";
			$post_c = "";
			$LAST_W = 0;
			next;
		}


		$dataf = 1 if(/^SURVEILLANCE/);
		$dataf = 2 if(/^Western Pacific Region/ && $dataf == 1);
		$dataf = 3 if(/^Grand total/);

		next if($dataf <= 1);
		if(/††/ || /[\*]{2}/ || /Territories/){
			$LAST_W = -1;
			next;
		}

		s/†//;
		s/\^+//;

		print "[$dataf]" . $_ , "\n" if($DEBUG);
		s/\(([0-9]+)\)/ $1 /g if($date <= 20200301);		# format
		my @w = split(/ {2,999}/, $_);

		if($#w > 1){
			if($post_c){
				$w[0] = $post_c . " " . $w[0];
				print "---> " . $w[0] , "\n" if($DEBUG);
				$post_c = "";
			}
			print "[DATA] $ln " . join(",", @w) , "\n" if($DEBUG);
			$RECORD[$ln][0] = $REGION;
			if($date >= 20200227){
				for(my $i = 0; $i <= 4; $i++){
					$RECORD[$ln][$i+1] = $w[$i];
				}
			}
			else {
				$RECORD[$ln][1] = $w[1];
				$RECORD[$ln][2] = $w[2];
				$RECORD[$ln][3] = $w[11];
				$RECORD[$ln][4] = $w[12];
			}
			$ln++;
		}
		elsif(/Region/){
			$REGION = $w[0];
			$post_c = "";
		}
		elsif(/Diamond Princess/){
			print ">> $ln " . $RECORD[$ln-1][0] ;
			print "($w[0])" , "\n";
			$RECORD[$ln-1][0] .= " " . $w[0];
			print "<< " . $RECORD[$ln-1][0] , "\n";
		}
		elsif(defined $w[0]){
			if($LAST_W > 1){
				$RECORD[$ln-1][1] .= " " . $w[0];
				print "#PRE:$LAST_W# $RECORD[$ln-1][1]\n" if($DEBUG);
			}
			else {
				$post_c .= $w[0];   #  $_ ;
				print "#POST:$LAST_W# $post_c\n" if($DEBUG);
			}
		}
		last if($dataf == 3);
		$LAST_W = $#w;
	}
	close(TXT);

	print $txtd , "\n" if($DEBUG > 2);
	open(TXD, ">$txtd") || die "cannot create $txtd";
	for(my $n = 0; $n < $ln; $n++){
		print "## $n $RECORD[$n]\n" if($DEBUG);
		my @w = @{$RECORD[$n]};
		print TXD join(",", @w[0..5]), "\n";
		print join(",", @w), "\n" if($DEBUG);

	}
	close(TXD);
}

sub	get_population
{
	my $PPL = "../population.txt";
	open(P, $PPL) || die "Cannot open $PPL\n";
	while(<P>){
		chop;
		next if(!$_);

		s/^[^A-Za-z]+//;
		s/\[.\]//;
		s/\([A-Za-z ]+\)//;
		my($c, $p) = split(/\t/, $_);
		$c =~ s/^ +//;
		$p =~ s/,//g;
		#print "[$c:$p]";
		$POP{$c} = $p / 1000000;	# 1M
	}
	print "\n";
	close(P);

}
#
#
#
sub	valdef
{
	my ($v, $d) = @_;
	
	$d = 0 if(! defined $d);

	return defined $v ? $v : $d;
}

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
