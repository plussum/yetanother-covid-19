#
#   定型のCSVから、再生産数 のデータを生成
#
#       t                  *
#       +----+-------------+
#         lp       ip
#		潜伏期間 感染期間
#
#       R0 = ip * S[t+ip+lp] / sum(S[t+1..t+ip])
#
#       source      https://qiita.com/oki_mebarun/items/e68b34b604235b1f28a1
#					http://www.kantoko.com/?p=2102
#
package ern;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(ern);

use strict;
use warnings;
use Data::Dumper;
use	csvlib;
use dp;
use config;

my $DEBUG = 0;

sub	ern
{
	my ($p) = @_;

	my @IMF_DATA =();
	my @COUNTRY_LIST = ();
	my @DATE_LIST = ();
	my @RATE = ();
	my @TOTAL = ();
	my @AVERAGE = ();

	my $dlm = csvlib::valdef($p->{delimiter}, $config::DLM);
	my $lp = csvlib::valdef($p->{lp}, $config::RT_LP);	# 8 潜伏期間
	my $ip = csvlib::valdef($p->{ip}, $config::RT_IP);	# 5 感染期間
	my $avr = csvlib::valdef($p->{average_date}, 7);
	$DEBUG = csvlib::valdef($p->{DEBUG}, 0);

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
		$TOTAL[$ln] = shift(@w);
		$IMF_DATA[$ln] = [@w];

		$ln++;
	}
	close(IMF) ;
	my $country_number = $#COUNTRY_LIST;
	my $date_number = $#DATE_LIST;
	#dp::dp "IMF_DATGA: " . join(",", @{$IMF_DATA[0]}) . "\n";

	#
	#	平均に変換
	#
	for(my $cn = 0; $cn <= $#COUNTRY_LIST; $cn++){
		#print "RAW: " . join(",", @{$IMF_DATA[$cn]}) . "\n" if($COUNTRY_LIST[$cn] =~ /Japan/i);
		for(my $dt = 0; $dt < $date_number; $dt++){
			my $total = 0;
			my $half = int($avr / 2);
			my $from = $dt - $half;
			my $to = $dt + $avr - $half;
			# print "($from:$to)";
			# for(my $i = $from; $i <= $to; $i++){
			for(my $i = $from; $i < $to; $i++){
				#$total += ($i >= 0) ? $IMF_DATA[$cn][$i] : $IMF_DATA[$cn][0];
				if($i < 0){
					$total += $IMF_DATA[$cn][0];
				}
				elsif($i > $date_number){
					$total += $IMF_DATA[$cn][$date_number];
				}
				else {
					$total += $IMF_DATA[$cn][$i];
				}
			}
			my $a = int(1000 * $total / $avr) / 1000;
			$AVERAGE[$cn][$dt] = $a;
		}
		#print "AVR: " . join(",", @{$AVERAGE[$cn]}) . "\n" if($COUNTRY_LIST[$cn] =~ /Japan/i);
	}

	#
	#	再生産数の計算
	#
	my $rate_term = $date_number - $ip - $lp;
	open(RATE, "> " . $p->{output_file}) || die "Cannot create " . $p->{output_file} ;
	print RATE join($dlm, "Country", "Total", @DATE_LIST[0..($rate_term-1)]), "\n";
	for(my $cn = 0; $cn <= $#COUNTRY_LIST; $cn++){
		my $country = $COUNTRY_LIST[$cn];

		print RATE $country. $dlm . $TOTAL[$cn] . $dlm;
		for(my $dt = 0; $dt < $rate_term ; $dt++){
			my $ppre = $ip * $AVERAGE[$cn][$dt+$lp+$ip];
			my $pat = 0;
			for(my $dp = $dt + 1; $dp <= ($dt + $ip); $dp++){
				$pat += $AVERAGE[$cn][$dp];
			}
			# print "$country $dt: $ppre / $pat\n";
			if($pat > 0){
				$RATE[$cn][$dt] =  int(1000 * $ppre / $pat) / 1000;
			}
			else {
				$RATE[$cn][$dt] =  0;
			}
		}
		print RATE join($dlm, @{$RATE[$cn]}), "\n";
		#print "R0 : " . join(",", @{$RATE[$cn]}) . "\n" if($COUNTRY_LIST[$cn] =~ /Japan/i);
	}
	close(RATE);

	return ($#COUNTRY_LIST, $rate_term, $DATE_LIST[0], $DATE_LIST[$rate_term]);
}

1;
