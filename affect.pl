#!/usr/bin/perl

$verbose=1;

# lecture toutes salles

print "======================================== lecture salles ========================================" if $verbose;
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
	print "  creneau $c (a $mins min) => $hhmm\n" if $verbose>1;
	$ht_mins{$mins}=[] unless exists $ht_mins{$mins};
	push @{$ht_mins{$mins}},$s;
    }
    close F;
}

# rangement par creneau horaire
@minss=sort keys %ht_mins;
foreach $mins (@minss)
{
    $matches_sur_creneau{$mins}=();
    $nb_matches_restant_sur_creneau{$mins}=$ht_nb{$mins}=$#{$ht_mins{$mins}}+1;
    print "- a $mins, ",$ht_nb{$mins}," salles dispo = ",join(',',@{$ht_mins{$mins}}),"\n" if $verbose;
}

print "======================================== lecture matches ========================================" if $verbose;
# lecture tous matches
@fmatches=`ls -1 m_*csv`;
foreach $fmatch (@fmatches)
{
    chomp $fmatch;
    $p=$fmatch;
    $p=~s/^m_//;
    $p=~s/.csv$//;
    open F,$fmatch;
    while (<F>)
    {
	next unless /[0-9]/;
	($n,$e1,$e2,$r)=split ';',$_;
	print "poule $p : $e1 contre $e2\n" if $verbose;
	$nom_match="$p;$e1;$e2;";
	push @t_matches,$nom_match;
    }
    close F;
}

print "======================================== traitement matches ========================================" if $verbose;
$passe=1;
@t_m_restants=@t_matches;

# tant qu'il reste des matches pas casés
while ($#t_m_restants>=0)
{
    # matches non pourvus
    @nop=();
    # on itère sur tous les matches
    foreach $match (@t_m_restants)
    {
	
    }
}
