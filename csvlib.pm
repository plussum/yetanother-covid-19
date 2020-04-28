
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
use Time::Local 'timelocal';



#
#
#
#
sub ut2t
{
	my ($tm, $dlm) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%02d%s%02d%s%02d", $hour, $dlm, $min, $dlm, $sec);
	return $s;
}
sub ut2d
{
	my ($tm, $dlm) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%02d%s%02d%s%02d", $year % 100, $dlm, $mon+1, $dlm, $mday);
	return $s;
}

sub ut2d4
{
	my ($tm, $dlm) = @_;
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%04d%s%02d%s%02d", $year + 1900, $dlm, $mon+1, $dlm, $mday);
	return $s;
}

#
#
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
#
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

    for(my $i = 0; $i <= $#w; $i++){
		my $ntc = $w[$i];
        if($sk =~ /$ntc/){
            #print "search_list: $sk:$ntc\n" ;
            return $i + 1;
        }
    }
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
	my $popf = "COV/pop.csv";

	my %JHU_CN = ();
	my %WHO_CN = ();
	open(FD, $popf) || die "cannot open $popf\n";
	<FD>;
	while(<FD>){
		chop;
		
		my($jhu, $who, $un, $pn, @w) = split(",", $_);

		$JHU_CN{$jhu}++;
		$WHO_CN{$who}++;
		$cnt_pop->{$un} = $pn;
		foreach my $sn (@w){
			$cnt_pop->{$sn} = $pn;
		}
	}
	close(FD);

	foreach my $c (sort keys %JHU_CN){
		if(defined $cnt_pop->{$c}){
			#print "$c\t" . $cnt_pop->{$c}, "\n";
		}
		else {
			#print $c , "\n";
		}
	}
	foreach my $c (sort keys %WHO_CN){
		if(defined $cnt_pop->{$c}){
			#print "$c\t" . $cnt_pop->{$c}, "\n";
		}
		else {
			#print $c , "\n";
		}
	}
}
