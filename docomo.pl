#!/usr/bin/perl
#
#
#
#   SRC: https://mobaku.jp/covid-19/download/%E5%A2%97%E6%B8%9B%E7%8E%87%E4%B8%80%E8%A6%A7.csv
# エリア,メッシュ,各日15時時点増減率(%),2020/5/1
# 北海道,札幌駅,644142881,感染拡大前比,-58
# 北海道,札幌駅,644142881,緊急事態宣言前比,-54.4
# 北海道,札幌駅,644142881,前年同月比,-62.5
# 北海道,札幌駅,644142881,前日比,-2.2
# 北海道,すすきの,644142683,感染拡大前比,-50.6
# 北海道,すすきの,644142683,緊急事態宣言前比,-36
# 北海道,すすきの,644142683,前年同月比,-44.3
# 北海道,すすきの,644142683,前日比,1.3
# 北海道,新千歳空港,644115441,感染拡大前比,-69.6
#
#
#
use strict;
use warnings;
use utf8;
use Encode 'decode';
use Data::Dumper;
use config;
use csvlib;

binmode(STDOUT, ":utf8");

my $VERBOSE = 0;
my $END_OF_DATA = "###EOD###";
my $TERM_X_SIZE = 1000;
my $TERM_Y_SIZE = 350;

my @KIND_NAME = qw( 感染拡大前比 緊急事態宣言前比 前年同月比 前日比 );
my $DOWN_LOAD = 0;
my $DST_DLM = "\t";
my $AVR_DATE = 7;
my $MAIN_URL = "https://mobaku.jp/covid-19/";
my $SRC_URL = "https://mobaku.jp/covid-19/download/%E5%A2%97%E6%B8%9B%E7%8E%87%E4%B8%80%E8%A6%A7.csv";
my $SRC_CSVF =  "$config::WIN_PATH/docomo/docomo.csv.txt";
my $TITLE_HEAD = "NTTドコモ";

my $DST_FILE_TAG = "$config::PNG_PATH/docomo%s";
my $HTMLF_TAG    = "$config::HTML_PATH/docomo%s.html";
my $DST_FILE = sprintf($DST_FILE_TAG, "PP");
my $HTMLF = sprintf($HTMLF_TAG, "PP");

my @tokyo = (qw (東京都));
my @kanto = (qw (東京都 神奈川県 千葉県 埼玉県 茨木県 栃木県 群馬県));
my @kansai = (qw (大阪府 京都府 兵庫県 奈良県 和歌山県 滋賀県));
my @tokai = (qw (愛知県 岐阜県 三重県 静岡県));
my @touhoku = (qw (青森県 秋田県 岩手県 宮城県 山形県 福島県));
my @koushin = (qw (山梨県 長野県));
my @hokuriku = (qw (新潟県 富山県 石川県 福井県));
my @chugoku = (qw (鳥取県 島根県 岡山県 広島県 山口県));
my @shikoku = (qw (香川県 愛媛県 徳島県 高知県));
my @kyusyu = (qw (福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県 沖縄県));


my	@SUMMARY = (
	{name => "全国", target => []},
	{name => "関東", target => [@kanto]},
	{name => "関西", target => [@kansai]},
	{name => "東海", target => [@tokai]},
	{name => "東京", target => ["東京都"]},
	{name => "大阪", target => ["大阪府"]},
#	{name => "名古屋", target => ["愛知県"]},
);

my	@SUMMARY_ALL = (
	{name => "全国", target => []},
	{name => "関東", target => [@kanto]},
	{name => "関西", target => [@kansai]},
	{name => "東海", target => [@tokai]},
	{name => "北海道", target => ["北海道"]},
	{name => "東北", target => [@touhoku]},
	{name => "甲信", target => [@koushin]},
	{name => "北陸", target => [@hokuriku]},
	{name => "中国", target => [@chugoku]},
	{name => "四国", target => [@shikoku]},
	{name => "九州", target => [@kyusyu]},
);

my $TGN = 0;
my $TGK = $KIND_NAME[$TGN];
my %TARGET_KIND_LIST = ();

for(@ARGV){
	$TARGET_KIND_LIST{PP}++ if(/-PP/);	# Pre Pandemic
	$TARGET_KIND_LIST{PE}++ if(/-PE/);	# Pre Emergency
	$TARGET_KIND_LIST{PM}++ if(/-PM/);	# Previouse Month 
	$TARGET_KIND_LIST{PD}++ if(/-PD/);	# Previouse DAY 
	$DOWN_LOAD = 1 if(/-DL/);
	$VERBOSE = 1 if(/-V/);
	if(/-ALL/){
		$TARGET_KIND_LIST{PP} = 1;
		$TARGET_KIND_LIST{PE} = 1;
		$TARGET_KIND_LIST{PM} = 1;
		$TARGET_KIND_LIST{PD} = 1;
	}
}

