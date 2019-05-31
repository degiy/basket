#!/usr/bin/perl

# script de creation des différentes matches d'une poule

$#ARGV==-1 and die "$0 -i <p_poule.csv>\n";
$file=$ARGV[0];

$poule=$file;
$poule=~s/\.csv$//;
$poule=~s/^p_//;

open F,$file or die "impossible d'ouvrir $file\n";
while (<F>)
{
    next unless /[a-z]/;
    next if /#/;
    chomp $_;
    s/;.*$//;
    push @eq,$_;
}
close F;

open F,">m_$poule.csv";

@eqs=sort @eq;
$nb=$#eq+1;
$c=1;
for ($i=0;$i<$nb;$i++)
{
    for ($j=$i+1;$j<$nb;$j++)
    {
	print F $c++,';',$eqs[$i],';',$eqs[$j],';',"\n";
    }
}
close F;

