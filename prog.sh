#!/bin/sh
#Kemiche Ghiles
#12013565


# le script envoie 0 si tout fonctionne bien
#                  1 si aucun fichier n'a été entré
#				   2 si l'extension du fichier n'est pas .aiken ou -c ou --correction	  


#definir les couleur pour n'utiliser que leur noms
rougefonce='\e[1;31m'
bleufonce='\e[1;34m'
neutre='\e[0;m'
jaune='\e[1;33m'
vertclair='\e[1;32m'
vertclair_clignotant='\e[5;32m'


#une fonction usage qui permet d'expliquer l'utilisation du script à l'utilisateur
usage()
{
	cat <<EOF
Usage: $0 fichier.aiken...
ou     $0 ...-c|--correction... pour avoir un fichier correction à la fin du test
fait passer les questions du ou plusieurs fichier.aiken au candidat
EOF
}

#si aucun argument n'est entré on quitte le programme
case $# in
	
	0)
		echo "manque d argument !"	
		exit 1
		;;
	*) 
		;;
esac

correc_test=0


#creer un dossier temporaire pour heberger les fichiers qu'on va creer pour le supprimer à la fin
#le nom du dossier commence par '_' pour eviter de creer deja un dossier existant pourtant le même nom
mkdir _dtmp



for i; do
	case "$i" in
		#si le fichiers entre sont de l extention aiken on les fusionne tous dans un seul fichier questions
		*.aiken )
				cat $i >> _dtmp/questions
				printf "\n" >> _dtmp/questions
		;;
		# si y a -c dans les arguments on va afficher on a juste l'option de 
		#visualisation de la coorection à la fin en creeant un fichier correction
		"-c"|"--correction")
				correc_test=1
		;;
		*)
			echo "$i : entrée non valide, extension aiken demandée"
			usage
			rm -rf _dtmp
			exit 2
		;;
	esac
done
	
		


for i in $(grep -no "ANSWER: " _dtmp/questions); do
	#cette commande me permet de couper en champs la chaine avec -d on precise celui qui decoupe et -fn ecrire le champ num n
	# | signifie redireger la sortie de la premiere commande vers la deuxieme commande

	echo $i | cut -d':' -f1 >> _dtmp/qcm
		
done
n=1

for i in $(cat _dtmp/qcm); do
 	case $n in
 		1 )
			head -n "$i" _dtmp/questions > "_dtmp/$n.txt"
 			;;
 		* )
 			head -n "$i" _dtmp/questions | tail -n $(($i-$last-1)) >"_dtmp/$n.txt"	
 	esac
 	# on met les noms des fichier dans u fichier en_fichiers un par un à tour de boucle
 	printf "_dtmp/$n.txt\n" >> _dtmp/ens_fichiers
 	last=$i
 	n=$(($n+1))
done

#on initialise la note au maximum et apres pour chaque reponse fausse on met-1
div=$(($n-1))
note=$div

#on inverse les lignes de ens_fichiers (qui contient les noms des fichier des questions) avec la commande sort
sort -R _dtmp/ens_fichiers > _dtmp/ens_fichier

#ainsi on peut lire les noms des fichiers qui sont deja randomisee et ecrire les question 
#et dan cette boucle on va traiter chaque fichier de question 
for i in $(cat _dtmp/ens_fichier); do

	# n va avoir le nombre de ligne de chaque fichierde question
	n=$(wc -l <$i)

	# on sauvgarde la lettre de la reponse juste 
	juste=$(tail -n 1 $i | cut -d' ' -f2 )

	# on pose la question
	echo "${bleufonce}$(head -n 1 $i)${neutre}"
	head -n 1 $i >>correction

	# on affecte les choix dans un fichier tmp
	head -n $(($n-1)) $i | tail -n $(($n-2)) >_dtmp/tmp

	# on separe les champs du fichier tmp
	#ex :
	# A. >> x  choix1 >>z
	# B. >> x  choix2 >>z
	# c. >> x  choix3 >>z

	cut -d' ' -f1 _dtmp/tmp >_dtmp/x


	# ici on cherche la reponse juste d'apres la qu'on a extraite toute à l'heure
	num_ligne_juste=$(cut -d'.' -f1 _dtmp/x | grep -n "$juste" |cut -d':' -f1 )
	rep_juste=$(cut -d' ' -f 2- _dtmp/tmp | head -n $num_ligne_juste | tail -n 1)


	# on trie alors au hasard le fichier ou y a les choix
	cut -d' ' -f 2- _dtmp/tmp | sort -R >_dtmp/z

	# ici on colle les champs des lettres et des choix deja randomisés
	paste -d' ' _dtmp/x _dtmp/z > _dtmp/rand
	printf "${jaune}$(cat _dtmp/rand)${neutre}\n"
	printf "${jaune}$(cat _dtmp/rand)${neutre}\n">> correction	

	printf "\n${bleufonce}quelle est la reponse : ${neutre}"
	IFS= read -r entree_user
	
	num_ligne_user=$(cut -d'.' -f1 _dtmp/x | grep -ni "$entree_user"|cut -d':' -f1)

	while [ -z $num_ligne_user ]; do
		printf "\n${bleufonce}veillez entrer une reponse parmi les choix svp : ${neutre}"
		IFS= read -r entree_user
	
		num_ligne_user=$(cut -d'.' -f1 _dtmp/x | grep -ni "$entree_user"|cut -d':' -f1)
	done
	#[-z chaine] teste si la chaine est vide

	#on met dans la variable rep_user la reponse de l'utilisateur
	rep_user=$(cut -d' ' -f 2- _dtmp/rand | head -n $num_ligne_user | tail -n 1)

	printf "\n${bleufonce}votre rep etait : ${neutre}$rep_user \n\n" >> correction

	#on compare la reponse de l'utilisateur avec la reponse juste et sa note sera evalué en fonction de la reponse
	if [ "$rep_user" = "$rep_juste" ]; then

		echo  "${vertclair}vous avez répondu correctement bravo !${neutre}\n"
		printf "${vertclair}votre reponse est juste !${neutre}\n" >>correction

	else

        printf "\n${rougefonce}c'est faux${neutre}\n"
        note=$(($note-1))
        printf "${rougefonce}votre reponse est fausse${neutre}\n${bleufonce}la bonne rep est : ${neutre}${vertclair}$rep_juste${neutre}\n" >>correction

	fi

		

	printf "\n\n"
	
done


printf "${vertclair_clignotant}votre note est : %d/%d ${neutre}\n" $note $div

#si l'utilisateur a choisi de voir sa correction ou pas 
case $correc_test in
	1)	
		printf "ouvrez le fichier correction pour voir la correction\n"
		;;
	0)
		rm correction
esac

#on supprime le dossier _dtmp qui contient tous les fichiers
rm -rf _dtmp
exit 0


