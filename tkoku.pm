#!/usr/bin/perl
#
#	Get data from Tokyo-to directory instead of Shinjyku-ku
#	Because of the dealy of updating the data
#
# 	https://www.metro.tokyo.lg.jp/tosei/hodohappyo/ichiran.html
#
#	Shinjyuku-ku data URL
# 	https://www.city.shinjuku.lg.jp/kusei/cln202002_kns01_me01.html
#
#
#

package tkoku;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(tkoku);

use strict;
use warnings;

use Data::Dumper;
use csvgpl;
use csvaggregate;
use csvlib;
use tkopdf;

#
#	Initial
#
my $WIN_PATH = $config::WIN_PATH;
my $CSV_PATH = $config::CSV_PATH;
my $DLM = $config::DLM;

my $DEBUG = 1;


#
#	Parameter set
#
# 	https://www.metro.tokyo.lg.jp/tosei/hodohappyo/ichiran.html
my $src_url = $tkopdf::src_url;
my $index_file = $tkopdf::index_file;
my $transaction = $tkopdf::transaction;

my $EXC = "都外";
my $STD = "2020/05/20";
our $PARAMS = {			# MODULE PARETER		$mep
    comment => "**** TOYO-KU  ****",
    src => "TOYO KU ONLINE",
	src_url => $src_url,
	references => ["https://www.fukushihoken.metro.tokyo.lg.jp/hodo/saishin/index.html"],
    prefix => "tkoku_",
    src_file => {
		NC => $transaction,
		CC => $transaction,
    },
    base_dir => "",
	csv_aggr_mode => "", 	# "" or TOTAL

    new => \&new,
    aggregate => \&aggregate,
    download => \&download,
    copy => \&copy,

	POP_THRESH => 5000,
	AGGR_MODE => {DAY => 1, POP => 1},		# POP: 7 Days Total / POP
	#MODE => {NC => 1, ND => 1},
#	sort_balance =>0.7,  	# ALL = 0; 0.7 = 後半の30%のデータでソート
#	sort_weight => 0.1,	# 0: No Weight, 0.1: 10%　Weight -0.1: -10% Wight
#
#	SORT_BALANCE => {		# move to config.pm
#		CC => [0.99, 0.1],
#		CD => [0.99, 0.1],
#	},

	COUNT => {			# FUNCTION PARAMETER	$funcp
		EXEC => "",
		graphp => [		# GPL PARAMETER			$gplp
		],
		graphp_mode => {												# New version of graph pamaeter for each MODE
			NC => [
				#{ext => "#KIND# Tokyo 1-5 MONTH (#LD#) #SRC# ", start_day => "-31",  lank =>[0, 4] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7},
				#{ext => "#KIND# Tokyo 6-10 MONTH (#LD#) #SRC# ", start_day => "-31",  lank =>[5, 9] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7},
				#{ext => "EOD"},

				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo TOP01-10 1m (#LD#) #SRC# raw", start_day => -31,  lank =>[0, 9] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines",  thresh => 1},
				#{ext => "#KIND# Tokyo TOP01-10 2m TH:5(#LD#) #SRC#", start_day => -61,  lank =>[0, 9] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7, thresh => 5},
				{ext => "#KIND# Tokyo TOP01-10 1m (#LD#) #SRC#", start_day => -31,  lank =>[0, 9] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7, thresh => 1},
				#{ext => "#KIND# Tokyo TOP01-10 2m TH:5(#LD#) #SRC#", start_day => -61,  lank =>[0, 9] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7, thresh => 5},
				#{ext => "#KIND# Tokyo TOP01-10 2m TH:8(#LD#) #SRC#", start_day => -61,  lank =>[0, 9] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7, thresh => 9},
				{ext => "#KIND# Tokyo TOP11-20 2m (#LD#) #SRC#", start_day => -61,  lank =>[10, 19] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7},

				{ext => "#KIND# Tokyo TOP01-10 1m (#LD#) #SRC#", start_day => -21,  lank =>[0, 9] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7, thresh => 1},
				{ext => "#KIND# Tokyo TOP11-20 1m (#LD#) #SRC#", start_day => -21,  lank =>[10, 19] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7, thresh => 1},

				{ext => "#KIND# Tokyo TOP20 ruiseki(#LD#) #SRC#", start_day => 0,  lank =>[0, 99] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", avr_date => 7, 
						ruiseki => -1, term_ysize => 450},
				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo TOP20 $STD (#LD#) #SRC#", start_day => "$STD",  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				#{ext => "#KIND# Tokyo TOP20 $STD (#LD#) #SRC# wo Shinjyuku", start_day => "$STD",  lank =>[0, 19] , exclusion => "新宿", target => "", label_skip => 7, graph => "lines"},
				#{ext => "#KIND# Tokyo 1 $STD (#LD#) #SRC#", start_day => "$STD",  lank =>[0, 0] , exclusion => "", target => "", label_skip => 7, graph => "lines"},

				#{ext => "#KIND# Tokyo 1 $STD (#LD#) #SRC# ", start_day => "$STD",  lank =>[0, 0] , exclusion => "", target => "", label_skip => 7, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 1-5 $STD (#LD#) #SRC# ", start_day => "$STD",  lank =>[0, 4] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 6-10 $STD (#LD#) #SRC# ", start_day => "$STD",  lank =>[5, 9] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 11-15 $STD (#LD#) #SRC# ", start_day => "$STD",  lank =>[10, 14] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 16-20 $STD (#LD#) #SRC# ", start_day => "$STD",  lank =>[15, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 21-30 $STD (#LD#) #SRC# ", start_day => "$STD",  lank =>[20, 29] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 31-40 $STD (#LD#) #SRC# ", start_day => "$STD",  lank =>[30, 39] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", avr_date => 7},

				{ext => "#KIND# Tokyo 1-5 $STD (#LD#) #SRC#", start_day => "$STD",  lank =>[0, 4] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo 6-10 $STD (#LD#) #SRC#", start_day => "$STD",  lank =>[5, 9] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo 11-15 $STD (#LD#) #SRC#", start_day => "$STD",  lank =>[10, 14] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo 16-20 $STD (#LD#) #SRC#", start_day => "$STD",  lank =>[15, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo 21-30 $STD (#LD#) #SRC#", start_day => "$STD",  lank =>[20, 29] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo 31-40 $STD (#LD#) #SRC#", start_day => "$STD",  lank =>[30, 39] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},

				{ext => "#KIND# Tokyo 1-5 MONTH (#LD#) #SRC# TOP20", start_day => "-31",  lank =>[0, 20] , exclusion => "", target => "", label_skip => 1, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 1-5 MOTH (#LD#) #SRC# TOP20", start_day => "-31",  lank =>[0, 20] , exclusion => "", target => "", label_skip => 1, graph => "lines"},

				{ext => "#KIND# Tokyo 1-5 2MONTH (#LD#) #SRC# ", start_day => "-62",  lank =>[0, 4] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 6-10 2MONTH (#LD#) #SRC# ", start_day => "-62",  lank =>[5, 9] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 11-15 2MONTH (#LD#) #SRC# ", start_day => "-62",  lank =>[10, 14] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 16-20 2MONTH (#LD#) #SRC# ", start_day => "-62",  lank =>[15, 19] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 21-30 2MONTH (#LD#) #SRC# ", start_day => "-62",  lank =>[20, 29] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 31-40 2MONTH (#LD#) #SRC# ", start_day => "-62",  lank =>[30, 39] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", avr_date => 7},

				{ext => "#KIND# Tokyo 1-5 2MOTH (#LD#) #SRC#", start_day => "-62",  lank =>[0, 4] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines"},
				{ext => "#KIND# Tokyo 6-10 2MOTH (#LD#) #SRC#", start_day => "-62",  lank =>[5, 9] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines"},
				{ext => "#KIND# Tokyo 11-15 2MOTH (#LD#) #SRC#", start_day => "-62",  lank =>[10, 14] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines"},
				{ext => "#KIND# Tokyo 16-20 2MOTH (#LD#) #SRC#", start_day => "-62",  lank =>[15, 19] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines"},
				{ext => "#KIND# Tokyo 21-30 2MOTH (#LD#) #SRC#", start_day => "-62",  lank =>[20, 29] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines"},
				{ext => "#KIND# Tokyo 31-40 2MOTH (#LD#) #SRC#", start_day => "-62",  lank =>[30, 39] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines"},

				#{ext => "#KIND# Tokyo TOP10 (#LD#) #SRC#(wo Shinjyuku) ", start_day => 0,  lank =>[0, 9] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", avr_date => 7},
				#{ext => "#KIND# Tokyo TOP10 (#LD#) #SRC# ", start_day => 0,  lank =>[0, 9] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", avr_date => 7},
				#{ext => "#KIND# Tokyo TOP20 $STD (#LD#) #SRC# ", start_day => "$STD",  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", avr_date => 7},
				#{ext => "#KIND# Tokyo TOP20 $STD (#LD#) #SRC# wo Shinjyuku ", start_day => "$STD",  lank =>[0, 19] , exclusion => "新宿", target => "", label_skip => 7, graph => "lines", avr_date => 7},

			],
			CC => [
				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
#				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC# logscale", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", logscale => "y"},
				{ext => "#KIND# Tokyo 1-5 (#LD#) #SRC#", start_day => 0,  lank =>[0, 4] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				#{ext => "#KIND# Tokyo 1-5 (#LD#) #SRC# wo Shinjyuku", start_day => 0,  lank =>[0, 4] , exclusion => "新宿", target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo 6-10 (#LD#) #SRC#", start_day => 0,  lank =>[5, 9] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo 11-19 (#LD#) #SRC#", start_day => 0,  lank =>[10, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo 21-29 (#LD#) #SRC#", start_day => 0,  lank =>[20, 29] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo 31-39 (#LD#) #SRC#", start_day => 0,  lank =>[30, 39] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
			],
		},
	},
	FT => {
		EXEC => "",
		average_date => 7,
		ymin => 10,
		graphp => [
			{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC#", start_day => 0,  lank =>[0, 5] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
		],
	},
	ERN => {
		EXEC => "",
        ip => $config::RT_IP,
		lp => $config::RT_LP,,
		average_date => 7,
		graphp => [	
			{ext => "#KIND# TOP5 ", start_day => 0, lank =>[0, 4] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
			{ext => "#KIND# TOP5 ", start_day => 0, lank =>[0, 4] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", ymax => 3},
			{ext => "#KIND# TOP5 ", start_day => 0, lank =>[0, 4] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", ymax => 10},
			{ext => "#KIND# 06-10 ", start_day => 0, lank =>[5, 9] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", ymax => 10},
			{ext => "#KIND# 11-15 ", start_day => 0, lank =>[10, 14] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", ymax => 10},
			{ext => "#KIND# 16-20 ", start_day => 0, lank =>[16, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", ymax => 10},
			{ext => "#KIND# 21-25 ", start_day => 0, lank =>[20, 24] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", ymax => 10},
			{ext => "#KIND# 26-30 ", start_day => 0, lank =>[25, 29] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", ymax => 10},
		],
	},
	KV => {
		EXC => "Others",
		graphp => [
			{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", 
					label_skip => 7, graph => "lines"},
		],
	},
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
	tkopdf::download(@_);
}

#
#	Copy download data to Windows Path
#
sub	copy
{
	tkopdf::copy(@_);
}

#
#	Aggregate J.A.G Japan  
#
sub	aggregate
{
	my ($fp) = @_;

	my $mode = $fp->{mode};
	my $aggr_mode = $fp->{aggr_mode};
	my $src_file = $fp->{src_file};
	my $report_csvf = $fp->{stage1_csvf};
	my $graph_html = $fp->{htmlf};
	my $csv_aggr_mode = csvlib::valdef($fp->{csv_aggr_mode}, "");

	my $agrp = {
		mode => $mode,
		input_file => $index_file,
		output_file => $fp->{stage1_csvf},
		delemiter => $fp->{dlm},
		exclude_keys => [],						# 動作未検証
		agr_total => 0,
		agr_count => 0,
		total_item_name => "",
	};

	return &gencsv($agrp);		# 集計処理
	#system("more $aggregate");
}
#
#
#

my %CONFIRMED = ();
my %DATE_FLAG = ();
my %KU_FLAG = ();
my $data_dir = "tokyo-ku";

#
#
#
sub	gencsv
{
	my	($agrp) = @_;	

	my $csvf = $agrp->{output_file};
	my $pdf_dir = $tkopdf::PDF_DIR;

	tkopdf::getpdfdata();

	#
	#	read all pdf.txt 
	#
	opendir my $DIRH, "$pdf_dir" || die "Cannot open $pdf_dir";
	while(my $pdf_file = readdir($DIRH)){
		#dp::dp $pdf_file . "\n";
		if($pdf_file =~ "\.pdf\.txt"){
			$pdf_file = "$pdf_dir/$pdf_file";
			#dp::dp $pdf_file . "\n" if($rec++ < 3);		# 3
			&pdf2data("$pdf_file");
		}
	}

	#
	#	generate csv file from pdf(text)
	#
	dp::dp $csvf . "\n" if($config::VERBOSE);
	open(CSV, "> $csvf") || die "cannto create $csvf";
	my @KUS = (sort {$KU_FLAG{$b} <=> $KU_FLAG{$a}} keys %KU_FLAG);
	my @DATES = (sort keys %DATE_FLAG);

	my $n = 0;
#	foreach my $ku (@KUS){
#		dp::dp sprintf("%02d: ", $n++). "[$ku] [$KU_FLAG{$ku}]\n";
#	}
	print CSV join($DLM, "#", @DATES) . "\n";
	my $no = 1;
	foreach my $ku (@KUS){
		#dp::dp $ku . "\n";
		my @nn = ();
		my $lv = 0;
		foreach my $date (@DATES){
			if(!defined $CONFIRMED{$date}{$ku}){
				dp::dp "### UNDEFINED CONFIRMED: $date $ku\n";
				next;
			}
			my $v = $CONFIRMED{$date}{$ku};
			#dp::dp "$date:$ku: $v:$lv\n";# if($ku eq "小笠原");
			push(@nn, $v - $lv);
			$lv = $v;
		}
		print CSV join($DLM, $ku, @nn) . "\n";
		#dp::dp join(",", $ku, @nn) . "\n" if($ku eq "小笠原");
	}
	close(CSV);
}

#
#
#
sub	pdf2data
{
	my ($txtf) = @_;

	open(PDF, "$txtf") || die "cannot open $txtf";
	my $date = "";
	my $kn = 0;
	my $ku_flag = 0;
	while(<PDF>){
		s/（/(/g;
		s/）/)/g;
		chop;
		#if(/【参考】.*区市町村別患者数.*都内発生分.*/){
		if(/令和(.+)年(.+)月(.+)日.+時.+分時点/){		# 2021/01/03 Y/M/D
			my ($y, $m, $d) = ($1, $2, $3);
			#dp::dp "[$_] $txtf\n";
			#s/^.*\((.*)月(.*)日時点.*$/$1\t$2/;
			#my ($y, $m, $d) = split(/\t/, $_);
			#dp::dp "$m $d -> ";
			$y = tkopdf::utf2num($y) + 2018;						# 令和 -> 西暦
			$m = tkopdf::utf2num($m);
			$d = tkopdf::utf2num($d);

			#dp::dp "$m $d \n";
			$y += 2000 if($y < 100);
			$date = sprintf("%04d/%02d/%02d", $y, $m, $d);

			my $csvf = "$txtf.csv.txt";
			my $csvd = $date;
			$csvd =~ s#/#-#g;
			$csvf =~ s/txt/$csvd/; 
			open(CSV, ">$csvf") || die "cannot open $csvf";
			print CSV "# " . $date . "\n";

			#last if(! ($date ge "2020/04/05" && $date le "2020/04/10"));		#### 
			#last if($date ne "2020/05/01");		#### 

			$DATE_FLAG{$date} = $date;
			#dp::dp "$date, $txtf \n";
			#exit;
		}
		elsif(/【参考】区市町村別患者数/){
			$ku_flag = 1;
			#last;
		}
		elsif($date && $ku_flag) {
			last if($kn++ > 5);
			#dp::dp ">>>" . $_ . "\n";
			s/東久留米武蔵村山/東久留米  武蔵村山/;
			s/あきる野西東京/あきる野  西東京/;
			s/世田谷渋谷/世田谷 渋谷/;
			s/調査中.*※/調査中/;
			s/、/  /g;
			s/」//g;
			s/T//g;
			s/\|/ /g;
			s/\｜/ /g;
			s/[\r\n]//g;
			my @ku = split(/ +/, $_);

			my $d = <PDF>;
			chop $d;
			$d =~ s/[\r\n]//g;
			$d =~ s/\([0-9]+\)/  /g;
			$d =~ s/\|/ /g;
			$d =~ s/\｜/ /g;

			#dp::dp "NUMBER: $d \n";
			my @number = split(/ +/, $d);

			#dp::dp "\n" . "-" x 20 . "\n";
			#if($#ku != $#number){
			#	dp::dp  ">>> " . $_  . "\n";
			#	dp::dp  ">>> " . $d  . "\n";
			#}
			#dp::dp "# " . join(",", $#ku, @ku). "\n";
			#dp::dp "# " . join(",", $#number, @number). "\n";
			#dp::dp "\n" . "-" x 20 . "\n";

			for(my $i = 1; $i <= $#ku; $i++){
				my $k = $ku[$i];
				$KU_FLAG{$k} = $number[$i] if(!defined $KU_FLAG{$k} || $number[$i] > $KU_FLAG{$k});
				#dp::dp join(":", $date, $k, $number[$i]) . " \n";
				$CONFIRMED{$date}{$k} = $number[$i];
				print CSV join("\t", $date, $k, $number[$i]) . "\n" ;
			}
		}
	}
	close(PDF);
	close(CSV);
}
1;
