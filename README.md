# projet_bash

Le but du projet est de comparer deux dossiers entre eux et connaître leurs différences.

Pour avoir la liste des commandes disponibles :

```
main.bash -h
```

## Fonctionalitées

- liste les fichiers différents (nouveaux et/ou modifiés)
- créé un fichier avec la liste des fichiers différents
- affiche l'arborescence du premier et/ou deuxième dossier sous forme d'arbre coloré avec toutes les informations
- l'arborescence en arbre peut être exporté en html

## Exemples

On va comparer les dossiers de tests : dossier_1 et dossier_2.

Pour avoir la liste des fichiers différents :

```
main.bash --ficdiff dossier_1 dossier_2
```

Pour créer le fichier (fichiers_diff) contenant les différences :

```
main.bash --ficfdiff dossier_1 dossier_2
```

Pour afficher l'arborescence du dossier_2 sous forme d'arbre :

```
main.bash --arb2 dossier_1 dossier_2
```

On enlève les fichiers identiques :

```
main.bash --arb2 --non-arbid dossier_1 dossier_2
```

Pour l'exporter en html (fichier diff.html) :

```
main.bash --arb2 --non-arbid --siteweb dossier_1 dossier_2
```
