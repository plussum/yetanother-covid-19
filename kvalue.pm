#
#	K値
#
#	・X=累計感染者数
#	・Y=1週間前の累計感染者数
#
#	とおき、“画期的な”指標である「K値」を
#
#	・K=(X-Y)/X=1-Y/X
#
#		source		https://note.com/yagena/n/n22215ecd9175
#
#	input_file
#	output_file
#	colum_number
#	record_number
#	start_day
#	last_day
#	thresh
#	average

package kvalue;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(kvalue);

use strict;
use warnings;
use Data::Dumper;
use	csvlib;
use dp;

my $DEBUG = 0;

sub	kvalue
{
	my ($p) = @_;

	my @IMF_DATA =();
	my @TOTAL = ();
	my @COUNTRY_LIST = ();
	my @DATE_LIST = ();
	my @KV = ();
	my $TERM = 7;

	my $dlm = csvlib::valdef($p->{delimiter}, ",");

	#
	#	Load input file
	#
	#dp::dp "INPUT FILE: " . $p->{input_file} . "\n";
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
		#dp::dp join(",", @w) . "\n" if($COUNTRY_LIST[$ln] =~ /Japan/);
		for(my $dt = 0; $dt <= $#w; $dt++){
			$IMF_DATA[$ln][$dt] = (($dt > 0) ? $IMF_DATA[$ln][$dt-1] : 0) + $w[$dt];
		}
		#$IMF_DATA[$ln] = [@w];
		#dp::dp join(",", @{$IMF_DATA[$ln]}) . "\n" if($COUNTRY_LIST[$ln] =~ /Japan/);

		$ln++;
	}
	close(IMF) ;
	my $country_number = $#COUNTRY_LIST;
	my $date_number = $#DATE_LIST;

	#
	#	K値の計算
	#
	#dp::dp "OUTPUT_FILE: " . $p->{output_file} . "\n";
	open(KV, "> " . $p->{output_file}) || die "Cannot create " . $p->{output_file} ;
	print KV join($dlm, "Country", "Total", @DATE_LIST[$TERM..$date_number]), "\n";
	for(my $cn = 0; $cn <= $#COUNTRY_LIST; $cn++){
		my $country = $COUNTRY_LIST[$cn];

		print KV $country. $dlm . $TOTAL[$cn] . $dlm;
		for(my $dt = $TERM; $dt <= $date_number ; $dt++){
			my $X = csvlib::valdef($IMF_DATA[$cn][$dt], 0);
			my $Y = csvlib::valdef($IMF_DATA[$cn][$dt-$TERM], 0);

			my $kv = 0;
			$kv = 1 - $Y/$X if($X > 0);
			
			#dp::dp join(",", $country, $dt, $kv, $X, $Y) . "\n" if($country =~ /Japan/);
			$KV[$cn][$dt-$TERM] = $kv;
		}
		print KV join($dlm, @{$KV[$cn]}), "\n";
		#dp::dp "KV : " . join(",", @{$KV[$cn]}) . "\n" if($COUNTRY_LIST[$cn] =~ /Japan/i);
	}
	close(KV);

	return ($#COUNTRY_LIST, $date_number - $TERM - 0, $DATE_LIST[$TERM + 0], $DATE_LIST[$date_number]);
}

1;
