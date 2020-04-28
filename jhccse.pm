#
#	Johns Hopkins CCSEを処理するためのライブラリ
#
#
#
package jhccse;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(jhccse);

use strict;
use warnings;
use dp;
use Data::Dumper;

#
#	$input_file
#	$output_file
#	$population		人口比の場合は１
#
#	/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv
#	/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv

my $DEBUG = 1;


#
#	Open File
#
sub	jhccse
{
	my ($p) = @_;

	my %CNT_POP = ();
	if($p->{aggr_mode} eq "POP"){
		csvlib::cnt_pop(\%CNT_POP);
		dp::dp( "###### $p->{aggr_mode}\n") if($DEBUG > 1);
	}

	my $DLM = csvlib::valdefs($p->{delimiter} , ",");
	
	#
	#	jh ccse data to csv
	#
	open(FD, $p->{input_file}) || die "Cannot open " . $p->{input_file} . "\n";
	
	#
	#	1行目：日付の読み込み
	#
	$_ = <FD>; chop;
	my @COL = ();
	my @w = split(/,/, $_);
	
	for (@w[4..$#w]){
		#s#/[0-9]+$##;		# Date Format 2/10/20 -> 2/10 
		my ($m, $d, $y) = split(/\//, $_);
		#dp::dp "[$_]($y,$m,$d)";
		#$_ = sprintf("%04d/%02d/%02d", $y + 2000, $m, $d);
		$_ = sprintf("%02d/%02d", $m, $d);
		
		push(@COL, $_);
	}
	my $ITEMS = $#COL;		# $ITEMS はCSVのカラム数（全数）
	my $DT_S = 4;			# データカラムの最初
	for(my $i = 0; $i < $DT_S; $i++){
		shift(@COL);		# カラム名（日付）の0から日付けが始まるようにシフト
	}
	my $DT_E = $#COL;		# データの最終カラム

	#
	#	データの読み込み CSV File -> @DATA[][]
	#
	my @DATA = ();
	my $RN = 0;								# レコード数
	while(<FD>){
		dp::dp $_ if($DEBUG > 2);
		if(/"/){
			s/"([^",]+),([^"]+)"/$1-$2/;	# データ中の,を- ,"aa,bb", -> aa-bb 
		}
		my @LINE = split(/,/, $_);
		for(my $cn = 0; $cn <= $ITEMS; $cn++){
			$DATA[$RN][$cn] = $LINE[$cn];
		}
		$RN++;
	}
	close(FD);

	for(; $DT_E > $DT_S; $DT_E--){
		last if(defined $DATA[1][$DT_E]);	# 最終カラムが日付だけのことがあるため
	}

	#
	#	データ @DATA[][] から、国ごとに集計したデータを作る
	#		元データは、国を複数のリージョンに分けているところがある
	#		ここでは、国ごとのデータを見たいため、国ごとにマージしている
	#
	my $CR = 1; 							# "Country/Region";
	my %COUNTRY = ();
	my %COUNT = ();
	my %COUNT_D = ();
	my %NO_POP = ();

	for(my $rn = 0; $rn < $RN; $rn++){
		my $country = $DATA[$rn][$CR];
		dp::dp "[$rn:$RN:$country]\n" if($DEBUG > 1);
		for(my $dt = $DT_S; $dt <= $ITEMS; $dt++){
			$COUNT{$country}[$dt-$DT_S] += $DATA[$rn][$dt];		# 複数のレコードになっている国があるので += 
		}
		$COUNTRY{$country} += $DATA[$rn][$DT_E];
	}
	my $cn =  keys %COUNTRY;
	dp::dp( "country: " , join(", ", $cn),"\n") if($DEBUG > 1);


	#
	#	日次csvの作成 累計値から日次への変換
	#
	open(CSV, "> $p->{output_file}") || die "Cannot create " . $p->{output_file} . "\n";

	dp::dp (join($DLM, "Country", "Total", @COL), "\n") if($DEBUG > 1);
	print CSV join($DLM, "Country", "Total", @COL), "\n" ;

	my $ln = 0;
	foreach my $country (sort {$COUNTRY{$b} <=> $COUNTRY{$a}} keys %COUNTRY){	# 累計の降順ソート
		dp::dp( join($DLM, $country, $COUNTRY{$country}), "\n") if($DEBUG > 1);
		next if($country =~ /Diamond Princess/ || $country =~ /MS Zaandam/);	# 国以外のデータを除外
		next if(! $country || !$country =~ /^[A-Za-z]/);						# エラーデータの除外

		dp::dp (join(", ", $country, $COUNTRY{$country}, @{$COUNT{$country}}[0..$#COL]), "\n")  if($ln < 3 && $DEBUG > 1);

		for(my $dt = 0; $dt <= $#COL; $dt++){
			my $dtn = $COUNT{$country}[$dt] - ($dt == 0 ? 0 : $COUNT{$country}[$dt-1]);	# 累計 -> 日次
			if($p->{aggr_mode} eq "POP"){															# 人口比に置き換え
				if(defined $CNT_POP{$country}){
					#dp::dp "[" . $p->{aggr_mode} . "]";
					$dtn = $dtn / ($CNT_POP{$country} / (1000*1000));			# 100万人当たり
				}
				else {
					$NO_POP{$country}++;										# エラー。国名が見つからない
					$dtn = 10**20 - 1;											# 大きな値をセットして、上位に来ないようにする
				}
			}
			$COUNT_D{$country}[$dt] = $dtn;										# データを COUNT_D セット
		}
		#print CSV $country. $DLM . $COUNTRY{$country}. $DLM;					# 国、トータル
		print CSV join($DLM, $country, $COUNTRY{$country}, @{$COUNT_D{$country}}), "\n";						# 1行分（国）のデータの出力
		dp::dp (join(", ", $country, $COUNTRY{$country}, @{$COUNT_D{$country}}[0..$#COL]), "\n" x 2 ) if($ln < 3 && $DEBUG > 1);
		$ln++;
	}
	close(CSV);

	#
	#	人口比の場合に、未登録の国を出力
	#
	foreach my $c (sort %NO_POP){
		print STDERR "#### Nopoulatopn [$c], [$NO_POP{$c}]\n";
	}

	#
	#	戻り値: カラム数、レコード数、最初の日付け、最後の日付
	#
	return ($DT_E, $RN, $COL[0], $COL[$#COL]);
}

1;
