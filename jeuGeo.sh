#!/bin/bash

# Fonction pour vérifier si un argument est un code postal valide (5 chiffres)
function is_valid_postal_code() {
  local code=$1
  if [[ $code =~ ^[0-9]{5}$ ]]; then
    return 0
  else
    return 1
  fi
}

# Fonction pour récupérer les informations sur les communes correspondantes à un code postal
function get_communes() {
  local code=$1
  local url="https://geo.api.gouv.fr/communes?codePostal=$code&fields=nom"
  local response=$(curl -s $url)
  echo $response | jq -r '.[].nom'
}

# Fonction principale du jeu
function play_game() {
  local code=$1
  local communes=($(get_communes $code))
  local num_communes=${#communes[@]}
  local lives=10
  local answer=""
  
  echo "Bienvenue dans le jeu GEO !"
  echo "Vous devez deviner le nombre d'habitants d'une commune."
  echo "Choisissez une commune parmi les suivantes :"
  
  for ((i=0; i<num_communes; i++)); do
    echo "[$i] ${communes[$i]}"
  done
  
  echo ""
  
  while [[ $lives -gt 0 ]]; do
    echo "Avec quelle ville souhaitez-vous jouer ?"
    read -p "Entrez le numéro de la commune : " choice
    if [[ $choice =~ ^[0-9]+$ ]] && (( choice >= 0 )) && (( choice < num_communes )); then
      break
    else
      echo "Numéro invalide. Veuillez réessayer."
    fi
  done
  
  echo ""
  
  local chosen_commune="${communes[$choice]}"
  
  echo "Vous avez choisi : $chosen_commune"
  echo "Devinez le nombre d'habitants :"
  
  while [[ $lives -gt 0 ]]; do
    read -p "Entrez un nombre entier : " answer
    if [[ $answer =~ ^[0-9]+$ ]]; then
      local population=$(curl -s "https://geo.api.gouv.fr/communes?nom=$chosen_commune&fields=population")
      local target_population=$(echo $population | jq -r '.[0].population')
      
      if [[ $answer -gt $target_population ]]; then
        echo "Moins !"
      elif [[ $answer -lt $target_population ]]; then
        echo "Plus !"
      else
        echo "Félicitations ! Vous avez trouvé le bon nombre d'habitants."
        return 0
      fi
      
      lives=$((lives-1))
      echo "Vies restantes : $lives"
    else
      echo "Nombre invalide. Veuillez réessayer."
    fi
  done
  
  echo "Vous avez épuisé toutes vos vies. Le nombre d'habitants était $target_population."
  return 1
}

# Point d'entrée du script

if [[ $# -gt 0 ]] && is_valid_postal_code $1; then
  play_game $1
else
  while true; do
    read -p "Veuillez saisir un code postal valide : " code
    if is_valid_postal_code $code;
    then
      play_game $code
      break
    else
      echo "Code postal invalide. Veuillez réessayer."
    fi
  done
fi