my %TGNS = (PP => 0, PE => 1, PM => 2, PD => 3);


my @PARAMS = (
# 	{dst => $END_OF_DATA},
	{dst => "全国平均",  target_range => [1,999], graph => "AVR,RLAVR", target_area => [], exclusion_are => [],},

	{dst => "サマリ主要地域", target_range => [1,999], graph => "AVR,RLAVR", target_area => [], exclusion_are => [], summary => [@SUMMARY]},
	{dst => "サマリ主要地域 2m rlavr", target_range => [1,999], graph => "AVR,RLAVR", target_area => [], exclusion_are => [], summary => [@SUMMARY], start_date => -60},
	{dst => "サマリ主要地域 2m raw", target_range => [1,10], graph => "RAW", target_area => [], exclusion_are => [], summary => [@SUMMARY], start_date => -60},

	{dst => "サマリ全地域",   target_range => [1,999], graph => "AVR,RLAVR", target_area => [], exclusion_are => [], summary => [@SUMMARY_ALL]},

	{dst => "東京 ALL",  target_range => [1,20], graph => "RAW", target_area => [qw(東京都)], exclusion_are => [],},
	{dst => "東京 ALL",  target_range => [1,20], graph => "RLA", target_area => [qw(東京都)], exclusion_are => [],},
	{dst => "東京 ALL 2m",  target_range => [1,20], graph => "RAW", target_area => [qw(東京都)], exclusion_are => [], start_date => -60},
	{dst => "東京 ALL 2m",  target_range => [1,20], graph => "RLA", target_area => [qw(東京都)], exclusion_are => [], start_date => -60},

	{dst => "関東 Top10",  target_range => [1,10], graph => "RAW", target_area => [@kanto], exclusion_are => [],},
	{dst => "関東 Top10 2m",  target_range => [1,10], graph => "RAW", target_area => [@kanto], exclusion_are => [], start_date => -60},
	{dst => "関東 Top10",  target_range => [1,10], graph => "RLA", target_area => [@kanto], exclusion_are => [],},

#	{dst => "TokyoAvr",  target_range => [1,999], graph => "AVR", target_area => [@tokyo], exclusion_are => [],	},
#	{dst => "東京平均",  target_range => [1,999], graph => "AVR,RLAVR", target_area => [@tokyo], exclusion_are => [],},
#	{dst => "関東平均",  target_range => [1,999], graph => "AVR,RLAVR", target_area => [@kanto], exclusion_are => [],},
#	{dst => "関西平均",  target_range => [1,999], graph => "AVR,RLAVR", target_area => [@kansai], exclusion_are => [],},
#	{dst => "東海平均",  target_range => [1,999], graph => "AVR,RLAVR", target_area => [@tokai], exclusion_are => [],},

	{dst => "全国 top10",  target_range => [1,10], graph => "RLA", target_area => [], exclusion_are => [],},
	{dst => "全国 top11-20", target_range => [11,20], graph => "RLA", target_area => [], exclusion_are => []},
	{dst => "全国 top21-30", target_range => [21,30], graph => "RLA", target_area => [], exclusion_are => []},
	{dst => "全国 top31-40", target_range => [31,40], graph => "RLA", target_area => [], exclusion_are => []},
	{dst => "全国 top41-50", target_range => [41,50], graph => "RLA", target_area => [], exclusion_are => []},

	{dst => "全国 top10",  target_range => [1,10], graph => "RAW", target_area => [], exclusion_are => [],	},
	{dst => "全国 top10 2m",  target_range => [1,10], graph => "RAW", target_area => [], exclusion_are => [],	start_date => -60},
	{dst => "全国 top11-20", target_range => [11,20], graph => "RAW", target_area => [], exclusion_are => [],},
	{dst => "全国 top21-30", target_range => [21,30], graph => "RAW", target_area => [], exclusion_are => [],},
	{dst => "全国 top31-40", target_range => [31,40], graph => "RAW", target_area => [], exclusion_are => [],},
	{dst => "全国 top41-50", target_range => [41,50], graph => "RAW", target_area => [], exclusion_are => [],},


#	{	
#		src => "$SRC_CSVF",
#		dst => "tokyo",
#		target_area => [qw (東京都)],
#		exclusion_are => [],	# [qw (立川 羽田空港)],
#		target_kind =>   [$KIND_NAME[0]],
#		dt_start => "0000-00-00",
#		target_range => [0,9999],
#	},
#
#	{	
#		src => "$SRC_CSVF",
#		dst => "kanto",
#		target_area => [qw (神奈川 千葉 埼玉)],
##		exclusion_are => [],
#		target_kind =>   [$KIND_NAME[0]],
#		dt_start => "0000-00-00",
#		target_range => [0,9999],
#	},

);

