#!/usr/bin/perl

@salles=`ls -1 t_*csv`;
foreach $salle (@salles)
{
    chomp $salle;
    open F,$salle;
    $s=$salle;
    $s=~s/^t_//;
    $s=~s/\.csv$//;
    print "- lecture $salle ($s)\n" if $verbose;
    while (<F>)
    {
	next unless /[0-9]/;
	($c,$mins,$hhmm,$r)=split ';',$_;
	print "  creneau $c (a $mins min) => $hhmm\n" if $verbose;
    }
}
