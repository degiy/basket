#!/usr/bin/perl

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
	    push @{$hts{$mins}},@t;
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

# recuperation des preferences de salle par poule
open F, "grep '^#pref' p_*csv |";
while (<F>)
{
    s/.csv:#pref /;/;
    printf $_ if $verbose>1;
    @t=split /;/;
    $p=shift @t;
    $i=1;
    # indexation des choix de salle par poule 1,2,3,...
    foreach $s (@t)
    {
	$s{$i}=[] unless exists $s{$i};
	push @{$s{$i}},$p;
	$i++;
    }
}

# iteration sur les creneaux
foreach $mins (@minss)
{
    print "- creneau $mins\n" if $verbose;
    print "  - dispo salles : ",join(' ',@{$hts{$mins}}), "\n" if $verbose;
    print "  - matches : ",join(' ',@{$htm{$mins}}), "\n" if $verbose;


}
