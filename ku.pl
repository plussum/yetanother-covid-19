#!/usr/bin/perl
#

#
use strict;
use warnings;
use config;
use csvlib;
use dp;

my $DL = "";
my $DLM = "\t";

my $index = "cln202002_kns01_me01.html";
my $base_url = "https://www.city.shinjuku.lg.jp";
my $index_url = "$base_url/kusei/$index";
my $pdf_dir = "content";


my %CONFIRMED = ();
my %DATE_FLAG = ();
my %KU_FLAG = ();
my $data_dir = "tokyo-ku";

#&utf2num("３0");
#&utf2num("3０");
#&utf2num("３1");
#&utf2num("2９");
#exit;
my @PARAMS = (
    {	
		#src => "$TKY_DIR/data/positive_rate.json",
		dst => "tky_ku",
		title => "Tokyo-ku Positive Rate",
		ylabel => "confiermed",
		plot => [
			{colm => '($2+$3)', axis => "x1y1", graph => "boxes fill",  item_title => ""},
			{colm => '2', axis => "x1y1", graph => "boxes fill",  item_title => ""},
			{colm => '4', axis => "x1y2", graph => "lines linewidth 2",  item_title => ""},
		],
	},
);
my $p = $PARAMS[0];

my $avr_date = 0;
my $dst = $p->{dst} . "_avr$avr_date";
my $pngf = $config::PNG_PATH . "/$dst.png";
my $csvf = $config::CSV_PATH . "/$dst.csv.txt";
my $plotf = $config::PNG_PATH . "/$dst-plot.txt";

chdir($data_dir);

system ("wget $index_url") if($DL);


my $rec = 0;
open(HTML, $index) || die "cannot open $index";
while(<HTML>){
	if(/都内の新型コロナウイルス関連患者数等/){
		chop;
		#print ;
		s#.*a href="/(content/[0-9]+\.pdf)".*#$1#;
		my $pdf = $_;
		my $pdf_url = "$base_url/$pdf";
		#dp::dp $pdf_url . "\n";
		if(! -e $pdf){
			chdir("$pdf_dir") || die "cannto go dir $pdf_dir";
			system("wget $pdf_url");
			chdir("..");
		}
		#dp::dp "ps2ascii $pdf > $pdf.txt\n";
		system("ps2ascii $pdf > $pdf.txt") if(!-e "$pdf.txt"); 
		&pdf2data("$pdf.txt");

		#last if($rec++ > 3);
	}
}
close(HTML);

open(CSV, "> $csvf") || die "cannto create $csvf";
my @KUS = (sort {$KU_FLAG{$b} <=> $KU_FLAG{$a}} keys %KU_FLAG);
my @DATES = (sort keys %DATE_FLAG);

print CSV join($DLM, "#", @KUS) . "\n";
my $no = 1;
foreach my $date (@DATES){
	my @nn = ();
	foreach my $ku (@KUS){
		push(@nn, $CONFIRMED{$date}{$ku});
	}
	print CSV join($DLM, $date, @nn) . "\n";
}
close(CSV);


my $first_date = $DATES[0];
my $last_date = $DATES[$#DATES];
my $gpara = {
	csvf => $csvf,
	pngf => $pngf,
	plotf => $plotf,
	first_date => $first_date, 
	last_date   => $last_date,
	xtics => 60 * 60 * 24 * 7,
	dlm => $DLM,
	items => \@KUS,
	p => $p,
	range => "1,10",
};	
&graph($gpara);

exit 0;

sub	graph
{
	my ($gp) = @_;

	my $p = $gp->{p};
	my $csvf = $gp->{csvf};
	my $pngf = $gp->{pngf};
	my $plotf = $gp->{plotf};
	my $last_date = $gp->{last_date};
	my $first_date = $gp->{first_date};
	my $xrange = sprintf("['%s':'%s']", $first_date, $last_date);
	my $xtics = $gp->{xtics};
	my $items = $gp->{items};

	my $dlm = $gp->{dlm};
	my $title = $p->{title} . "($last_date)";
	my $ylabel = $p->{ylabel};
	my ($start, $end) = split(/,/, $gp->{range});

	my $PARAMS = << "_EOD_";
set datafile separator '$dlm'
set style fill solid 0.2
set xtics rotate by -90
set xdata time
set timefmt '%m/%d'
set format x '%m/%d'
set xrange $xrange
set mxtics 2
set mytics 2
set grid xtics ytics mxtics mytics
set key below
set title '$title' font "IPAexゴシック,12" enhanced
#set xlabel 'date'
set ylabel '$ylabel'
#
set xtics $xtics
set terminal pngcairo size 1000, 300 font "IPAexゴシック,8" enhanced
set y2tics
set output '$pngf'
plot #PLOT_PARAM#
exit
_EOD_

	my @p= ();
	#dp::dp join(",", $item_number, @$item_names) . ":\n";
	my $dn = 0;
	for(my $i = $start; $i <= $end; $i++){
		my $plp = $p->{plot}[$i-1];
		#dp::dp "plp :\n " . Dumper $plp;
		my $s = sprintf("'%s' using 1:%s with lines lw %d title '%s'", 
				$csvf, $i+1, (($dn < 7) ? 2 : 1), $items->[$i-1]
		);
		push(@p, $s);
		$dn++;
	}
	my $plot = join(",", @p);
	$PARAMS =~ s/#PLOT_PARAM#/$plot/;

	open(PLOT, ">$plotf") || die "cannto create $plotf";
	print PLOT $PARAMS;
	close(PLOT);

	#dp::dp $csvf. "\n";
	#dp::dp $PARAMS;

	system("gnuplot $plotf");
}

sub	valdef
{
	my($v) = @_;

	$v = 0 if(!defined $v);
	return $v;
}

#     【参考】区市町村別患者数（都内発生分）　（７月８日時点の累計値）
#        千代田 中央         港     新宿     文京    台東     墨田     江東    品川     目黒     大田
#         49     135   390    900    112   195    171    268   208    191    284
#        世田谷 渋谷 中野 杉並 豊島                    北     荒川     板橋    練馬     足立     葛飾
#         576    238   339    314    272   130    108    225   351    197    152
#        江戸川 八王子 立川 武蔵野 三鷹 青梅 府中 昭島 調布 町田 小金井
#         184    60     26    28     42     10    84     13     39     66    39
#         小平     日野 東村山 国分寺 国立 福生 狛江 東大和 清瀬 東久留米武蔵村山
#         32     22     21    17      8     3     28      8     18     20     2
#         多摩     稲城    羽村 あきる野 西東京 瑞穂 日の出 檜原 奥多摩 大島 利島
#         40     14     5     11     63     2      1      0     0      0      0
#         新島 神津島 三宅 御蔵島 八丈 青ヶ島 小笠原 都外 調査中
#          0      0     0      1      0     0      0     313    23
my @KU = (
"       千代田 中央         港     新宿     文京    台東     墨田     江東    品川     目黒     大田",
"        世田谷 渋谷 中野 杉並 豊島                    北     荒川     板橋    練馬     足立     葛飾",
"         小平     日野 東村山 国分寺 国立 福生 狛江 東大和 清瀬 東久留米武蔵村山",
"         新島 神津島 三宅 御蔵島 八丈 青ヶ島 小笠原 都外 調査中",
);


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
	#dp::dp "\n";
	close(PDF);
	#exit;
}

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
		

