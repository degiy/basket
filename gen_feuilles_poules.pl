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
    &op($lstat+1,'IF(@1="";0;1)');
    # matches gagnés
    &op($lstat+2,'IF(@1>@2;1;0)');
    # matches nuls
    &op($lstat+3,'IF(@1="";0;1)*IF(@1=@2;1;0)');
    # matches perdus
    &op($lstat+4,'IF(@1<@2;1;0)');
    # pts marqués
    &op($lstat+5,'IF(@1="";0;@1)');
    # pts encaissés
    &op($lstat+6,'IF(@2="";0;@2)');
    # autres stats
    &ops($lstat+7);
    
    # generation fichier csv
    open F,">f_$p.csv";
    &gen($dx,$dy);
    close F;
}


sub ops
{
    my ($ligne)=@_;
    print "  - stats diverses sur ligne $ligne\n" if $verbose>1;
    # on itere sur toutes les equipes
    for(my $i=0;$i<$nb;$i++)
    {
	# diff de pts
	$h{$i+2}{$ligne}="=".$z[$i+2].($ligne-2)."-".$z[$i+2].($ligne-1);
	# score
	$h{$i+2}{$ligne+1}="=3*".$z[$i+2].($ligne-5)."+".$z[$i+2].($ligne-4);
	# rang
	$h{$i+2}{$ligne+2}="=RANK(".$z[$i+2].($ligne+1).";B".($ligne+1).":".$z[$nb+1].($ligne+1).";0)";
    }
}

sub op
{
    my ($ligne,$exp)=@_;
    print "  - stats $exp sur ligne $ligne\n" if $verbose>1;
    # on itere sur toutes les equipes
    for(my $i=0;$i<$nb;$i++)
    {
	my $res=&opi($exp,$i+1);
	$h{$i+2}{$ligne}=$res;
    }
}

sub opi
{
    my ($exp,$e)=@_;
    my $res="= 0 ";
    # on itere sur la ligne (match allés)
    print "    - stat pour equipe $e\n" if $verbose>2;
    for (my $i=$e+1;$i<=$nb;$i++)
    {
	my $form=$exp;
	my $c1=$z[$i*2].($e+1);
	my $c2=$z[$i*2+1].($e+1);
	print "      - cell c1=$c1,c2=$c2\n" if $verbose>3;
	$form=~s/\@1/$c1/g;
	$form=~s/\@2/$c2/g;
	$res.="+ $form";
    }
    # on itere sur la colonne (match retours)
    for (my $i=1;$i<$e;$i++)
    {
	my $form=$exp;
	my $c1=$z[$e*2+1].($i+1);
	my $c2=$z[$e*2].($i+1);
	print "      - cell c1=$c1,c2=$c2\n" if $verbose>3;
	$form=~s/\@1/$c1/g;
	$form=~s/\@2/$c2/g;
	$res.="+ $form";
    }
    
    return $res;
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
	    print F $h{$x}{$y},"\t";
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
