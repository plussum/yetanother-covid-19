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

	my ($package_name, $file_name, $line) = caller;
	print "$file_name ($line)" . join("", @p);
}

1;
