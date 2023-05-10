#!/bin/bash

# Fonction pour afficher le menu des communes
function afficher_menu() {
  local -n communes_array=$1
  for ((i=0; i<${#communes_array[@]}; i++)); do
    echo "[$i] ${communes_array[$i]}"
  done
}

# Fonction pour vérifier si un argument est un code postal valide (5 chiffres)
function est_code_postal_valide() {
  local code_postal=$1
  if [[ $code_postal =~ ^[0-9]{5}$ ]]; then
    return 0
  else
    return 1
  fi
}

# Fonction pour interroger l'API et récupérer les informations sur les communes
function recuperer_informations_communes() {
  local code_postal=$1
  local communes_array=()

  # Requête à l'API
  communes_json=$(curl -s "https://geo.api.gouv.fr/communes?codePostal=$code_postal")

  # Extraction des noms des communes
  while IFS= read -r line; do
    commune=$(echo "$line" | jq -r '.nom')
    communes_array+=("$commune")
  done <<< "$communes_json"

  echo "${communes_array[@]}"
}

# Vérification de la présence d'un argument
if [ $# -eq 1 ]; then
  code_postal=$1
else
  while true; do
    read -p "Veuillez saisir un code postal : " code_postal
    if est_code_postal_valide "$code_postal"; then
      break
    else
      echo "Code postal invalide. Veuillez saisir un code postal valide."
    fi
  done
fi

# Récupération des informations sur les communes correspondantes au code postal
communes_array=($(recuperer_informations_communes "$code_postal"))

# Vérification s'il y a des communes disponibles
if [ ${#communes_array[@]} -eq 0 ]; then
  echo "Aucune commune trouvée pour ce code postal."
  exit 1
fi

# Affichage du menu des communes
echo "Avec quelle ville souhaitez-vous jouer ?"
afficher_menu communes_array

# Définition du nombre de vies
nb_vies=10

# Sélection de la commune
while true; do
  read -p "Choisissez un numéro de ville : " choix_ville
  if [[ $choix_ville =~ ^[0-9]+$ ]] && [ $choix_ville -ge 0 ] && [ $choix_ville -lt ${#communes_array[@]} ]; then
    break
  else
    echo "Numéro invalide. Veuillez choisir un numéro valide."
  fi
done

ville_selectionnee="${communes_array[$choix_ville]}"
echo "Bienvenue dans le jeu GEO ! Vous avez choisi la ville $ville_selectionnee."

# Jeu GEO
while [ $nb_vies -gt 0 ]; do
  read -p "Devinez le nombre d'habitants dans la ville $ville_selectionnee : " estimation

  if [[ $estimation =~ ^[0-9]+$ ]]; then
    habitants=$(curl -s "https://geo.api.gouv.fr/communes?nom=$ville_selectionnee&codePostal=$code_postal" | jq -r '.[0]')
  if [ $estimation -eq $habitants ]; then
    echo "Félicitations ! Vous avez deviné le bon nombre d'habitants."
    break
  elif [ $estimation -lt $habitants ]; then
    echo "C'est moins. Essayez encore !"
  else
    echo "C'est plus. Essayez encore !"
  fi

  nb_vies=$((nb_vies - 1))

  if [ $nb_vies -eq 0 ]; then
    echo "Dommage ! Vous avez épuisé toutes vos vies."
    break
  fi

  echo "Il vous reste $nb_vies vies."
done

echo "Merci d'avoir joué au jeu GEO !"
