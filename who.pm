#!/usr/bin/perl
#
#	comment => "**** WHO PARAMS ****",
#	src => "Who situation report",
#	src_url => "https://www.who.int/emergencies/diseases/novel-coronavirus-2019/situation-reports/",
#	prefix => "who_",
#
#	Functions must define
#	new => \&new,
#	aggregate => \&aggregate,
#	download => \&download,
#	copy => \&copy,
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
use dp;

#
#	Initial
#

my $DEBUG = 0;
my $DLM = $config::DLM;
my $WIN_PATH = $config::WIN_PATH;
my $INFO_PATH = $config::INFO_PATH->{ccse};

#
#	Parameter set
#
my $WHO_PAGE = "https://www.who.int/emergencies/diseases/novel-coronavirus-2019/situation-reports/";
my $BASE_URL = "https://www.who.int";
my $DL_DIR = "$WIN_PATH/whodata";

my $REPORT_MAIN = $WIN_PATH . "/who_report_main.html";

our $PARAMS = {			# MODULE PARETER        $mep
	comment => "**** WHO PARAMS ****",
	src => "Who situation report",
	src_url => "https://www.who.int/emergencies/diseases/novel-coronavirus-2019/situation-reports/",
	prefix => "who_",
	src_file => {
		NC => "$WIN_PATH/CSV/who_situation_report_NC.html",		# 表示用　実際にはプログラム中でファイルを生成している
		ND => "$WIN_PATH/CSV/who_situation_report_ND.html",		# jhccseの場合は、実際にCSVがあるので、このパラメータを読み込みに利用している
		CC => "$WIN_PATH/CSV/who_situation_report_NC.html",		# 表示用　実際にはプログラム中でファイルを生成している
		CD => "$WIN_PATH/CSV/who_situation_report_ND.html",		# jhccseの場合は、実際にCSVがあるので、このパラメータを読み込みに利用している
	},
	base_dir => "",
	DLM => ",",

	new => \&new,
	aggregate => \&aggregate,
	download => \&download,
	copy => \&copy,

	AGGR_MODE => {DAY => 1},
	#MODE => {NC => 1, ND => 1, CC => 1, CD => 1},

	COUNT => {			# FUNCTION PARAMETER    $funcp
		EXEC => "US",
		graphp => [		# GPL PARAMETER         $gplp
			@params::PARAMS_COUNT, 
		],
		graphp_mode => {
			NC => [
				@params::PARAMS_COUNT, 
			],
			ND => [
				@params::PARAMS_COUNT, 
			],
			CC => [
				 @params::ACCD_PARAMS, 
			],
			CD => [
				 @params::ACCD_PARAMS, 
			],
		},
	},
	FT => {
		EXC => "Others",  # "Others,China,USA";
		ymin => 10,
		average_date => 7,
		graphp => [
			@params::PARMS_FT
		],
	},
	ERN => {
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
#	For initial (first call from cov19.pl)
#
sub	new 
{
	return $PARAMS;
}

#
#	Download data from the data source
#
sub	download
{
	my ($info_path) = @_;
	system("wget $WHO_PAGE -O $REPORT_MAIN");	
}

#
#	Copy download data to Windows Path
#
sub	copy
{
	my ($info_path) = @_;
}

#
#	Aggregate WHO Situation Report 
#		Most duty part of this program set
#
my $START_DATE = 20200301;	# 20200220以前はフォーマットが違う
my $END_DATE   = 99999999;		
my $LAST_DATE = 0;

my @HTML_LIST = ();
my @DLF_LIST = ();

my %TOTAL_CASE = ();
my %NEW_CASE = ();
my %TOTAL_DEATH = ();
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
		$date =~ s/[^0-9].+$//;
		$DATES{$date}++;
		$LAST_DATE = $date if($date > $LAST_DATE);

		$txtf =~ s/\.pdf/.txt/;
		my $txtd = $txtf;
		$txtd =~ s/.txt/-d.txt/;
		dp::dp $txtf , "\n" if($DEBUG > 2);

		dp::dp "DL: $html\n" if($DEBUG > 2);
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
			#dp::dp "[$country] " if($country =~ /Koso/);

			next if($country =~ /regions International/i);
			next if($country =~ /regions/);
			$country = "Iran" if($country =~ /Iran/);
			$country = "USA"  if($country =~ /United States of America/);
			$country = "UK"  if($country =~ /The United Kingdom/);
			$country =~ s/ *transmission *//;
			$country =~ s/ *\[[0-9]*\] *//;
			#dp::dp "[$country] \n" if($country =~ /Koso/);
			
			dp::dp "### COUNTRY($date):" . join(",", $region, $country, @w) . " \n" if($country =~ /^[0-9]+$/);

			my $k = join("\t", $date, $country);

			my $c = 0;
			if($mode =~ /^N[A-Z]/ || $mode =~ /^C[A-Z]/){
				$c = csvlib::valdef($w[1], 0) if($mode eq "NC");
				$c = csvlib::valdef($w[3], 0) if($mode eq "ND");
				$c = csvlib::valdef($w[1], 0) if($mode eq "CC");	# for total count, must be daily data
				$c = csvlib::valdef($w[3], 0) if($mode eq "CD");	# for total count, must be daily data
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
			$TOTAL_DEATH{$k} = csvlib::valdef($w[2], 0);	# Total deth
			$NEW_DETH{$k}   = csvlib::valdef($w[3], 0);	# new death 
		}
		close(TXT);
	}
	dp::dp "#### LAST_DATE : $LAST_DATE\n" if($DEBUG > 1);
		
	my $whoindexf = $config::HTML_PATH . "/" . $config::WHO_INDEX;

	open(SRC, ">$whoindexf") || die "Cannot create $whoindexf\n";
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

	#dp::dp "#### " . $COUNTRY{Plurinational} , "###\n";
	#dp::dp join("\n", keys %COUNTRY);
	#for(keys %COUNTRY){
	#	dp::dp $_ . "\n" if(/International/);
	#}

	#
	#	CSV の作成
	#
	my %NODATA = ();
	my @COL = ();
	my %COUNT_D = ();

	dp::dp "Report_csv $report_csvf\n" if($DEBUG > 0);
	unlink($report_csvf) || dp::dp STDERR "cannot remove $report_csvf $!\n";
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
			$c = csvlib::valdef($TOTAL_CASE{$k}, 0) if($mode eq "CC");
			$c = csvlib::valdef($TOTAL_DEATH{$k}, 0) if($mode eq "CD");
			if($PP){
				if(defined $POP{$country}){
					$c /= $POP{$country};
				}
				else {
					#dp::dp "No population data for [$country]\n" if(! defined $NODATA{$country});
					dp::dp "$country\n" if(! defined $NODATA{$country});
					$NODATA{$country}++;
				}
			}
			
			if($mode eq "DR"){
				$c = 0;
				$c = int(10000 * csvlib::valdef($TOTAL_DEATH{$k}, 0) / csvlib::valdef($TOTAL_CASE{$k}, 0)/100) if(csvlib::valdef($TOTAL_CASE{$k}, 0) > 0);
			
				dp::dp join("," , $dt, $country, csvlib::valdef($TOTAL_DEATH{$k}, 0), csvlib::valdef($TOTAL_CASE{$k}, 0), $c) , "\n" if($DEBUG);
			}
			print CSV $c , ",";
			$COUNT_D{$country}[$i] = $c;
			$i++;
		}
		#dp::dp join(",", @{$COUNT_D{$country}}) . "\n" if($country =~ /Japan/);

		print CSV "\n";
	}
	close(CSV);
}

