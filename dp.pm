#
#
package dp;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(dp);

#
#
#
sub	dp
{
	my (@p) = @_;

	my ($p1, $f1, $l1, $s1, @w1) = caller;
	my ($package_name, $file_name, $line, $sub, @w) = caller(1);
	print "#[$l1]$f1;$sub " . join("", @p);
	#print "#[$line]$file_name " . join("", @p);
}

sub	WARNING
{
	my(@warns) = @_;
	
	#dp:dp "-" x 10 . " WARNING " . "-" x 10 . "\n";
	my ($p1, $f1, $l1, $s1, @w1) = caller;
	my ($package_name, $file_name, $line, $sub, @w) = caller(1);
	my $info = "#[$l1]$f1;$sub " ;

	print $info . "-" x 30 . "\n";
	foreach my $warn (@warns){
		print $info . join("", @warns);
	}
	print $info . "-" x 30 . "\n";

}
1;
