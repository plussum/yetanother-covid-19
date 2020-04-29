#!/usr/bin/perl
#
#	WHO のデータ(pdf)をWHOからダウンロードして、CSVを生成する
#
package who;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(who);

use strict;
use warnings;

use config;
use csvgpl;
use params;
use ft;
use rate;
use dp;

my $DEBUG = 1;
my $DLM = $config::DLM;
my $WIN_PATH = $config::WIN_PATH;
my $INFO_PATH = $config::INFO_PATH->{ccse};

my $WHO_PAGE = "https://www.who.int/emergencies/diseases/novel-coronavirus-2019/situation-reports/";
my $BASE_URL = "https://www.who.int";
my $DL_DIR = "$WIN_PATH/whodata";


#dp::dp "WIN_PATH: $WIN_PATH \n";

my $REPORT_MAIN = $WIN_PATH . "/who_report_main.html";

my $EXCLUSION = "Others,US";
my $EXC_POP = "San Marino,Holy See";
my $infopath = $config::INFOPATH->{who} ;

our $PARAMS = {			# MODULE PARETER        $mep
	comment => "**** WHO PARAMS ****",
	src => "Who situation report",
	src_url => "https://www.who.int/emergencies/diseases/novel-coronavirus-2019/situation-reports/",
	prefix => "who_",
	src_file => {
		NC => "$WIN_PATH/CSV/who_situation_report_NC.html",		# 表示用　実際にはプログラム中でファイルを生成している
		ND => "$WIN_PATH/CSV/who_situation_report_ND.html",		# jhccseの場合は、実際にCSVがあるので、このパラメータを読み込みに利用している
	},
	base_dir => "",
	DLM => ",",

	new => \&new,
	aggregate => \&aggregate,
	download => \&download,
	copy => \&copy,

	COUNT => {			# FUNCTION PARAMETER    $funcp
		EXEC => "US",
		graphp => [		# GPL PARAMETER         $gplp
			@params::PARAMS_COUNT, 
		],
	},
	FT => {
		EXC => "Others",  # "Others,China,USA";
		ymin => 10,
		average_date => 7,
		graphp => [
			@params::PARMS_FT
		],
	},
	RT => {
		EXC => "Others",
		ymin => 10,
		ip => 5,
		lp => 8,
		average_date => 7,
		graphp => [
			@params::PARMS_RT
		],
	}
};

#
#
#
sub	new 
{
	return $PARAMS;
}

sub	download
{
	my ($info_path) = @_;
	system("wget $WHO_PAGE -O $REPORT_MAIN");	
}
sub	copy
{
	my ($info_path) = @_;
}

#
#
#
my $START_DATE = 20200301;	# 20200220以前はフォーマットが違う
my $END_DATE   = 99999999;		
my $LAST_DATE = 0;

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

sub	aggregate
{
	my ($fp) = @_;

	my $mode = $fp->{mode};
	my $aggr_mode = $fp->{aggr_mode};
	my $src_file = $fp->{src_file};
	my $report_csvf = $fp->{stage1_csvf};
	my $graph_html = $fp->{htmlf};
	my @src_list = ();

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
		push(@src_list, "$txtf\t$txtd");

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
			if($mode eq "NC" || $mode eq "ND"){
				$c = csvlib::valdef($w[1], 0) if($mode eq "NC");
				$c = csvlib::valdef($w[3], 0) if($mode eq "ND");
				if($c =~ /transmission/ || $c =~ /[67][5289] /){
					dp::dp "find trasnmission [$c][$txtd] $_\n";
				}
				$COUNTRY{$country} += $c;	# 累計
			}
			elsif($mode eq "DR"){
				$c = 0;
				$c = sprintf("%.2f", 100 * csvlib::valdef($w[2], 0) / csvlib::valdef($w[0], 0)) if(csvlib::valdef($w[0], 0) > 0);
				$COUNTRY{$country} = $c;	# 累計
			}

			$TOTAL_CASE{$k} = csvlib::valdef($w[0], 0);	# Total case
			$NEW_CASE{$k}   = csvlib::valdef($w[1], 0);	# new case
			$TOTAL_DETH{$k} = csvlib::valdef($w[2], 0);	# Total deth
			$NEW_DETH{$k}   = csvlib::valdef($w[3], 0);	# new death 
		}
		close(TXT);
	}
	printf "#### LAST_DATE : $LAST_DATE\n";
		
	open(SRC, ">$src_file") || die "cannot create $src_file\n";
	print SRC "<HTML>\n";
	print SRC "<HEAD>\n";
	print SRC $config::CSS;
	print SRC "</HEAD>\n";
	print SRC "<BODY>\n";
	print SRC "<span class=\"c\">\n";
	foreach my $sl (sort {$b cmp $a} @src_list){
		#dp::dp  $sl . "\n";
		foreach my $f (split(/\t/, $sl)){
			$f =~ s#$WIN_PATH#..#;
			print SRC "<a href=\"$f\">$f</a>" . "&nbsp;" x 3;
			#dp::dp  "<a href=\"$f\">$f</a>\n";
		}
		print SRC "<br>\n";
	}
	print SRC "</span>\n";
	print SRC "</BODY>\n</HTML>\n";
	close(SRC);

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

	unlink($report_csvf) || print STDERR "cannot remove $report_csvf\n";
	open(CSV, ">$report_csvf") || die "cannot create $report_csvf\n";

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
			$c = csvlib::valdef($NEW_CASE{$k}, 0) if($mode eq "NC");
			$c = csvlib::valdef($NEW_DETH{$k}, 0) if($mode eq "ND");
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
			
			if($mode eq "DR"){
				$c = 0;
				$c = int(10000 * csvlib::valdef($TOTAL_DETH{$k}, 0) / csvlib::valdef($TOTAL_CASE{$k}, 0)/100) if(csvlib::valdef($TOTAL_CASE{$k}, 0) > 0);
			
				print join("," , $dt, $country, csvlib::valdef($TOTAL_DETH{$k}, 0), csvlib::valdef($TOTAL_CASE{$k}, 0), $c) , "\n" if($DEBUG);
			}
			print CSV $c , ",";
			$COUNT_D{$country}[$i] = $c;
			$i++;
		}
		print CSV "\n";
	}
	close(CSV);
}

#
#
#
sub	get_situation_list
{

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
1;
