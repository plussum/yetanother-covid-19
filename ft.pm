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

	my $average_day = $p->{average_day};
	my $thresh = $p->{thresh};
	my $dlm = csvlib::valdef($p->{delimiter}, ",");
	my $avr_day = $p->{average_day};
	$DEBUG = csvlib::valdef($p->{DEBUG}, 0);

	dp::dp "#### $thresh\n";

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
	my $date_number = $#DATE_LIST;
	print Dumper $IMF_DATA[0] . "\n";
	#dp::dp "IMF_DATGA: " . join(",", @{$IMF_DATA[0]}) . "\n";

	#
	#	各国が閾値を超えた日を求める
	#
	print join($dlm, "Country", "Total", @COUNTRY_LIST), "\n" if($DEBUG);
	for(my $cn = 0; $cn <= $#COUNTRY_LIST; $cn++){
		my $country = $COUNTRY_LIST[$cn];

		for(my $dt = 0; $dt <= $date_number; $dt++){
			my $dtn = $IMF_DATA[$cn][$dt]; 		#	平均を求める
			for(my $i = $dt - $avr_day + 1; $i < $dt; $i++){
				my $dtnw = ($i >= 0 ? $IMF_DATA[$cn][$i]: $IMF_DATA[$cn][$dt]);
				$dtn += $dtnw;
			}
			my $avr = int(0.999999 + $dtn / $avr_day);
			$ABS[$cn][$dt] = $avr;		# 平均値のセット

			# 平均が閾値以上の場合、そこをその国の最初の日とする
			if($avr >= $thresh && !defined $FIRST{$country}){
				$FIRST{$country} = $dt;
				$MIN_FIRST = $dt if($dt < $MIN_FIRST);
				#dp::dp ">> FIRST $country: dt $dt: threash $thresh: avr $avr: avr_day $avr_day\n";
			}

			if(defined $FIRST{$country}){
				$ABS[$cn][$dt] = 0 if($avr < 1);	# たぶん、NaNにしたい。。不明
			}
		}
		print join(", ", $country, @{$ABS[$cn]}[0..$date_number]), "\n" x 2  if($ln < 3 && $DEBUG > 1);
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
	open(FT, "> " . $p->{output_file}) || die "Cannot create " . $p->{output_file};
	print FT join($dlm, "Country", "Total");
	for(my $i = 0; $i <= $ITEM_COUNT; $i++){
			print FT ",$i";
	}
	print FT "\n";
	for(my $cn = 0; $cn <= $#COUNTRY_LIST; $cn++){
		my $country = $COUNTRY_LIST[$cn];
		next if(! $FIRST{$country});

		my $first = $FIRST{$country};
		# dp::dp "FIRST: [$country:$first]\n";
		if($country =~ /Japan/){
			print "first: $country: $first,$end,$date_number,$MIN_FIRST  " ;
			print join($dlm, @{$ABS[$cn]}[$first..$end]), "\n";
			print join($dlm, @{$ABS[$cn]}), "\n";
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

