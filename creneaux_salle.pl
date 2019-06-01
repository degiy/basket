#!/usr/bin/perl

# script de creation de creneaux sur une salle

sub fin
{
    die "$0 -s <nom_de_salle> -p <periode_entre_2_creneaux_en_min> -d <hh:mm> -f <hh:mm> -d -f ... -t -prio <priorite_traitement>\n";
}

$#ARGV==-1 and &fin;
# creneau
$c=1;
$prio=99;

while ($#ARGV>=0)
{
    $cmd=shift @ARGV;
    if ($cmd eq '-s')
    {
	$salle=shift @ARGV;
	open (F,">t_$salle.csv");
    }
    elsif ($cmd eq '-p')
    {
	$periode=shift @ARGV;
    }
    elsif ($cmd eq '-prio')
    {
	$prio=shift @ARGV;
    }
    elsif ($cmd eq '-d')
    {
	$deb=shift @ARGV;
    }
    elsif ($cmd eq '-f')
    {
	$fin=shift @ARGV;
	&gen;
    }
    elsif ($cmd eq '-t')
    {
	# trou
	print F ";;\n";
    }
    else
    {
	&fin;
    }
}
print F ";;\n#prio $prio;;\n";
close F;


sub gen
{
    $md=&hhmm2mm($deb);
    $mf=&hhmm2mm($fin);
    $t=$md;
    while ($t<=$mf)
    {
	print F $c++,';',$t,';',&mm2hhmm($t),';',"\n";
	$t+=$periode;
    }
}

sub hhmm2mm
{
    my ($st)=@_;
    my ($hh,$mm)=split ':',$st;
    return $hh*60+$mm;
}

sub mm2hhmm
{
    my ($mm)=@_;
    my $h=int($mm/60);
    my $m=$mm-$h*60;
    my $s=sprintf "%02d:%02d",$h,$m;
    return $s;
}
