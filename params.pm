#
#	John Hopkings CCSEとWHOの共通グラフ生成パラメータ
#
#
#
package params;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(params);

use strict;
use warnings;

my $EXCLUSION = "Others,China,USA";
my $NONE_EXC = "Others";
my @COMMON_PARAMS = (
    {ext => "#KIND# all with US(#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => "Others", target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP5+Japan(#LD#) #SRC#", start_day => 0, lank =>[0, 4] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", add_target => "Japan"},
	{ext => "#KIND# TOP5+Japan(wo US)(#LD#) #SRC#", start_day => 0, lank =>[0, 4] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", add_target => "Japan"},

    {ext => "#KIND# Japan (#LD#) #SRC#", start_day => 0,  lank =>[0, 4] , exclusion => "Others", target => "Japan", label_skip => 3, graph => "lines"},
    {ext => "#KIND# Japan 3weeks (#LD#) #SRC#", start_day => -21,  lank =>[0, 4] , exclusion => "Others", target => "Japan", label_skip => 1, graph => "lines"},

    {ext => "#KIND# TOP20-122 (#LD#) #SRC#", start_day => 0, lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", term_ysize => 600},

    {ext => "#KIND# 01-05 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[0,  4] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},
    {ext => "#KIND# 06-10 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[5,  9] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},
    {ext => "#KIND# 11-20 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[10, 19] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},
    {ext => "#KIND# 21-30 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[20, 29] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},
    {ext => "#KIND# 31-40 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[30, 39] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},
    {ext => "#KIND# 41-50 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[40, 49] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},

    {ext => "#KIND# 3weeks 01-05 (#LD#) #SRC#", start_day => -21, lank =>[0, 4] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 06-10 (#LD#) #SRC#", start_day => -21, lank =>[5, 9] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 11-20 (#LD#) #SRC#", start_day => -21, lank =>[10,19] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 21-30 (#LD#) #SRC#", start_day => -21, lank =>[20,29] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 31-40 (#LD#) #SRC#", start_day => -21, lank =>[30,39] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 41-50 (#LD#) #SRC#", start_day => -21, lank =>[40,49] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 51-60 (#LD#) #SRC#", start_day => -21, lank =>[50,59] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 61-70 (#LD#) #SRC#", start_day => -21, lank =>[60,69] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 71-80 (#LD#) #SRC#", start_day => -21, lank =>[70,79] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},

	{ext => "#KIND# all-211 ALL logscale (#LD#) #SRC#", start_day => 0, lank =>[0, 19] , exclusion => "Others", target => "", additional_target => "Japan",
		label_skip => 3, graph => "lines", logscale => "y", average => 5, add_target => "Japan"},
	{ext => "#KIND# TOP10 -211 ALL logscale (#LD#) #SRC#", start_day => 0, lank =>[10, 19] , exclusion => "Others", target => "", additional_target => "Japan",
		label_skip => 3, graph => "lines", logscale => "y", average => 5, add_target => "Japan"},
	{ext => "#KIND# TOP5 -211 ALL logscale (#LD#) #SRC#", start_day => 0, lank =>[0, 4] , exclusion => "Others", target => "", additional_target => "Japan",
		label_skip => 3, graph => "lines", logscale => "y", average => 5, add_target => "Japan"},
#    {ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0,  lank =>[0, 999] , exclusion => $EXCLUSION, target => "Taiwan", label_skip => 3, graph => "lines"},
#    {ext => "$PP#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXCLUSION, target => "China", label_skip => 3, graph => "lines"},

    {ext => "#KIND# Japan 0301 (#LD#) #SRC#", start_day => "03/01", lank =>[0, 9999] , exclusion => $NONE_EXC, target => "Japan", label_skip => 2, graph => "lines"},
);

sub	common
{
	return (@COMMON_PARAMS);
}
1;
