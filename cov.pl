#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、CSVとグラフを生成する
#
#	beoutbreakprepared
#	https://github.com/beoutbreakprepared/nCoV2019
#
#
use strict;
use warnings;
use lib qw(../gsfh);

my $DEBUG = 0;
my $download = 0;

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$download = 1 if(/-DL/i);
}

if(1){
	system("(cd ../COVID-19; git pull origin master)") if($download);
	system("./ccse.pl");

	my $gwflag = ($download) ? "-dl" : "";
	system("./getwho.pl $gwflag");

	system("./japan.pl $gwflag");
}


my $WIN_PATH = "/mnt/f/OneDrive/cov";
my $INDEX_HTML = "$WIN_PATH/covid_index.html";
my $HTML_LIST = << "_EOD_";
/mnt/f/OneDrive/cov/COVID-19_NC.html
/mnt/f/OneDrive/cov/COVID-19_ND.html
/mnt/f/OneDrive/cov/who_situation_report_NC.html
/mnt/f/OneDrive/cov/who_situation_report_ND.html
/mnt/f/OneDrive/cov/COVID-19_rate_NC.html
/mnt/f/OneDrive/cov/COVID-19_rate_ND.html
/mnt/f/OneDrive/cov/COVID-19_ft_NC.html
/mnt/f/OneDrive/cov/JapanPref.html
_EOD_

my $CSS = << "_EOCSS_";
	<style type="text/css">
	<!--
		span.c {font-size: 12px;}
	-->
	</style>
_EOCSS_

my $TBL_SIZE = 10;
my $class = "class=\"c\"";

open(HTML, "> $INDEX_HTML") || die "Cannot create file $INDEX_HTML";
print HTML "<HTML>\n";
print HTML "<HEAD>\n";
print HTML "<TITLE> COVID-19 INDEX </TITLE>\n";
print HTML $CSS;
print HTML "</HEAD>\n";
print HTML "<BODY>\n";

print HTML "<span class=\"c\"> ";
print HTML "<H1>GRAPHS of COVID-19</H1>\n";
print HTML "<ul type=\"disc\">\n";
foreach my $p (split("\n", $HTML_LIST)){
	my $relp = $p;
	$relp =~ s/$WIN_PATH/./; 

	print HTML "<li><a href =\"$relp\">$relp</a></li>";
}
print HTML "</ul>\n";
print "</span>\n";
print HTML "</BODY>\n";
print HTML "</HTML>\n";
close(HTML);
