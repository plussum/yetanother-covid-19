#!/usr/bin/perl
#
#
#
#

package tko;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(tko);

use strict;
use warnings;
use config;
use csvlib;

my $BASE_DIR = "/home/masataka/who/tokyokeizai/covid19/data";
my $transaction = "/home/masataka/who/tokyokeizai/covid19/data/prefectures.csv";

my $CSV_DIR = $config::WIN_PATH . "/TKO";

&tko_csv($transaction);

sub	tko_csv
{
	my ($src_file) = @_;

	my %DATES = ();
	my %PREFS = ();
	my %COUNT = ();
	my %TOTAL = ();
	my @items = ();

	open(FD, $src_file) || die "cannot open $src_file";
	$_ = <FD>;
	@items = &csv($_);
	dp::dp "[$src_file]\n";
	dp::dp $_ ;
	dp::dp join(",", @items) . "\n";

	while(<FD>){
		my ($y, $m, $d, $pref, $prefe, @vals)  = &csv($_);
		my $ymd = sprintf("%04d/%02d/%02d", $y, $m, $d);

		$DATES{$ymd}++;
		for(my $vn = 0; $vn <= 3; $vn++){
			my $v = $vals[$vn];
			$v = 0 if(!$v);
			$PREFS{$prefe} = $v if($vn == 0);	# 
			$COUNT{$ymd}{$prefe}[$vn] = $v;
			#print $COUNT{$ymd}{$prefe}[$vn] . ", $v \n";
		}
	}
	close(FD);

	#dp::dp "Tokyo: " . $PREFS{Tokyo} . "\n";
	my @PREF_ORDER = sort {$PREFS{$b} <=> $PREFS{$a}} keys %PREFS;
	my @DATE_ORDER = sort keys %DATES;

	my $RN = 0;
	foreach my $pref (@PREF_ORDER){
		#my $tl = 0;
		my $out_file = $CSV_DIR . "/$pref" . ".csv.txt";
		print "[$out_file]\n";
		open(CSV, "> $out_file") || die "cannot create $out_file";
		#print CSV join(",", "# data ", "total", @DATE_ORDER) . "\n";
		print CSV join(",", "# data ", @items[5..8]) . "\n";
		my @lv = ();
		for(my $i = 0; $i <= $#DATE_ORDER; $i++){
			my @data = ();
			my $ymd = $DATE_ORDER[$i];
			for(my $vn = 0; $vn <= 3; $vn++){
				my $v = csvlib::valdef($COUNT{$ymd}{$pref}[$vn], 0);
				$v = 0 if(!$v);
				#dp::dp "$ymd: $v, $lv => " . ($v - $lv) . "\n";
				push(@data, $v - $lv[$vn]);
				#$tl += ($v - $lv[$vn]);
				$lv[$vn] = $v;
			}
			#dp::dp join(", ", $pref, $#DATE_ORDER, $lv, $DATE_ORDER[$#DATE_ORDER]) . "\n";
			#print CSV join(",", $pref, $items[$vn+5], $tl, @data) . "\n";
			#print join(",", $pref, $items[$vn+5], $tl, @data) . "\n";
			print CSV join(",", $ymd, @data) . "\n";
			print join(",", $ymd, @data) . "\n";
		}
		close(CSV);
		exit ;
	}
	#
	#	戻り値: カラム数、レコード数、最初の日付け、最後の日付
	#
	#return ($#date_list, $rn , $date_list[0], $date_list[$#date_list]) ;
	return ($#DATE_ORDER, $RN, $DATE_ORDER[0], $DATE_ORDER[$#DATE_ORDER]);
}

sub	csv
{
	my ($line) = @_;

	$line =~ s/^"//;
	$line =~ s/"*[\r\n]+$//;
	$line =~ s/",/,/g;
	$line =~ s/,"/,/g;
	return (split(/,/, $line));
}

