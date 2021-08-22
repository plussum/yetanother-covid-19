#!/usr/bin/perl
#
#	kaz-ogiwara / covid19
#	https://github.com/kaz-ogiwara/covid19
#
#
#
#

package tkoage;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(tkoage);

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
my $aged = "60代,70代,80代,90代,100歳以上代";
my $yang = "10代,10歳未満";
our $PARAMS = {			# MODULE PARETER		$mep
    comment => "**** TOYO-KU  ****",
    src => "TOYO KU ONLINE",
	src_url => $src_url,
	references => ["https://www.fukushihoken.metro.tokyo.lg.jp/hodo/saishin/index.html"],
    prefix => "tkoage_",
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

	POP_THRESH => 10000,
	AGGR_MODE => {DAY => 1, POP => 1},		# POP: 7 Days Total / POP
	#MODE => {NC => 1, ND => 1},
#	sort_balance =>0.7,  	# ALL = 0; 0.7 = 後半の30%のデータでソート
#	sort_weight => 0.1,	# 0: No Weight, 0.1: 10%　Weight -0.1: -10% Wight
#
#	SORT_BALANCE => {		# move to config.pm
#		CC => [0.99, 0.1],
#		CD => [0.99, 0.1],
#	},
#	THRESH => { 	# move to config.pm
#		NC => 9,
#		ND => 9,
#		NR => 0,
#		CC => 0,
#		CD => 0,
#		CR => 0,
#
#		ERN => 0,
#		FT => 0,
#		KV => 0,
#	},

	COUNT => {			# FUNCTION PARAMETER	$funcp
		EXEC => "",
		graphp => [		# GPL PARAMETER			$gplp
		],
		graphp_mode => {												# New version of graph pamaeter for each MODE
			NC => [
				{ext => "#KIND# Tokyo Age (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo Age (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", 
						avr_date => 7, nosort => 1},
			#	{ext => "#KIND# Tokyo Age (#LD#) #SRC# large", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", 
			#			avr_date => 7, nosort => 1, term_ysize => 600},
				{ext => "#KIND# Tokyo Age (#LD#) #SRC# 2m rlavr", start_day => -61,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", 
						avr_date => 7, nosort => 1},
			#	{ext => "#KIND# Tokyo Age (#LD#) #SRC# 2m large", start_day => -61,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", 
			#			avr_date => 7, nosort => 1, term_ysize => 600,},
				{ext => "#KIND# Tokyo Age (#LD#) #SRC# 2m", start_day => -61,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", 
						nosort => 1},

				{ext => "#KIND# Tokyo OLD Age (#LD#) #SRC# 2m rlavr", start_day => -61,  lank =>[0, 19] , exclusion => $EXC, target => "$aged", label_skip => 1, graph => "lines", 
						avr_date => 7, nosort => 1},
				{ext => "#KIND# Tokyo Yang Age (#LD#) #SRC# 2m rlavr", start_day => -61,  lank =>[0, 19] , exclusion => $EXC, target => "$yang", label_skip => 1, graph => "lines", 
						avr_date => 7, nosort => 1},

				#{ext => "#KIND# Tokyo Age (#LD#) #SRC# ruiseki01", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", 
				#		avr_date => 7, ruiseki => 1, nosort => 1, thresh => ""},
				{ext => "#KIND# Tokyo Age (#LD#) #SRC# ruiseki02", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", 
						avr_date => 7, ruiseki => -1, nosort => 1, thresh => ""},
				{ext => "#KIND# Tokyo Age (#LD#) #SRC# ruiseki03(Percent)", start_day => 0, lank =>[0, 19] , exclusion => "100,不明", target => "", label_skip => 7, graph => "lines", 
						avr_date => 7, ruiseki => -1, nosort => 1, thresh => "", ruiseki_percent => 1},
				{ext => "#KIND# Tokyo Age (#LD#) #SRC# ruiseki02 2m", start_day => -61,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 1, graph => "lines", 
						avr_date => 7, ruiseki => -1, nosort => 1, thresh => ""},

				{ext => "#KIND# Tokyo over 50 #1(#LD#) #SRC# ruiseki03", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, 
					target => "50,60,70,80,90,100", label_skip => 7, graph => "lines", avr_date => 7, ruiseki => -1, nosort => 1, thresh => ""},

				{ext => "#KIND# Tokyo over 50 #2 (#LD#) #SRC# ruiseki04", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, 
					target => "50,60,70,80,90,100", label_skip => 7, graph => "lines", avr_date => 7, nosort => 1, thresh => ""},
			],
			CC => [
				{ext => "#KIND# Tokyo Age (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines"},
				{ext => "#KIND# Tokyo Age (#LD#) #SRC# ruiseki", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines",
					 nosort => 1, ruiseki => 1, thresh => ""},
			],
		},
	},
	FT => {
		EXEC => "",
		average_date => 7,
		ymin => 10,
		graphp => [
			{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC#", start_day => 0,  lank =>[0, 5] , exclusion => $EXC, target => "", 
					label_skip => 7, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
		],
	},
	ERN => {
		EXEC => "",
        ip => $config::RT_IP,
		lp => $config::RT_LP,,
		average_date => 7,
		graphp => [	
			{ext => "#KIND# ALL (#LD#)", start_day => 0, lank =>[0, 10] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", nosort => 1},
			{ext => "#KIND# ALL (#LD#) 2m", start_day => -62, lank =>[0, 10] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", nosort => 1, ymax => 2},
			{ext => "#KIND# ALL (#LD#) max3", start_day => 0, lank =>[0, 10] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", ymax => 3, nosort => 1},
			{ext => "#KIND# ALL (#LD#) max10", start_day => 0, lank =>[0, 10] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", ymax => 10, nosort => 1},
			{ext => "#KIND# 1-7 (#LD#) max10", start_day => 0, lank =>[1, 7] , exclusion => $EXC, target => "", label_skip => 7, graph => "lines", ymax => 10, nosort => 1},
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
	tkopdf::download(@_);
}

#
#	Copy download data to Windows Path
#
sub	copy
{
	tkopdf::download(@_);
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

my %DATE_FLAG = ();

my @RANGE_NAME = ();
my %RANGE = ();
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
	my @DATES = (sort keys %DATE_FLAG);

	print CSV join($DLM, "#", @DATES) . "\n";
	my $no = 1;
	foreach my $r (@RANGE_NAME){
		my @nn = ();
		foreach my $date (@DATES){
			my $v = csvlib::valdef($RANGE{$date}{$r}, 0);
			#dp::dp join(",", $date, $r, $v) . "\n";
			push(@nn, $v);
		}
		print CSV join($DLM, $r, @nn) . "\n";
	}
	close(CSV);
}

#
#
#
sub	pdf2data
{
	my ($txtf) = @_;

	#dp::dp "$txtf\n";
	open(PDF, "$txtf") || die "cannot open $txtf";
	my $date = "";
	my $kn = 0;
	while(<PDF>){
		s/（/(/g;
		s/）/)/g;
		chop;

		if(/◆令和(.+)年(.+)月(.+)日.+時.+分時点/){
			my($y, $m, $d) = ($1, $2, $3);
			#print "$_\n";
			#  ◆令和２年４月１６日 １８時３０分時点
			#s/令和(.+).*年(.+)月(.+)日.*/$1\t$1\t$2/;		# 2020/01/03 Y/M/D
			#print "$_\n";
			#my($y, $m, $d) = split(/\t/, $_);
			$y = tkopdf::utf2num($y) + 2018;				# 令和 -> 西暦
			$m = tkopdf::utf2num($m);
			$d = tkopdf::utf2num($d);
			$date = sprintf("%04d/%02d/%02d", $y, $m, $d);
			#dp::dp"$date $txtf\n";
			$DATE_FLAG{$date} = $date;
		}
		elsif(/10歳未満 +10代 +20代 +30代/){
			chop;
			s/^ +//;
			@RANGE_NAME = split(/ +/, $_);
			my $d = <PDF>;
			$d =~ s/[\r\n]+$//;
			$d =~ s/^ +//;
			$d =~ s/,//g;
			my @w = split(/ +/, $d);
			for(my $i = 0; $i <= $#RANGE_NAME; $i++){
				my $r = $RANGE_NAME[$i];
				$RANGE{$date}{$r} = csvlib::valdef($w[$i], 0);
				#dp::dp "$date [$r](" . $w[$i] . ")\n";
			}
			last;
		}
	}
	close(PDF);
}

