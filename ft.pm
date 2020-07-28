#	
#	FT.pm
#
#	Finatial Times Likeな対数グラフを作るためのデータ生成
#
#	各国が$p->{thresh} を超えた日からの相対日で、データを生成
#
#	input_file
#	output_file
#	colum_number
#	record_number
#	start_day
#	last_day
#	thresh
#	average

package ft;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(ft);

use strict;
use warnings;
use Data::Dumper;
use	csvlib;
use dp;
use config;

my $DEBUG = 0;

sub	ft
{
	my ($p) = @_;

	my %FIRST = ();
	my $MIN_FIRST = 10**10 - 1;
#	my $THRESH_DAY = ($MODE eq "NC") ? 9 : 1;	# 10 : 1
#	my $THRESH_TOTAL = ($MODE eq "NC") ? 100 : 10;	# 10 : 1
	my @IMF_DATA =();
	my @COUNTRY_LIST = ();
	my @ABS = ();
	my @DATE_LIST = ();

	my $thresh = $p->{thresh};
	my $dlm = csvlib::valdef($p->{delimiter}, $config::DLM);
	my $avr_date = $p->{average_date};
#	$DEBUG = csvlib::valdef($p->{DEBUG}, 0);

	if(! defined $p->{thresh}){
		dp::dp "#### $thresh\n";
		return;
	}

	#
	#	Load input file
	#
	open(IMF, $p->{input_file}) || die "Cannot open " . $p->{input_file};
	$_ = <IMF>; chop;
	@DATE_LIST = split(/,/, $_);
	shift(@DATE_LIST);
	shift(@DATE_LIST);

	my $ln = 0;
	while(<IMF>){
		chop;
		my @w = (split(",", $_));
		$COUNTRY_LIST[$ln] = shift(@w);
		shift(@w);
		$IMF_DATA[$ln] = [@w];

		$ln++;
	}
	close(IMF) ;
	my $country_number = $#COUNTRY_LIST;
	my $date_number = $#DATE_LIST - $avr_date;
	#dp::dp Dumper $IMF_DATA[0] . "\n";
	#dp::dp "IMF_DATGA: " . join(",", @{$IMF_DATA[0]}) . "\n";

	#
	#	各国が閾値を超えた日を求める
	#
	#dp::dp "AVR_DATE: $avr_date" . "\n";	
	#dp::dp join($dlm, "Country", "Total", @COUNTRY_LIST), "\n" if($DEBUG);
	my $avr_start = 0; #int($avr_date / 2);
	my $avr_end = $avr_date; #$avr_date - $avr_start; 
	for(my $cn = 0; $cn <= $#COUNTRY_LIST; $cn++){
		my $country = $COUNTRY_LIST[$cn];

		#for(my $dt = 0; $dt <= $date_number; $dt++){					# 
		#	my $avr = csvlib::avr($IMF_DATA[$cn], $dt, $dt + $avr_date);
		for(my $dt = $avr_date; $dt <= ($date_number + $avr_date); $dt++){
			my $avr = csvlib::avr($IMF_DATA[$cn], $dt - $avr_date, $dt);
			$ABS[$cn][$dt] = int(0.999999 + $avr);		# 平均値のセット

			# 平均が閾値以上の場合、そこをその国の最初の日とする
			if($avr >= $thresh && !defined $FIRST{$country}){
				$FIRST{$country} = $dt;
				$MIN_FIRST = $dt if($dt < $MIN_FIRST);
				#dp::dp ">> FIRST $country: dt $dt: threash $thresh: avr $avr: avr_date $avr_date\n";
			}

			if(defined $FIRST{$country}){
				$ABS[$cn][$dt] = 0 if($avr < 1);	# logでエラーになるためと、NaNにセットするため
			}
		}
		dp::dp join(", ", $country, $FIRST{$country}, @{$ABS[$cn]}[0..$date_number]), "\n" x 2  if($ln < 3 && $DEBUG > 1);
	}

	#
	#	データをシフトした結果の最大レコード数を求める
	#
	my $ITEM_COUNT = 0;
	foreach my $country (@COUNTRY_LIST){
		next if(! $FIRST{$country});
		my $first = $FIRST{$country};
		my $ic = $date_number - $first;

		$ITEM_COUNT = $ic if($ic > $ITEM_COUNT);
	}
	my $end = $date_number - $MIN_FIRST;


	#
	#	Finatial Times形式のデータで出力
	#
	#dp::dp "OUTPUT_FILE: " .  $p->{output_file} . "\n";
	open(FT, "> " . $p->{output_file}) || die "Cannot create " . $p->{output_file};
	print FT join($dlm, "Country", "Total");
	for(my $i = 0; $i <= $ITEM_COUNT; $i++){
			print FT ",$i";
	}
	print FT "\n";
	for(my $cn = 0; $cn <= $#COUNTRY_LIST; $cn++){
		my $country = $COUNTRY_LIST[$cn];
		next if(! defined $FIRST{$country});

		my $first = $FIRST{$country};
		# dp::dp "FIRST: [$country:$first]\n";
		if(($DEBUG) && $country =~ /Japan/){
			dp::dp "###################\n";
			dp::dp "first: $country: $first,$end,$date_number,$MIN_FIRST  " ;
			dp::dp join($dlm, @{$ABS[$cn]}[$first..$end]), "\n";
			dp::dp join($dlm, @{$ABS[$cn]}), "\n";
		}
		#print FT $country. $dlm . $COUNTRY{$country}. $dlm;
		print FT $country. $dlm . ($date_number - $first) . $dlm;
		print FT join($dlm, @{$ABS[$cn]}[$first..$date_number]), "\n";
	}
	close(FT);
}

#
#	FT用の倍化指標を書くための gnuplotのコマンドを生成
#
sub	exp_guide
{
	my ($from, $to, $ymin, $scc) = @_;

	my $guide = "";
	for(my $d = $from; $d <= $to; $d++){
		my $base = 2**(1/$d);
		my $p10 = 0;
		my $b10 = 0;
		for($p10 = 6; $p10 < 100; $p10 += 1){
			$b10 = $base**$p10;
			last if($b10 >= $ymin);
		}
		for(; $p10 > 0; $p10 -= 0.001 ){
			$b10 = $base**$p10;

			last if($b10 <= $ymin);
		}
		#printf("[%d:%.3f:%3f]\n", $d, $p10, $b10);

		#$guide .= sprintf("(%.6f**(x+%.3f)) with lines dt \".\" title '%dday' $scc," , $base, $p10, $d);
		$guide .= sprintf("(%.6f**(x+%.3f)) with lines dt \".\" title '%dday'," , $base, $p10, $d);
	}
	$guide =~ s/,$//;

	return $guide;
}
1;
