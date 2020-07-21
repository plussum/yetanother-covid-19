
#	csv操作の基本的な関数群
#
#
#
package csvlib;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(csvlib);

use strict;
use warnings;
use Data::Dumper;
use Time::Local 'timelocal';
use dp;

my $DEBUG = 0;

#
#
#
sub	sum
{
	my ($data, $s, $e) = @_;
	
	if($DEBUG){
		print "($s:$e:" . ($e - $s + 1) . ")";
		for(my $i = $s; $i <= $e; $i++){
			print "[" . $data->[$i] . "]";
		}
	}
	dp::dp "sum($s, $e)\n" if($s =~ /[^0-9]/ || $e =~ /[^0-9]/);
	dp::dp "sum($s, $e)\n" if($s > $e);
	dp::dp "sum($s, $e) OUT OF RANGE(" . scalar(@$data) . ")\n" if($s < 0 || $e > scalar(@$data));

	my $sum = 0;
	for(my $i = $s; $i <= $e; $i++){
		$sum += (defined $data->[$i]) ? $data->[$i] : 0;
	}
	print "i=> $sum\n" if($DEBUG);
	return $sum;
}

sub	avr
{
	my ($data, $s, $e) = @_;
	
	my $sum = &sum($data, $s, $e);
	my $avr = $sum / ($e - $s + 1);
	return $avr;
}


#
#
#	unix_time, ":", -> "01:23:45"
#
sub ut2t
{
	my ($tm, $dlm) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%02d%s%02d%s%02d", $hour, $dlm, $min, $dlm, $sec);
	return $s;
}
#
#	unix_time, "/", -> "20/01/02"
#
sub ut2d
{
	my ($tm, $dlm) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%02d%s%02d%s%02d", $year % 100, $dlm, $mon+1, $dlm, $mday);
	return $s;
}

#
#	unix_time, "/", -> "2020/01/02"
#
sub ut2d4
{
	my ($tm, $dlm) = @_;
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%04d%s%02d%s%02d", $year + 1900, $dlm, $mon+1, $dlm, $mday);
	return $s;
}

#
#	year, month, date, hour, min, sec -> unix_time
#
sub ymd2tm
{
	my ($y, $m, $d, $h, $mn, $s) = @_;

	#print "ymd2tm: " . join("/", @_), "\n";

	#$y -= 2100 if($y > 2100);
	my $tm = timelocal($s, $mn, $h, $d, $m - 1, $y);
	# print "ymd2tm: " . join("/", $y, $m, $d, $h, $mn, $s), " --> " . &ut2d($tm, "/") . "\n";
	return $tm;
}

#
#	"2020/01/02/hh/mm/ss", "/", 0, 1, 2, 3, 4, 5, 6 -> unix_time
#
sub	date2ut
{
	my ($dt, $dlm, $yn, $mn, $dn, $hn, $mnn, $sn) = @_;

	my @w = split(/$dlm/, $dt);
	my ($y, $m, $d, $h, $mi, $s) = ();
	
	$y = &valdef($w[$yn], 0);
	$m = &valdef($w[$mn], 0);
	$d = &valdef($w[$dn], 0);

	if(! defined $hn){
		return &ymd2tm($y, $m, $d, 0, 0, 0);
	}

	$h  = &valdef($w[$hn], 0);
	$mi = &valdef($w[$mnn], 0);
	$s  = &valdef($w[$sn], 0);

	return &ymd2tm($y, $m, $d, $h, $mi, $s);
} 