my @OUTPUT_FILES = ();


#
#	Down Load CSV 
#


if($DOWN_LOAD){
	my $wget = "wget $SRC_URL -O $SRC_CSVF";
	dp::dp $wget ."\n" if($VERBOSE);
	system($wget);
}

#
#	Lpad CSV File
#
my %DOCOMO = ();
my %AREA = ();
my %KIND = ();

open(FD, $SRC_CSVF) || die "Cannot open $SRC_CSVF";
my $line = <FD>;
chop $line;
$line = decode('Shift_JIS', $line);
my @LABEL = split(/,/, $line);
my $FIRST_DATE = $LABEL[3];
my $LAST_DATE = $LABEL[$#LABEL];

my $ln = 0;
while(<FD>){
	#last if($ln++ > 50);
	chop;
	my $line = decode('Shift_JIS', $_);
	my ($area, $mesh, $kind, @data) = split(/,/, $line);

	my $k = join(",", $area, $kind);
	$DOCOMO{$k} = join(",", @data);
	$AREA{$area}++;
	$KIND{$kind}++;

	#dp::dp join(",", $area, $mesh, $kind) . "\n";
}
close(FD);

#
#
#
for(my $i = 0; $i < 3; $i++){
	shift(@LABEL);
}
#dp::dp join(",", "# " . $TGK, @LABEL) . "\n";

#
#	MAIN LOOP
#
foreach my $TG (sort keys %TARGET_KIND_LIST){
	@OUTPUT_FILES = ();
	$TGN = $TGNS{$TG};
	$TGK = $KIND_NAME[$TGN];

	$DST_FILE = sprintf($DST_FILE_TAG, $TG);
	$HTMLF    = sprintf($HTMLF_TAG, $TG);
	dp::dp "##### $TG, $TGN, $TGK, $DST_FILE, $HTMLF" . "\n" if($VERBOSE);

	foreach my $param (@PARAMS){
		last if($param->{dst} eq $END_OF_DATA);

		push(@OUTPUT_FILES, &csv2graph($param));
	}
	&gen_html($HTMLF, @OUTPUT_FILES);
}

exit 0;

#
#
#
sub	gen_html
{
	my ($htmlf, @output_files) = @_;

	my $CSS = $config::CSS;
	my $class = $config::CLASS;

	open(HTML, ">$htmlf") || die "Cannot create file $htmlf";
	binmode(HTML, ":utf8");

	print HTML "<HTML>\n";
	print HTML "<HEAD>\n";
	print HTML "<TITLE> DOCOMO DATA </TITLE>\n";
	print HTML $CSS;
	print HTML "</HEAD>\n";
	print HTML "<BODY>\n";
	my $now = csvlib::ut2d4(time, "/") . " " . csvlib::ut2t(time, ":");

	print HTML "<h3>データソース： <a href=\"$MAIN_URL\" target=\"blank\"> NTTドコモ モバイル空間統計　新型ウイルス感染症対策特設サイト</a></h3>\n";
	#print HTML "<a href=\"$MAIN_URL\" target =\"blank\">$MAIN_URL</a>\n";

	foreach my $file (@output_files){
		my $html_path = $file;
		$html_path =~ s#.*/#../PNG/#;

		print HTML "<span class=\"c\">$now</span><br>\n";
		print HTML "<img src=\"$html_path.png\">\n";
		print HTML "<br>\n";
		print HTML "<span $class> <a href=\"$SRC_URL\" target=\"blank\"> Data Source (CSV) </a></span>\n";
		print HTML "<hr>\n";
	
		print HTML "<span $class>";

		my @refs = (join(":", "PNG", "$html_path.png"),
					join(":", "CSV", "$html_path-plot.csv.txt"),
					join(":", "PLT", "$html_path-plot.txt"),
		);
		foreach my $r (@refs){
			my ($tag, $path) = split(":", $r);
			print HTML "$tag:<a href=\"$path\" target=\"blank\">$path</a>\n"; 
		}
		print HTML "<br>\n" ;
		print HTML "</span>\n";
		print HTML "<br><hr>\n\n";
	}
	print HTML "</BODY>\n";
	print HTML "</HTML>\n";
	close(HTML);
}


sub	csv2graph
{
	my($param) = @_;

	my @MATRIX = ();
	$MATRIX[0] = [ "# " . $TGK, @LABEL];

	dp::dp "DOCOMO  [$TGK] " . $param->{dst} . " " . $param->{graph} . "\n" if($VERBOSE);
	#dp::dp join(",", @{$param->{target_area}}) . "\n";
	my $rn = 1;
	my $tga = $param->{target_area};
	my $exc = $param->{exclusion_are};
	my $start_date = $param->{start_date} // $FIRST_DATE;
	my $end_date = $param->{end_date} // "$LAST_DATE";

	#dp::dp "#### " . ($param->{start_date} // "--") . " / " . ($param->{end_date} // "--") . "($start_date, $end_date)\n";

	my $dst = $param->{dst};
	$dst =~ s/[ \/]/_/g;

	foreach my $area (sort keys %AREA){
		#dp::dp "## tga " . @$tga . "\n";
		next if(@$tga > 0 && csvlib::search_list($area, @$tga) eq "");
		next if(@$exc > 0 && csvlib::search_list($area, @$exc));
		#dp::dp ">>> $area \n";

		foreach my $kind (sort keys %KIND){
			next if($kind ne $TGK);
			#dp::dp "### $kind \n";

			my $k = join(",", $area, $kind);
			next if(! defined $DOCOMO{$k});

			my @w = split(",", $DOCOMO{$k});
			#dp::dp join(",",  $area, $kind,  @w) . "\n";
			$MATRIX[$rn++] = [$area, @w];
		}
	}

	if($rn <= 1){
		my $errmes = sprintf("No data found in this parameter [%s][%s][%s]" ,
			join(",", @{$param->{target_area}}),
			join(",", @{$param->{exclusion_are}}),
			join(",", @{$param->{target_kind}})
		);
		dp::dp $errmes . "\n"; 
		next;
	}

	#
	#
	#
	my @matrix = ();
	my $p = {};
	my $dst_file = "";

	my ($col, $row) = csvlib::matrix_convert(\@MATRIX, \@matrix);
	if($param->{graph} eq "RAW"){
		my @matrix_sorted = ();
		csvlib::maratix_sort_max(\@matrix, \@matrix_sorted);
		$dst_file = join("_", $DST_FILE, $dst);
		$p = {
			datap => \@matrix_sorted,
			dst_file => $dst_file,
			title => "$TITLE_HEAD [$TGK] " . $param->{dst} . " ",
			target_range => $param->{target_range},
			start_date => $start_date,
			end_date => $end_date,
		};
		&graph($p);
	}


	#
	#
	#
	if($param->{graph} eq "RLA"){
		my @matrix_avr = ();
		my @matrix_sorted = ();
		csvlib::matrix_roling_average(\@matrix, \@matrix_avr, $AVR_DATE);
		csvlib::maratix_sort_max(\@matrix_avr, \@matrix_sorted);
		$dst_file = $DST_FILE . $dst . "rlavr__maxval";
		$p = {
			datap => \@matrix_sorted,
			dst_file => $dst_file,
			title => "$TITLE_HEAD  [$TGK] " . $param->{dst} . " (rlavr-$AVR_DATE)",
			target_range => $param->{target_range},
			start_date => $start_date,
			end_date => $end_date,
		};
		&graph($p);
	}

	#
	#
	#
	if($param->{graph} =~ /AVR/){
		my @matrix_avr = ();
		my @matrix_rl_avr = ();
		my @matrix_sorted = ();
		my $matrixp = \@matrix_avr;
		my $title = "$TITLE_HEAD [$TGK] " . $param->{dst} . " (avr)";  

		my $sp = $param->{summary};
		#if($sp){
		#	dp::dp $sp, @$sp . "\n";
		#	dp::dp join(",", @$sp) . "\n";
		#}
	
		csvlib::matrix_average(\@matrix, \@matrix_avr, $param->{summary});
		$dst_file = $DST_FILE . $dst . "avr";

		if($param->{graph} =~ /RLAVR/){
			#dp::dp "Roling\n";
			$dst_file .= "rl";
			$title .= " (rlavr-$AVR_DATE)";

			csvlib::matrix_roling_average(\@matrix_avr, \@matrix_rl_avr, $AVR_DATE) ;
			csvlib::maratix_sort_max(\@matrix_rl_avr, \@matrix_sorted);
			$matrixp = \@matrix_sorted;
		}
		
		$p = {
			datap => $matrixp,
			dst_file => $dst_file,
			title => $title,
			target_range => $param->{target_range},
			start_date => $start_date,
			end_date => $end_date,
		};
		#dp::dp "#### ($start_date, $end_date)\n";
		&graph($p);
	}
	dp::dp $dst_file . "\n" if($VERBOSE);
	return ($dst_file);
}


sub	graph
{
	my ($p) = @_;

	my $datap = $p->{datap};
	my $col = @{$p->{datap}[0]};
	my $row = @{$p->{datap}};

	my $title = $p->{title} . "($LAST_DATE)";
	my @target_range = (0, 99999);
	@target_range = (@{$p->{target_range}}) if(defined $p->{target_range});
	#dp::dp "#### " . join(",", "[" . $p->{target_range}[0] . "]", @target_range) . "\n";

	my $dst_file = $p->{dst_file};
	my $csvf = $dst_file .  "-plot.csv.txt";
	my $pngf = $dst_file .  ".png";
	my $plotf = $dst_file . "-plot.txt";

	my $dlm = $DST_DLM;
	my $ylabel = "%";

	my $start_date = $p->{start_date} // "NONE";
	my $end_date = $p->{end_date} // "NONE";

	#dp::dp "#### $start_date -> $end_date\n";
	if(! ($start_date =~ /\//)){
		if($start_date < 0){
			my $sn = $#LABEL + $start_date;
			$sn = 3 if($sn < 3);
			$start_date = $LABEL[$sn];
			#dp::dp "---- $start_date : $sn\n";
		}
	}		

	my $start_ut = csvlib::ymds2tm($start_date);
	my $end_ut = csvlib::ymds2tm($end_date);
	my $dates = ($end_ut - $start_ut) / (60 * 60 * 24);
	my $xtics = 60 * 60 * 24 * 7;
	if($dates < 93){
		$xtics = 1 * 60 * 60 * 24;
	}
	elsif($dates < 120){
		$xtics = 2 * 60 * 60 * 24;
	}


	#
	#	Generate CSV Data
	#
	#dp::dp "row:$row col:$col\n";
	open(CSV, "> $csvf") || die "Cannot create $csvf";
	binmode(CSV, ":utf8");
	for(my $r = 0; $r < $row; $r++){
		#dp::dp    join($DST_DLM, @{$datap->[$r]}) . "\n";
		print CSV join($DST_DLM, @{$datap->[$r]}) . "\n";
	}
	close(CSV);

	#
	#	Draw Graph
	#
	my $PARAMS = << "_EOD_";
set datafile separator '$dlm'
set xtics rotate by -90
set xdata time
set timefmt '%Y/%m/%d'
set format x '%m/%d'
set mxtics 2
set mytics 2
#set grid xtics ytics mxtics mytics
set key below
set title '$title' font "IPAexゴシック,12" enhanced
#set xlabel 'date'
set ylabel '$ylabel'
#
set xtics $xtics
set xrange ['$start_date':'$end_date']
set grid
set terminal pngcairo size $TERM_X_SIZE, $TERM_Y_SIZE font "IPAexゴシック,8" enhanced
set output '$pngf'
plot #PLOT_PARAM#
exit
_EOD_

	my @p= ();
	my $pn = 0;
	for(my $i = 1; $i < $col; $i++){
		next if($i < $target_range[0] || $i > $target_range[1]);
		#dp::dp join(",", $i, @target_range) . "\n";

		$pn++;
		push(@p, sprintf("'%s' using 1:%d with lines title '$i:%s' linewidth %d ", 
						$csvf, $i + 1, $datap->[0][$i], ($pn < 7) ? 2 : 1)
		);
	}
	push(@p, "0 with lines dt '-' title 'base line'");
	my $plot = join(",", @p);
	$PARAMS =~ s/#PLOT_PARAM#/$plot/;

	open(PLOT, ">$plotf") || die "cannto create $plotf";
	binmode(PLOT, ":utf8");
	print PLOT $PARAMS;
	close(PLOT);

	#dp::dp $csvf. "\n";
	#dp::dp $PARAMS;

	system("gnuplot $plotf");

}

sub	valdef
{
	my($v, $d) = @_;

	$d = 0 if(!defined $d);	
	$v = $d if(!defined $v);
	return $v;
}

