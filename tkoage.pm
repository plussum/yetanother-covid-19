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
my $fromImage = "$BASE_DIR/fromImage";

my $EXC = "都外";
my $STD = "05/20";
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
	THRESH => { 	# move to config.pm
		NC => 9,
		ND => 9,
		NR => 0,
		CC => 0,
		CD => 0,
		CR => 0,

		ERN => 0,
		FT => 0,
		KV => 0,
	},

	COUNT => {			# FUNCTION PARAMETER	$funcp
		EXEC => "",
		graphp => [		# GPL PARAMETER			$gplp
		],
		graphp_mode => {												# New version of graph pamaeter for each MODE
			NC => [
				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC# ", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 2, graph => "lines", avr_date => 7, nosort => 1},
				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC# ruiseki +1", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 2, graph => "lines", 
						avr_date => 7, ruiseki => 1, nosort => 1, thresh => ""},
				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC# ruiseki -1", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 2, graph => "lines", 
						avr_date => 7, ruiseki => -1, nosort => 1, thresh => ""},
			],
			CC => [
				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 2, graph => "lines"},
				{ext => "#KIND# Tokyo TOP20 (#LD#) #SRC# ruiseki", start_day => 0,  lank =>[0, 19] , exclusion => $EXC, target => "", label_skip => 2, graph => "lines", nosort => 1, ruiseki => 1, thresh => ""},
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
			{ext => "#KIND# ALL (#LD#)", start_day => 0, lank =>[0, 10] , exclusion => $EXC, target => "", label_skip => 2, graph => "lines", nosort => 1},
			{ext => "#KIND# ALL (#LD#) max3", start_day => 0, lank =>[0, 10] , exclusion => $EXC, target => "", label_skip => 2, graph => "lines", ymax => 3, nosort => 1},
			{ext => "#KIND# ALL (#LD#) max10", start_day => 0, lank =>[0, 10] , exclusion => $EXC, target => "", label_skip => 2, graph => "lines", ymax => 10, nosort => 1},
			{ext => "#KIND# 1-7 (#LD#) max10", start_day => 0, lank =>[1, 7] , exclusion => $EXC, target => "", label_skip => 2, graph => "lines", ymax => 10, nosort => 1},
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
	dp::dp $cmd . "\n";
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

	my $index = $agrp->{index};
	my $csvf = $agrp->{output_file};

	#
	#	from PDF by hand
	#
	opendir(my $df, $fromImage) || die "cannot open $fromImage";
	while(my $fn = readdir($df)){
		next if($fn =~ /^[^0-9]/);

		dp::dp "fromImage: " . $fn . "\n";
		&pdf2data("$fromImage/$fn");
	}
	closedir($df);

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
			#dp::dp $pdf . "\n" if($rec++ < 3);		# 3
		}
	}
	close(HTML);

	#
	#	generate csv file from pdf(text)
	#
	dp::dp $csvf . "\n";
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

	open(PDF, "$txtf") || die "cannot open $txtf";
	my $date = "";
	my $kn = 0;
	while(<PDF>){
		s/（/(/g;
		s/）/)/g;
		chop;

		if(/◆令和.+年(.+)月(.+)日.+時.+分時点/){
			#print "$_\n";
			s/.*年(.+)月(.+)日.*/$1\t$2/;
			#print "$_\n";
			my($m, $d) = split(/\t/, $_);
			$m = &utf2num($m);
			$d = &utf2num($d);
			$date = sprintf("%02d/%02d", $m, $d);
			#print "$date\n";
			$DATE_FLAG{$date} = $date;
		}
		elsif(/10歳未満 +10代 +20代 +30代/){
			chop;
			s/^ +//;
			@RANGE_NAME = split(/ +/, $_);
			my $d = <PDF>;
			$d =~ s/[\r\n]+$//;
			$d =~ s/^ +//;
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