sub search_list
{
    my ($sk, @w) = @_;

    #dp::dp "search_list: $sk:" . join(",", @w) . "\n";
    for(my $i = 0; $i <= $#w; $i++){
		my $ntc = $w[$i];
        if($sk =~ /$ntc/){
           #dp::dp "search_list: $sk:$ntc\n";
           return $i + 1;
        }
    }
    #dp::dp "Not in the list: $sk\n" ;
    return "";
}
sub search_listp
{
    my ($sk, $wp) = @_;

	my $wn = scalar(@$wp);
    #dp::dp "search_list: $sk:" . join(",", @$w) . "\n";
    for(my $i = 0; $i <= $wn; $i++){
		my $ntc = $wp->[$i];
        if($sk =~ /$ntc/){
           #dp::dp "search_list: $sk:$ntc\n";
           return $i + 1;
        }
    }
    #dp::dp "Not in the list: $sk\n" ;
    return "";
}

sub valdef
{
    my ($v, $d) = @_;

    $d = 0 if(! defined $d);                                                                                                                     
    return (defined $v) ? $v : $d; 
}

sub valdefs
{
	my ($v, $d) = @_;
	$d = "" if(! defined $d);
	my $rt = (defined $v && $v) ? $v : $d;

	#print "valdef:[$v]:[$d]:[$rt]\n";
	return $rt;
}	

#
#
#
sub	date_format
{
	my ($dt, $dlm, $y, $m, $d, $h, $mn, $s) = @_;

	my @w = split(/$dlm/, $dt);
	my @dt = ();
	my @tm = ();
	
	$dt[0] = &valdef($w[$y], 0);
	$dt[1] = &valdef($w[$m], 0);
	$dt[2] = &valdef($w[$d], 0);

	my $dts = join("/", @dt);
	if(! defined $h){
		retunr $dts;
	}
	
	$tm[0] = &valdef($w[$h], 0);
	$tm[1] = &valdef($w[$mn], 0);
	$tm[2] = &valdef($w[$s], 0);
	my $tms = join(":", @tm);

	return "$dts $tms";
} 

#
#
#
sub	calc_max
{
	my ($v, $log) = @_;

	$v = 1 if($v < 1);
	my $digit = int(log($v)/log(10));
	my $max = 0;
	if(!$log){
		$max = (int(($v / 10**$digit)*10 + 9.999)/10) * 10**$digit;
	}
	else {
		$max = 10**($digit+1);
	}

	# print "ymax:[$v:$max]\n";

	return $max;

}

#
#	Country Population		(WHOは国が多すぎるのとPDFベースなので、不一致が多くあきらめた)
#
sub	cnt_pop
{
	my ($cnt_pop) = @_;
	my $popf = "$config::POPF";

	open(FD, $popf) || die "cannot open $popf\n";
	<FD>;
	while(<FD>){
		chop;
		
		my($name, $pn) = split(",", $_);

		$cnt_pop->{$name} = $pn;
	}
	close(FD);
}

#
#01	北海道		Hokkaido	5320	2506	2814
#02	青森県		Aomori-ken	1278	600	678
#03	岩手県		Iwate-ken	1255	604	651
#04	宮城県		Miyagi-ken	2323	1136	1188
sub	cnt_pop_jp
{
	my ($cnt_pop) = @_;
	my $popf = "$config::POPF_JP";

	my %JHU_CN = ();
	my %WHO_CN = ();
	open(FD, $popf) || die "cannot open $popf\n";
	while(<FD>){
		chop;
		next if(! /^[0-9]/);
		
		my($no, $pref, $pref_e, $total, $m, $fm) = split(/[ \t]+/, $_);

		#dp::dp join(",", $no, $pref, $pref_e, $total, $m, $fm) . "\n";
		$cnt_pop->{$pref} = $total * 1000;
		$cnt_pop->{$pref_e} = $total * 1000;
		#dp::dp join(",", $pref, $pref_e, $cnt_pop->{$pref}) . "\n";
	}
	close(FD);
}

sub	max_val
{
	my ($v, $div) = @_;

	$v = 1 if($v <= 0);
	$div = 1 if(!defined $div);
	my $digit = 10 ** int(log($v) / log(10));

	my $vv = $digit * int(1 + $div * $v / $digit)/$div;
	$vv = int(0.5+$vv);

	return $vv;
}


1;
