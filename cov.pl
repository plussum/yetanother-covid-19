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
my $gen = 1;

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$download = 1 if(/-DL/i);
	$gen = "" if(/-NG/i);
	
}

if($gen){
	system("(cd ../COVID-19; git pull origin master)") if($download);
	system("./ccse.pl");

	my $gwflag = ($download) ? "-dl" : "";
	system("./getwho.pl $gwflag");

	system("./japan.pl $gwflag");
}


my $WIN_PATH = "/mnt/f/OneDrive/cov";
my $INDEX_HTML = "$WIN_PATH/covid_index.html";
my $FRAME_HTML = "$WIN_PATH/covid_frame.html";
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
my @html_list = split("\n", $HTML_LIST);

my $gfs =  $html_list[0];
$gfs =~ s/$WIN_PATH/./;
my $INDEX = << "_EOI_";
<html>
<head>
<title>INDEX COVID-19 </title>
</head>

<frameset cols="300,*">
    <frame src="covid_frame.html" name="index">
    <frame src="$gfs" name="graph">
    </frameset>
</frameset>
</html> 
_EOI_

my $CSS = << "_EOCSS_";
	<style type="text/css">
	<!--
		span.c {font-size: 12px;}
	-->
	</style>
_EOCSS_

my $TBL_SIZE = 10;
my $class = "class=\"c\"";

open(INDEX, ">$INDEX_HTML") || die "cannot create file $INDEX_HTML";
print INDEX $INDEX;
close(INDEX);

open(FRAME, "> $FRAME_HTML") || die "Cannot create file $FRAME_HTML";
print FRAME "<HTML>\n";
print FRAME "<HEAD>\n";
print FRAME "<TITLE> COVID-19 INDEX </TITLE>\n";
print FRAME $CSS;
print FRAME "</HEAD>\n";
print FRAME "<BODY>\n";

print FRAME "<span class=\"c\"> ";
print FRAME "<H1>INDEX COVID-19</H1>\n";
print FRAME "<ul type=\"disc\">\n";
foreach my $p (@html_list){
	my $relp = $p;
	$relp =~ s/$WIN_PATH/./; 

	print FRAME "<li><a href =\"$relp\" target=\"graph\">$relp</a></li>\n";
}
print FRAME "</ul>\n";
print FRAME "</span>\n";
print FRAME "</BODY>\n";
print FRAME "</HTML>\n";
close(FRAME);

