#!/bin/perl

# generation des csv pour les feuilles de poule avec classement des équipes en fonction des matches jouées

$verbose=3;
&initz;

# lecture des fichiers de poule
@fps=`ls -1 p_*csv`;
foreach $fp (@fps)
{
    chomp $fp;
    $p=$fp;
    $p=~s/^p_//;
    $p=~s/.csv$//;
    open F,$fp;
    print "- poule $p :\n" if $verbose;
    @te=();
    while (<F>)
    {
        next unless /[A-Za-z]/;
        next if /#/;
        ($e,$r)=split ';',$_;
        print "  - equipe $e\n" if $verbose > 1;
        push @te,$e;
    }
    close F;
    $nb=$#te+1;
    print "  => $nb equipes\n" if $verbose;

    # netoyage tableau de travail (excel)
    $dx=$nb*2+1;
    $dy=$nb+1+12;
    &clean($dx,$dy);
    $lstat=$nb+2+2;

    # prod 1er ligne et colonne et nom equipes pour stats
    for($i=0;$i<$nb;$i++)
    {
	$h{1}{$i+2}=$te[$i];
	$h{$i*2+3}{1}=$te[$i];
	$h{$i+2}{$lstat}=$te[$i];
    }
    # prod stats libeles
    $i=$lstat;
    foreach $txt ('equipe','m joues','m gagnes','m nuls','m perdus','pts marqu','pts encais','diff pts','score','rang')
    {
	$h{1}{$i++}=$txt;
    }
    
    # cellules barées
    for($i=0;$i<$nb;$i++)
    {
	for ($j=$i;$j<$nb;$j++)
	{
	    $h{$i*2+2}{$j+2}='X';
	    $h{$i*2+3}{$j+2}='X';
	}
    }

    # matches joues
    &op($lstat+1,"SI(@1>=0;1)");
    # matches gagnés
    &op($lstat+2,"SI(@1>@2;1)");
    # matches nuls
    &op($lstat+3,"SI(@1==@2;1)");
    # matches perdus
    &op($lstat+4,"SI(@1<@2;1)");
    # pts marqués
    &op($lstat+5,"@1");
    # pts encaissés
    &op($lstat+5,"@2");
    
    # generation fichier csv
    open F,">f_$p.csv";
    &gen($dx,$dy);
    close F;
}


sub clean
{
    my ($dx,$dy)=@_;
    %h={};
    for ($x=1;$x<=$dx;$x++)
    {
	$h{$x}={};
	for ($y=1;$y<=$dy;$y++)
	{
	    $h{$x}{$y}='';
	}
    }
}

sub gen
{
    my ($dx,$dy)=@_;
    for ($y=1;$y<=$dy;$y++)
    {
	for ($x=1;$x<=$dx;$x++)
	{
	    print F $h{$x}{$y},';';
	}
	print F "\n";
    }
}

# init correspondance entre numero de colonne et lettre de colonne excel
sub initz
{
    @z=('?');
    for($i=0;$i<26;$i++)
    {
	push @z,chr(65+$i);
    }
}
