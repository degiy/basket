#!/usr/bin/perl

use POSIX;

$verbose=1;

# recup ordre des salles
# ./t_bouin.csv:#prio 1;;
open F,"grep '^#prio ' ./t_*csv|";
while (<F>)
{
    s/^\..t_//;
    s/\.csv:#prio /;/;
    ($salle,$prio,$r)=split ';';
    push @t,sprintf "%02d;%s",$prio,$salle;
}
close F;
@tt=sort @t;
@tprio=();
foreach $s (@tt)
{
    $s=~s/[0-9]+;//;
    push @tprio,$s;
}

while ($#ARGV>=0)
{
    $cmd=shift @ARGV;
    # chargement des matches sur chaque creneau
    if ($cmd eq '-i')
    {
	$fi=shift @ARGV;
	open FI,$fi;
	while (<FI>)
	{
	    next unless /[a-zA-Z]/;
	    @t=split /;/;
	    $mins= shift @t;
	    $htm{$mins}=[];
	    pop @t;
	    push @{$htm{$mins}},@t;
	}
	close FI;
    }
    # chargement des salles sur chaque creneau
    elsif ($cmd eq '-c')
    {
	$fc=shift @ARGV;
	open FC,$fc;
	while (<FC>)
	{
	    next unless /[a-zA-Z]/;
	    @t=split /;/;
	    $mins= shift @t;
	    push @minss,$mins;
	    $hts{$mins}=[];
	    shift @t;
	    pop @t;
	    # tri des salles par priorité
	    @tt=&ordre_salles(@t);
	    push @{$hts{$mins}},@tt;
	}
	close FC;
    }
    elsif ($cmd eq '-v')
    {
	$verbose++;
    }
    else
    {
	die "Usage : $0 [ -i fichier_des_matches_par_creneau ] [ -c fichier_de_creneaux] [-v] \n";
    }
}

# ordre des salles pré-calculé
print "ordre des salles : ",join(' ',@tprio),"\n" if $verbose;

# recuperation des preferences de salle par poule
open F, "grep '^#pref' p_*csv |";
%htp=();
while (<F>)
{
    # p_u9a.csv:#pref t5;t6;
    s/^p_//;
    s/.csv:#pref /;/;
    print "pref line = --",$_,"--\n" if $verbose>1;
    @t=split /;/;
    $p=shift @t;
    $i=1;
    # indexation des choix de salle par poule 1,2,3,...
    foreach $s (@t)
    {
	next unless $s=~/[A-Aa-z]/;
	$htp{$s}={} unless exists $htp{$s};
	$htp{$s}{$i}=[] unless exists $htp{$s}{$i};
	push @{$htp{$s}{$i}},$p;
	print "$s rg $i : ",join(',',@{$htp{$s}{$i}}),"\n";
	$i++;
    }
}
close F;


# iteration sur les creneaux
foreach $mins (@minss)
{
    print "- creneau $mins\n" if $verbose;
    print "  - dispo salles : ",join(',',@{$hts{$mins}}), "\n" if $verbose;
    print "  - matches : ",join(' , ',@{$htm{$mins}}), "\n" if $verbose;

    # chargement des matches du créneau => hash matches par poule et global presence
    %htmpp=();
    %htmsc=();
    foreach $mp (@{$htm{$mins}})
    {
	next unless $mp=~/[A-Za-z]/;
	# colomier1 - otb (u9a)
	($m,$p)=$mp=~/(.*) \((.*)\)/;
	print "m=$m, p=$p\n" if $verbose>3;
	# tableau de matches de la même poule sur creneau
	$htmpp{$p}=[] unless exists $htmpp{$p};
	push @{$htmpp{$p}},$mp;
	$htmsc{$mp}=1;
    }
    
    # iteration sur les salles/terrains
    foreach $salle (@{$hts{$mins}})
    {
	print "    - pour salle $salle : " if $verbose>1;
	if (exists $htp{$salle})
	{
	    # priorité pour cette salle
	    print " (priorités ",join(',',sort keys %{$htp{$salle}}),") " if $verbose>2;
	    foreach $i (sort keys %{$htp{$salle}})
	    {
		# liste des poules au rang de priorité i
		foreach $p (@{$htp{$salle}{$i}})
		{
		    print " [ rg $i : $p ? ] " if $verbose>3;
		    print " { hash ",$htmpp{$p}," [0] ",$htmpp{$p}[0]," } "if $verbose>4;
		    # poule prioritaire p, a-t-on un match ds cette poule sur le créneau ?
		    next unless exists $htmpp{$p};
		    # ok a des des matches de cette poule sur le créneau, on itère
		    foreach $mp (@{$htmpp{$p}})
		    {
			# on passe si le match a déjà été affecté
			next unless exists $htmsc{$mp};
			# sinon on a un client
			print "$mp\n" if $verbose > 1;
			delete $htmsc{$mp};
			$htsalle{$salle}{$mins}=$mp;
			goto prochaine_salle;
		    }
		}
	    }
	    print " (echec prios) " if $verbose>2;
	}
	# pas de priorité pour cette salle (ou echec sur les prio), on prend le premier match dispo
	@ms=keys %htmsc;
	if ($#ms>=0)
	{
	    $mp=shift @ms;
	    print "$mp\n" if $verbose > 1;
	    delete $htmsc{$mp};
	    $htsalle{$salle}{$mins}=$mp;
	}
	else
	{
	    $htsalle{$salle}{$mins}='-';
	    print " => pas de match pour cette salle\n" if $verbose>1;
	}
      prochaine_salle:
    }
    # verif plus de matches sur créneau
    if ((keys %htmsc) + 0 > 0)
    {
	print "\n!!! pb : reste des matches non pourvus sur créneau : ",join(' , ',keys %htmsc),"\n";
    }
}

# generation des tableaux
# F : basique (juste les heures et les matches)
# F2: avec score en plus
# F4: avec arbitre, otm et score

open F,">tableau.csv";
open F2,">tableau2.csv";
open F4,">tableau4.csv";
@salles=keys %htsalle;
@salless=&ordre_salles(@salles);
print F  "creneau;",join(';',@salless),";\n";
print F2 "creneau;",join(';',@salless),";\n";
print F4 "creneau;",join(';',@salless),";\n";

foreach $mins (@minss)
{
    $sp=";";
    $hh=floor($mins/60);
    $mm=$mins-$hh*60;
    printf F  "%02d:%02d;",$hh,$mm;
    printf F2 "%02d:%02d;",$hh,$mm;
    printf F4 "%02d:%02d;",$hh,$mm;
    foreach $salle (@salless)
    {
	$mp=$htsalle{$salle}{$mins};
	print F $mp,";";
	print F2 $mp,";";
	print F4 $mp,";";
	$sp.=";";
    }
    print F  "\n";
    print F2 "\n";
    print F2 "$sp\n";
    print F4 "\n";
    print F4 "$sp\n";
    print F4 "$sp\n";
    print F4 "$sp\n";
}
close F;
close F2;
close F4;

# generation du tableau avec triple ligne
    
sub ordre_salles
{
    my @t=@_;
    my @tt;
    my ($ref,$candid);
    
    foreach $ref (@tprio)
    {
	foreach $candid (@t)
	{
	    push @tt,$ref if $ref eq $candid;
	}
    }
    print "en entree : ",join(',',@t)," , en sortie : ",join(',',@tt),"\n" if $verbose;
    return @tt;
}
