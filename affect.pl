#!/usr/bin/perl

use List::Util 'shuffle';

$verbose=1;

# lecture toutes salles

print "======================================== lecture salles ========================================\n" if $verbose;
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
%ht_aff_creneau=();
@minss=sort keys %ht_mins;
$nb_total_creneaux=0;
foreach $mins (@minss)
{
    $ht_aff_creneau{$mins}=[];
    $nb_matches_restant_sur_creneau{$mins}=$ht_nb{$mins}=$#{$ht_mins{$mins}}+1;
    $nb_total_creneaux+=$ht_nb{$mins};
    print "- a $mins, ",$ht_nb{$mins}," salles dispo = ",join(',',@{$ht_mins{$mins}}),"\n" if $verbose;
}

print "======================================== lecture matches ========================================\n" if $verbose;
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
	$ht_m_restants{$nom_match}=1;
    }
    close F;
}
print "$nb_total_creneaux creneaux pour ",(keys %ht_m_restants)+0," matches\n" if $verbose;

print "======================================== traitement matches ========================================\n" if $verbose;
# init
$passe=1;
%ht_eq_joue_deja=();
%ht_aff_match=();

# tant qu'il reste des matches pas casés
while ((keys %ht_m_restants)+0>0)
{
    print "- passe $passe : reste ",(keys %ht_m_restants)+0," matches à ventiller \n" if $verbose;
    # on itère sur tous les matches
    foreach $match (shuffle keys %ht_m_restants)
    {
	($p,$e1,$e2,$r)=split /;/,$match;
	print "  - essai sur $e1 vs $e2 dans $p\n" if $verbose;
	# on itère sur les créneaux dispos
	$omins=0;
	foreach $mins (@minss)
	{
	    if ($nb_matches_restant_sur_creneau{$mins}>0)
	    {
		# ok : creneau dispo
		if ( (!exists($ht_eq_joue_deja{"$p;$e1;$mins"})) &&
		     (!exists($ht_eq_joue_deja{"$p;$e2;$mins"})) )
		{
		    if ( ($passe>1) ||
			 ( (!exists($ht_eq_joue_deja{"$p;$e1;$omins"})) &&
			   (!exists($ht_eq_joue_deja{"$p;$e2;$omins"})) ) )
		    {
			# ok aucune des 2 équipe ne joue déjà sur le créneau
			# ou sur celui d'avant (pour la première passe)
			# on supprime le match de la table et on décrémente la dispo du créneau
			delete $ht_m_restants{$match};
			$nb_matches_restant_sur_creneau{$mins}--;
			# puis on affecte le match au creneau et reciproquement
			$ht_aff_match{$match}=$mins;
			push @{$ht_aff_creneau{$mins}},$match;
			# puis on signale que les 2 équipes jouent sur ce créneau
			$ht_eq_joue_deja{"$p;$e1;$mins"}=1;
			$ht_eq_joue_deja{"$p;$e2;$mins"}=1;
			# debug
			print "    => sur creneau $mins\n" if $verbose;
			# sortie de la boucle créneau
			last;
		    }
		}
	    }
	    # on note sous le coude le créneau actuel qui va devenir le précédent
	    $omins=$mins;
	}	
    }
    print "- fin passe $passe : ",(keys %ht_m_restants)+0," matches à ventiller \n\n" if $verbose;
    $passe++;
    last if $passe>2;
}

