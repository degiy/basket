
rm -f ./t_*.csv

./creneaux_salle.pl -s bouin -p 20 -d 9:30 -f 12:00 -t -t -d 13:40 -f 16:00
./creneaux_salle.pl -s roure -p 20 -d 9:30 -f 12:00 -t -t -d 13:40 -f 16:00
./creneaux_salle.pl -s ext1 -p 20 -d 10:10 -f 12:00 -t -t -d 14:00 -f 16:00
./creneaux_salle.pl -s ext2 -p 20 -d 10:10 -f 12:00 -t -t -d 14:00 -f 16:00
./creneaux_salle.pl -s ext3 -p 20 -d 10:10 -f 12:00 -t -t -d 14:00 -f 15:30
./creneaux_salle.pl -s ext4 -p 20 -d 10:10 -f 12:00 -t -t -d 14:00 -f 15:30
./creneaux_salle.pl -s ext5 -p 20 -d 10:50 -f 12:00 -t -t -d 14:00 -f 15:30