#
#	Get WHO situation report home page HTML and list up the url of the situation report (PDF)
#
sub	get_situation_list
{
	open(HTML, $REPORT_MAIN) || die "cannot open $REPORT_MAIN";
	while(<HTML>){
		while(s/"[^"]+\.pdf\?[^"]+"//){
			my $pdf = $&;

			$pdf =~ s/"([^"]+)"/$1/;

			my $dlf = $pdf;
			$dlf =~s#.+/(.+pdf)\?.*$#$1#;
			dp::dp length($_) . " " , "PDF:$pdf" . "\n", "DLF:$dlf" . "\n" if($DEBUG > 2);
		
			my $date = $dlf;
			$date =~ s/[^0-9].+$//;
			#dp::dp "[$date]\n";
			next if($date < $START_DATE || $date > $END_DATE);		# 2/20 以前はフォーマットが違うため

			push(@HTML_LIST, $pdf);
			push(@DLF_LIST, $dlf);	
		}
	}
}

#
#	Textized WHO situation report (PDF) to csv data
#		Most durty cord in this source code.
#
##### CASE 1
#
#	El Salvador                                   395                  18                    9                   0       Clusters of cases                         0 
#   Venezuela (Bolivarian Republic 
#   of)                                           331                    2                 10                    0       Clusters of cases                         0 
#   Paraguay                                      249                  10                    9                   0   Community transmission                        0 
#
##### CASE 2
#
#   Niger                                         719                    6                 32                    0       Clusters of cases                         0 
#   Burkina Faso                                  645                    7                 43                    1   Community transmission                        0 
#   Democratic Republic of the 
#   Congo                                         572                  72                  31                    0       Clusters of cases                         0 
#   Mali                                          490                    8                 26                    1       Clusters of cases                         0 
#
##### CASE 3
#	Territoriesii 
#	occupied Palestinian territory 344 0 2 0 Clusters of cases 1 
#	Europe 
#	Spain 213435 518 24543 268 Community transmission 0 
#
#
#
#
#
#
sub	molding
{
	my ($txtf, $txtd, $date) = @_;

	my $REGION = "---";
	my @RECORD = ();
	my $LAST_W = -1;

	my $dataf = 0;
	my $ln = 0;
	my $post_c = "";

	dp::dp "##### $txtf\n";

	open(TXT, $txtf) || die "cannot open $txtf\n";
	while(<TXT>){
		dp::dp "[$dataf] $_" if($DEBUG > 2);

		s/ *[\r\n]+$//;
		if(/^ +Community$/){
			dp::dp "#" x 20 . "Community\n";
			next;
		}
		s/^ +//;
		if(/Region of the Americas/){
			dp::dp "-" x 20 , $_ , "\n";
			$post_c = "";
			$LAST_W = 0;
			next;
		}


		$dataf = 1 if(/^ *SURVEILLANCE/i);
		$dataf = 2 if(/^Western Pacific Region/ && $dataf == 1);
		$dataf = 2 if(/^ *Reporting Country/ && $dataf == 1);		# 2020/05/01
		$dataf = 3 if(/^Grand total/);

		next if($dataf <= 1);
		next if(/^ *Reporting Country/ && $dataf == 2);		# 2020/05/01

		if(/††/ || /[\*]{2}/ || /Territories/ || /^ *Territory\/Area/){
			$LAST_W = -1;
			$post_c = "";
			next;
		}

		s/†//;
		s/\^+//;

		# dp::dp "[$dataf]" . $_ , "\n" if($DEBUG);
		s/\(([0-9]+)\)/ $1 /g if($date <= 20200301);		# format
		my @w = split(/ {2,999}/, $_);

		#
		#	Set record
		#
		if($#w > 1){
			if($post_c){
				$w[0] = $post_c . " " . $w[0];
				dp::dp "---> " . $w[0] , "\n" if($DEBUG > 1);
				$post_c = "";
			}

			#	Adjust Coutry name
			$w[0] =~ s/Africa // if($w[0] =~ /Africa South Africa/);
			dp::dp "[DATA] $ln " . join(",", @w) , "\n" if($DEBUG && $w[0] =~ /America/);

			$RECORD[$ln][0] = $REGION;
			my $check = 0;
			if($date >= 20200227){	# after 2020/02/27
				for(my $i = 0; $i <= 4; $i++){
					if(! defined $w[$i] ){
						dp::dp "ERROR at data set (w):" .  join(",", @w) . "\n" if($DEBUG);
						$check ++;
					}
					elsif(($i >= 1 && $i <= 4) && $w[$i] =~ /[^0-9\-]/){
						dp::dp "ERROR at data set:[". $w[$i] ."] " . join(",", @w) . "\n" if($DEBUG);
						$check++;
					}
					$RECORD[$ln][$i+1] = $w[$i];
				}
			}
			else {			# old data befor 2020/02/27
				$RECORD[$ln][1] = $w[1];
				$RECORD[$ln][2] = $w[2];
				$RECORD[$ln][3] = $w[11];
				$RECORD[$ln][4] = $w[12];
			}
			if(!$check){
				$ln++;
			}
			
			#	05/02
			$post_c = "";		
			my $c = $w[0];
			if($c =~ /Burkina Faso/ || $c =~ /El Salvador/){
				@w = ();
			}
		}
		elsif(/Region/ || /^ *Europe$/){ 
			$REGION = $w[0];
			$post_c = "";
		}
		elsif(/Diamond Princess/){
			dp::dp ">> $ln " . $RECORD[$ln-1][0] ;
			dp::dp "($w[0])" , "\n";
			$RECORD[$ln-1][0] .= " " . $w[0];
			dp::dp "<< " . $RECORD[$ln-1][0] , "\n";
		}
		#
		#	only first colum is set (basically, a part of country
		#
		elsif(defined $w[0]){			# 
			if($LAST_W > 1){							# if last raw has the data 
				$RECORD[$ln-1][1] .= " " . $w[0];		# add $w[0] to last country
				dp::dp "#PRE:$LAST_W# $RECORD[$ln-1][1]\n" if($DEBUG > 0);
			}
			else {
				$post_c .= $w[0];   					# Set post country  ;
				dp::dp "#POST:$LAST_W# $post_c\n" if($DEBUG > 1);
			}
		}
		last if($dataf == 3);
		$LAST_W = $#w;				# number of columns
	}
	close(TXT);

	dp::dp $txtd , "\n" if($DEBUG > 0);
	open(TXD, ">$txtd") || die "cannot create $txtd";
	for(my $n = 0; $n < $ln; $n++){
		#dp::dp "## $n $RECORD[$n]\n" if($DEBUG > 1);
		my @w = @{$RECORD[$n]};
		if(! defined $w[5]){
			dp::dp "ERROR: $txtf". join(",", @w) . "\n";
		} 
		print TXD join(",", @w[0..5]), "\n";
		dp::dp "$n:  " . join(",", @w), "\n" if($DEBUG > 1);
	}
	close(TXD);
}

1;
