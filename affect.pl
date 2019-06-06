#!/usr/bin/perl

use List::Util 'shuffle';

$verbose=0;
$fo=$fc='';

while ($#ARGV>=0)
{
    $cmd=shift @ARGV;
    # rechargement d'une config retenue sur l'ordre des matches pour que ça rentre
    if ($cmd eq '-lm')
    {
	$flm=shift @ARGV;
	open (LM,$flm);
	while (<LM>)
	{
	    next unless /[a-zA-Z]/;
	    ($p,$e1,$e2,$r)=split ';',$_;
	    $nom_match="$p;$e1;$e2;";
	    push @t_matches,$nom_match;
	    $ht_m_restants{$nom_match}=1;
	}
	@sk_m_restants=@t_matches;
	close LM;
	$skip_poules=1;
    }
    elsif ($cmd eq '-sm')
    {
	$fsm=shift @ARGV;
	$flag_sauve_ordre=1;
    }
    elsif ($cmd eq '-o')
    {
	$fo=shift @ARGV;
    }
    elsif ($cmd eq '-c')
    {
	$fc=shift @ARGV;
    }
    elsif ($cmd eq '-v')
    {
	$verbose++;
    }
    else
    {
	die "Usage : $0 [ -lm fichier_d_ordre_de_matches_a_charger ] [ -sm fichier_ordre_matches_a_sauver ] [ -o fichier_sortie_matches_par_creneaux ] [ -c fichier_sortie_creneaux ] [-v] \n";
    }
}

# lecture toutes salles

print "======================================== lecture salles ========================================\n" if $verbose > 1;
@salles=`ls -1 t_*csv`;
foreach $salle (@salles)
{
    chomp $salle;
    open F,$salle;
    $s=$salle;
    $s=~s/^t_//;
    $s=~s/\.csv$//;
    print "- lecture $salle ($s)\n" if $verbose > 2;
    while (<F>)
    {
	next unless /[0-9]/;
	next if /#/;
	($c,$mins,$hhmm,$r)=split ';',$_;
	print "  creneau $c (a $mins min) => $hhmm\n" if $verbose>3;
	$ht_mins{$mins}=[] unless exists $ht_mins{$mins};
	push @{$ht_mins{$mins}},$s;
    }
    close F;
}

# rangement par creneau horaire
open FC,">$fc" unless $fc eq '';
%ht_aff_creneau=();
@minss=sort keys %ht_mins;
# nb max de salles par creneau
$maxspc=0;
$nb_total_creneaux=0;
foreach $mins (@minss)
{
    $ht_aff_creneau{$mins}=[];
    $nb_matches_restant_sur_creneau{$mins}=$ht_nb{$mins}=$#{$ht_mins{$mins}}+1;
    $nb_total_creneaux+=$ht_nb{$mins};
    $maxspc=$ht_nb{$mins} if $ht_nb{$mins}>$maxspc;
    print "- a $mins, ",$ht_nb{$mins}," salles dispo = ",join(',',@{$ht_mins{$mins}}),"\n" if $verbose >1;
    print FC $mins,';',$ht_nb{$mins},';',join(';',@{$ht_mins{$mins}}),";\n";
}
close FC unless $fc eq '';

goto trait if $skip_poules;
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
	next if /#/;
	($n,$e1,$e2,$r)=split ';',$_;
	print "poule $p : $e1 contre $e2\n" if $verbose > 2;
	$nom_match="$p;$e1;$e2;";
	push @t_matches,$nom_match;
	$ht_m_restants{$nom_match}=1;
    }
    close F;
}
print "$nb_total_creneaux creneaux pour ",(keys %ht_m_restants)+0," matches\n" if $verbose;
# rangement aléatoire des matches
@sk_m_restants=shuffle keys %ht_m_restants;
# sortie de l'ordre des matches
if ($flag_sauve_ordre)
{
    open F,">$fsm";
    foreach $m (@sk_m_restants)
    {
	print F "$m\n";
    }
    close F;
}

trait:
    print "======================================== traitement matches ========================================\n" if $verbose > 1;
# init
$passe=1;
%ht_eq_joue_deja=();
%ht_aff_match=();

# tant qu'il reste des matches pas casés
while ((keys %ht_m_restants)+0>0)
{
    print "- passe $passe : reste ",(keys %ht_m_restants)+0," matches à ventiller \n" if $verbose;
    # on itère sur tous les matches rangés au hasard
    foreach $match (@sk_m_restants)
    {
	($p,$e1,$e2,$r)=split /;/,$match;
	print "  - essai sur $e1 vs $e2 dans $p\n" if $verbose > 1;
	# on itère sur les créneaux dispos
	for ($im=0;$im<=$#minss;$im++)
	{
	    $mins=$minss[$im];
	    if ($nb_matches_restant_sur_creneau{$mins}>0)
	    {
		# ok : creneau dispo
		# calculs old et next mins
		$omins=$nmins=0;
		$omins=$minss[$im-1] if $im>0;
		$nmins=$minss[$im+1] if $im<$#minss;
		# verif si une des 2 equipes joue deja sur ce creneau
		if ( (!exists($ht_eq_joue_deja{"$p;$e1;$mins"})) &&
		     (!exists($ht_eq_joue_deja{"$p;$e2;$mins"})) )
		{
		    if ( ($passe>1) ||
			 ( (!exists($ht_eq_joue_deja{"$p;$e1;$omins"})) &&
			   (!exists($ht_eq_joue_deja{"$p;$e2;$omins"})) &&
			   (!exists($ht_eq_joue_deja{"$p;$e1;$nmins"})) &&
			   (!exists($ht_eq_joue_deja{"$p;$e2;$nmins"})) ) )
		    {
			# ok aucune des 2 équipe ne joue déjà sur le créneau
			# ou sur celui d'avant ou d'apres (pour la première passe)
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
			print "    => sur creneau $mins\n" if $verbose > 1 ;
			# sortie de la boucle créneau
			last;
		    }
		}
	    }
	}	
    }
    print "- fin passe $passe : ",(keys %ht_m_restants)+0," matches à ventiller \n\n" if $verbose;
    $passe++;
    # reconstitution de la liste des matches à traiter à partir de l'ordre aléatoire initial et de ce qu'il reste ds la table de hash
    @sk2=();
    foreach $m (@sk_m_restants)
    {
	push @sk2,$m if exists ($ht_m_restants{$m});
    }
    @sk_m_restants=@sk2;
    last if $passe>2;
}

# sortie des matches par creneau
unless ($fo eq '')
{
    open (F,">$fo");
    foreach $mins (@minss)
    {
	print F "$mins;";
	$i=0;
	foreach $match (@{$ht_aff_creneau{$mins}})
	{
	    ($p,$e1,$e2,$r)=split /;/,$match;
	    print F "$e1 - $e2 ($p);";
	    $i++;
	}
	for (;$i<$maxspc;$i++)
	{
	    print F ";";
	}
	print F "\n";
    }
    close F;
}
