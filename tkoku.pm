#!/usr/bin/perl
#
#	kaz-ogiwara / covid19
#	https://github.com/kaz-ogiwara/covid19
#
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
my $index_html = "cln202002_kns01_me01.html";
my $base_url = "https://www.city.shinjuku.lg.jp";
our $src_url = "$base_url/kusei/$index_html";

my $BASE_DIR = "$WIN_PATH/tokyo-ku";
my $index_file = "$BASE_DIR/$index_html";
my $pdf_dir = "content";
my $transaction = "$CSV_PATH/tokyo-ku.csv.txt";

my $EXC = "都外";
our $PARAMS = {			# MODULE PARETER		$mep
    comment => "**** TOYO-KU  ****",
    src => "TOYO KU ONLINE",
	src_url => $src_url,
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

	POP_THRESH => 100,
	AGGR_MODE => {DAY => 1, POP => 7},		# POP: 7 Days Total / POP
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
				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo TOP20 5/15 (#LD#) #SRC#", start_day => "05/15",  lank =>[0, 19] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo TOP20 5/15 (#LD#) #SRC# wo Shinjyuku", start_day => "05/15",  lank =>[0, 19] , exclusion => "新宿", target => "", 
					label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo 1 5/15 (#LD#) #SRC#", start_day => "05/15",  lank =>[0, 0] , exclusion => "", target => "", 
					label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo 1-5 5/15 (#LD#) #SRC#", start_day => "05/15",  lank =>[0, 3] , exclusion => "新宿", target => "", 
					label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo 6-10 5/15 (#LD#) #SRC#", start_day => "05/15",  lank =>[5, 9] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo 11-15 5/15 (#LD#) #SRC#", start_day => "05/15",  lank =>[10, 14] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo 16-20 5/15 (#LD#) #SRC#", start_day => "05/15",  lank =>[15, 19] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},

				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC# rlav 7", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo TOP20 5/15 (#LD#) #SRC# rlav 7", start_day => "05/15",  lank =>[0, 19] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo TOP20 5/15 (#LD#) #SRC# wo Shinjyuku rlav 7", start_day => "05/15",  lank =>[0, 19] , exclusion => "新宿", target => "", 
					label_skip => 2, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 1 5/15 (#LD#) #SRC# rlav 7", start_day => "05/15",  lank =>[0, 0] , exclusion => "", target => "", 
					label_skip => 2, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 1-5 5/15 (#LD#) #SRC# rlav 7", start_day => "05/15",  lank =>[0, 3] , exclusion => "新宿", target => "", 
					label_skip => 2, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 6-10 5/15 (#LD#) #SRC# rlav 7", start_day => "05/15",  lank =>[5, 9] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 11-15 5/15 (#LD#) #SRC# rlav 7", start_day => "05/15",  lank =>[10, 14] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines", avr_date => 7},
				{ext => "#KIND# Tokyo 16-20 5/15 (#LD#) #SRC# rlav 7", start_day => "05/15",  lank =>[15, 19] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines", avr_date => 7},

			],
			CC => [
				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},
#				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC# logscale", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", 
#					label_skip => 2, graph => "lines", logscale => "y"},
				{ext => "#KIND# Tokyo 1-5 (#LD#) #SRC#", start_day => 0,  lank =>[0, 4] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo 1-5 (#LD#) #SRC# wo Shinjyuku", start_day => 0,  lank =>[0, 4] , exclusion => "新宿", target => "", 
					label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo 6-10 (#LD#) #SRC#", start_day => 0,  lank =>[5, 9] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo 10-15 (#LD#) #SRC#", start_day => 0,  lank =>[10, 14] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo 16-20 (#LD#) #SRC#", start_day => 0,  lank =>[15, 19] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},
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
			{ext => "#KIND# TOP5 #FT_TD#", start_day => 0, lank =>[0, 5] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},
		],
	},
	KV => {
		EXC => "Others",
		graphp => [
			{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", 
					label_skip => 2, graph => "lines"},
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
	my ($mep) = @_;

	unlink($index_file);
	my $cmd = "wget " . $mep->{src_url} . " -O $index_file" ;
	print $cmd . "\n";
	system ($cmd);
}

#
#	Copy download data to Windows Path
#
sub	copy
{
	my ($info_path) = @_;

	#system("cp $transaction $CSV_PATH/");
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

	my $index = $agrp->{index};
	my $csvf = $agrp->{output_file};


	#
	#	load index and download pdf files
	#
	my $rec = 0;
	open(HTML, $index_file) || die "cannot open $index_file";
	while(<HTML>){
		if(/都内の新型コロナウイルス関連患者数等/){
			chop;
			s#.*a href="/(content/[0-9]+\.pdf)".*#$1#;
			my $pdf = $_;
			my $pdf_url = "$base_url/$pdf";
			#dp::dp $pdf_url . "\n";
			my $pdf_file = "$BASE_DIR/$pdf";
			#dp::dp "[$pdf_file]\n";
			if(! -e $pdf_file){
				system("wget $pdf_url -O $pdf_file");
			}
			if(!-e "$pdf_file.txt"){
				dp::dp "ps2ascii $pdf > $pdf.txt\n";
				system("ps2ascii $pdf_file > $pdf_file.txt") 
			}
			&pdf2data("$pdf_file.txt");
			if($rec++ < 3) {
				dp::dp $pdf . "\n";
			}
		}
	}
	close(HTML);

	#
	#	generate csv file from pdf(text)
	#
	dp::dp $csvf . "\n";
	open(CSV, "> $csvf") || die "cannto create $csvf";
	my @KUS = (sort {$KU_FLAG{$b} <=> $KU_FLAG{$a}} keys %KU_FLAG);
	my @DATES = (sort keys %DATE_FLAG);

	print CSV join($DLM, "#", @DATES) . "\n";
	my $no = 1;
	foreach my $ku (@KUS){
		my @nn = ();
		my $lv = 0;
		foreach my $date (@DATES){
			my $v = $CONFIRMED{$date}{$ku};
			push(@nn, $v - $lv);
			$lv = $v;
		}
		print CSV join($DLM, $ku, @nn) . "\n";
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
	while(<PDF>){
		chop;
		if(/【参考】区市町村別患者数（都内発生分）/){
			s/^.*　（(.*)月(.*)日時点.*$/$1\t$2/;
			#dp::dp "[$_]\n";
			my ($m, $d) = split(/\t/, $_);
			#dp::dp "$m $d -> ";
			$m = &utf2num($m);
			$d = &utf2num($d);

			#dp::dp "$m $d \n";
			$date = sprintf("%02d/%02d", $m, $d);
			#last if(! ($date ge "04/05" && $date le "04/10"));		#### 
			#last if($date ne "05/01");		#### 

			$DATE_FLAG{$date} = $date;
			#dp::dp "$txtf \n";
		}
		elsif($date && /今後の調査の状況により、数値は変更される可能性があります/){
			last;
		}
		elsif($date) {
			last if($kn++ > 5);
			#dp::dp $_ . "\n";
			s/東久留米武蔵村山/東久留米  武蔵村山/;
			s/あきる野西東京/あきる野  西東京/;
			s/世田谷渋谷/世田谷 渋谷/;
			s/、/  /g;
			s/」//g;
			s/T//g;
			my @ku = split(/ +/, $_);
			my $d = <PDF>;
			#dp::dp $d;
			chop $d;
			my @number = split(/ +/, $d);
			#dp::dp "\n" . "-" x 20 . "\n";
			#if($#ku != $#number){
			#	dp::dp  ">>> " . $_  . "\n";
			#	dp::dp  ">>> " . $d  . "\n";
			#}
			#dp::dp "# " . join(",", $#ku, @ku). "\n";
			#dp::dp "# " . join(",", $#number, @number). "\n";
			#dp::dp "\n" . "-" x 20 . "\n";

			for(my $i = 1; $i < $#ku; $i++){
				my $k = $ku[$i];
				$KU_FLAG{$k} = $number[$i] if(!defined $KU_FLAG{$k} || $number[$i] > $KU_FLAG{$k});
				#dp::dp join(":", $date, $k, $number[$i]) . " ";
				$CONFIRMED{$date}{$k} = $number[$i];
			}
		}
	}
	close(PDF);
}
#
#
#
sub	utf2num
{
	my($utf) = @_;

	my $un = "０１２３４５６７８９";
	my $number = 0;

	#dp::dp "\n($utf)\n";
	for(my $i = 0; $i < length($utf) ; ){
		$_ = substr($utf, $i, 99);
		#dp::dp "($_)\n";
		my $nn = -1;
		if(/^[0-9]+/){
			$nn = $&;
			$i += ($nn > 9) ? 2 : 1;
			#dp::dp "[[$nn:$i:$number]]\n";
		}
		else {
			my $n = substr($utf, $i, 3);
			$nn = index($un, $n);
			last if($nn < 0);

			$nn = $nn / 3;
			$i += 3;
			#dp::dp "<<$n:$nn:$i:$number>>\n";
		}
		last if($nn < 0);

		#dp::dp "($utf:$n)";
		
		$number = $number * 10 + $nn;
	}
	#dp::dp "$utf => $number\n";
	return $number;
}
		

1;

