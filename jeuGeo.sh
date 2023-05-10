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

# Fonction pour vérifier si le cache est valide
function cache_est_valide() {
  local cache_file=$1
  local cache_duration=$2
  local refresh_cache=$3
  local cache_validity=0

  if [ -f "$cache_file" ]; then
    local cache_timestamp=$(stat -c %Y "$cache_file")
    local current_timestamp=$(date +%s)
    local time_diff=$((current_timestamp - cache_timestamp))
    
    if [ $time_diff -le $cache_duration ]; then
      cache_validity=1
    fi
  fi
  
  if [ $cache_validity -eq 0 ] || [ "$refresh_cache" = "--refreshcache" ]; then
    return 0
  else
    return 1
  fi
}

# Fonction pour interroger l'API et récupérer les informations sur les communes
function recuperer_informations_communes() {
  local code_postal=$1
  local cache_file=".cache_$code_postal.txt"
  local cache_duration=$((60 * 60)) # Durée de vie du cache : 60 minutes
  
  if cache_est_valide "$cache_file" $cache_duration $2; then
    # Utilisation du cache
    communes_array=($(cat "$cache_file"))
  else
    # Requête à l'API
    communes_array=($(curl -s "https://geo.api.gouv.fr/communes?codePostal=$code_postal" | jq -r '.[].nom'))

    # Mise à jour du cache
    echo "${communes_array[@]}" > "$cache_file"
  fi
}

# Fonction pour jouer au jeu
function jouer_jeu_geo() {
  local communes_array=("$@")
  local nb_vies=10
  local commune_index=$((RANDOM % ${#communes_array[@]}))
  local nb_habitants
  local user_input
  
  echo "Avec quelle ville souhaitez-vous jouer ?"
  afficher_menu communes_array
  
  while true; do
    read -p "Choisissez un numéro de ville : " user_input
    if [[ $user_input =~ ^[0-9]+$ ]] && [ $user_input -ge 0 ] && [ $user_input -lt ${#communes_array[@]} ]; then
      break
    else
      echo "Numéro invalide. Veuillez choisir un numéro valide."
    fi
  done
  
  echo "Bienvenue dans le jeu GEO !"
  echo "Devinez le nombre d'habitants dans la ville ${communes_array[$user_input]}."
  
  while [ $nb_vies -gt 0 ]; do
    read -p "Nombre d'habitants : " nb_habitants
    
    if [[ $nb_habitants =~ ^[0-9]+$ ]]; then
      if [ $nb_habitants -eq $nb_habitants_estime ]; then
    echo "Bravo ! Vous avez trouvé le nombre d'habitants dans la ville ${communes_array[$user_input]}."
    return 0
  elif [ $nb_habitants -lt $nb_habitants_estime ]; then
    echo "Plus grand !"
  else
    echo "Plus petit !"
  fi
  nb_vies=$((nb_vies - 1))
  echo "Il vous reste $nb_vies vies."
else
  echo "Saisie invalide. Veuillez saisir un nombre entier."
fi
done

echo "Désolé, vous avez perdu ! Le nombre d'habitants dans la ville ${communes_array[$user_input]} était $nb_habitants_estime."
}

#Vérification de la présence d'un argument
if [ $# -eq 1 ]; then
code_postal=$1
else
while true; do
read -p "Veuillez saisir un code postal : " code_postal
if est_code_postal_valide $code_postal; then
break
else
echo "Code postal invalide. Veuillez saisir un code postal valide."
fi
done
fi

#Récupération des informations sur les communes correspondantes au code postal
recuperer_informations_communes $code_postal $2

#Jeu GEO
jouer_jeu_geo "${communes_array[@]}"