#!/bin/bash

./gen_salles.sh 
./gen_poules.sh 
./affect.pl -sm save.csv -v -o matches_sur_creneaux.csv -c creneaux.csv
./choix_salles.pl  -i ./matches_sur_creneaux.csv -c creneaux.csv -v -v -v


