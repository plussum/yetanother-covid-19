#
#
#
#
#
package tkopdf;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(tkopdf);

use strict;
use warnings;

use Data::Dumper;
use csvlib;

my $WIN_PATH = $config::WIN_PATH;
my $CSV_PATH = $config::CSV_PATH;
my $DLM = $config::DLM;

#my $index_html = "cln202002_kns01_me01.html";
#my $base_url = "https://www.city.shinjuku.lg.jp";
#our $src_url = "$base_url/kusei/$index_html";
#our $transaction = "$CSV_PATH/tokyo-ku.csv.txt";

my $index_html = "ichiran.html";
my $base_url = "https://www.metro.tokyo.lg.jp/";
our $src_url = "$base_url/tosei/hodohappyo/$index_html";
our $transaction = "$CSV_PATH/tokyo-ku.csv.txt";

my $BASE_DIR = "$WIN_PATH/tokyo-ku";
our $index_file = "$BASE_DIR/$index_html";
our $PDF_DIR = "$BASE_DIR/content";

#
#	Download data from the data source
#
sub	download
{
	my ($mep) = @_;

	unlink($index_file);
	my $cmd = "wget " . $src_url. " -O $index_file" ;
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
#
#
sub	getpdfdata
{
	my	($agrp) = @_;	

	#
	#	from PDF by hand
	#
	#opendir(my $df, $fromImage) || die "cannot open $fromImage";
	#while(my $fn = readdir($df)){
	#	next if($fn =~ /^[^0-9]/);
	#
	#	dp::dp "fromImage: " . $fn . "\n";
	#	&pdf2data("$fromImage/$fn");
	#}
	#closedir($df);

	#
	#	load index and download pdf files
	#
	#	Shinjyuku-ku to Tokyo-to 2020.10.11
	#		ichiran.html
	#		<td><p><a href="/tosei/hodohappyo/press/2020/10/10/01.html">新型コロナウイルスに関連した患者の発生（第895報）</a></p></td>
	#
	#		01.html
	#		<p>都内の医療機関から、今般の新型コロナウイルスに関連した感染症の症例が報告されましたので、
	#			<a href="/tosei/hodohappyo/press/2020/10/10/documents/01_00.pdf" class="icon_pdf">別紙（PDF：807KB）</a>のとおり、お知らせします。</p>
	#			新型コロナウイルスに関連した患者の発生（第895報）
	#			新型コロナウイルスに関連した患者の発生（第893報）
	#
	my $rec = 0;
	dp::dp $index_file . "\n";
	open(HTML, $index_file) || die "cannot open $index_file";
	while(<HTML>){
		#	<td><p><a href="/tosei/hodohappyo/press/2020/10/10/01.html">新型コロナウイルスに関連した患者の発生（第895報）</a></p></td>
		next if(! /新型コロナウイルスに関連した患者の発生/);

		#dp::dp $_;
		chop;
		s/.*href=\"([^"]+)\".*/$1/;			# /tosei/hodohappyo/press/2020/10/10/01.html
		my $tg_url = "$base_url" . $_;
		my $tg_file = $_;
		$tg_file =~ s#/tosei/hodohappyo/##;
		$tg_file =~ s#/##g;
		$tg_file = "$PDF_DIR/$tg_file";

		#dp::dp join(", ", $_, $tg_file, $tg_url) . "\n";
		if(! (-e $tg_file)){
			my $cmd = "wget $tg_url -O $tg_file";
			#dp::dp $cmd . "\n";
			system($cmd);
			if(! (-e $tg_file)){
				dp::dp "Error at $cmd\n";
				exit 1;
			}
		}

		my $pdf_file = "";
		open(TGHTML, $tg_file) || die "cannot open $tg_file";
		while(<TGHTML>){ 
			#<a href="/tosei/hodohappyo/press/2020/10/10/documents/01_00.pdf" class="icon_pdf">別紙（PDF：807KB）</a>のとおり、お知らせします。</p>
			if(/.pdf".*別紙（PDF：/){
				#dp::dp $_;

				chop;
				s/.*href=\"([^"]+)\".*/$1/;			# /tosei/hodohappyo/press/2020/10/10/documents/01_00.pdf
				my $tg_url = $base_url . $_;
				$pdf_file = $_;
				$pdf_file =~ s#/tosei/hodohappyo/##;
				$pdf_file =~ s#/##g;
				$pdf_file = "$PDF_DIR/$pdf_file";
				if(! (-e $pdf_file)){
					my $cmd = "wget $tg_url -O $pdf_file";
					dp::dp $cmd;
					system($cmd);
				}
				
				if(! (-e "$pdf_file.txt")){
					my $cmd = "ps2ascii $pdf_file > $pdf_file.txt";
					dp::dp $cmd . "\n";
					system($cmd);
				}
				#dp::dp "######## $pdf_file\n";
				last;
			}
		}
		close(TGHTML);
	}
	close(HTML);

	my $pdf_dir = $tkopdf::PDF_DIR;
	opendir my $DIRH, "$pdf_dir" || die "Cannot open $pdf_dir";
	while(my $pdf_file = readdir($DIRH)){
		#dp::dp $pdf_file . "\n";
		if($pdf_file =~ /\.pdf$/){
			$pdf_file = "$pdf_dir/$pdf_file";
			#dp::dp $pdf_file . "\n"; #if($rec++ < 3);		# 3
			if(!(-e "$pdf_file.txt")){
					my $cmd = "ps2ascii $pdf_file > $pdf_file.txt";
					dp::dp $cmd . "\n";
					system($cmd);
			}
			#&pdf2data("$pdf_file.txt");
		}
	}

	return 

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

