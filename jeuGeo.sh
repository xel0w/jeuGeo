#!/bin/bash

function cpValid() {
  local code=$1
  if [[ $code =~ ^[0-9]{5}$ ]]; then
    return 0
  else
    return 1
  fi
}

function getCommunes() {
  local code=$1
  local url="https://geo.api.gouv.fr/communes?codePostal=$code&fields=nom,code"
  local response=$(curl -s "$url")
  local communes=($(echo "$response" | jq -r '.[] | .nom + "," + .code'))
  echo "${communes[@]}"
}


# Fonction principale du jeu
function play() {
  local code=$1
  local communes=($(getCommunes $code))
  local num_communes=${#communes[@]}
  local lives=10
  local answer=""

  
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
local code_insee=$(echo "$chosen_commune" | cut -d "," -f 2)
  
  echo "Vous avez choisi : $chosen_commune"
  echo "Devinez le nombre d'habitants :"
  
  while [[ $lives -gt 0 ]]; do
    read -p "Entrez un nombre entier : " answer
    if [[ $answer =~ ^[0-9]+$ ]]; then
        local population=$(curl -s "https://geo.api.gouv.fr/communes/$code_insee?fields=population")
        local target_population=$(echo "$population" | jq -r '.population')
      
      if [[ $answer -gt $target_population ]]; then
        echo "Moins"
      elif [[ $answer -lt $target_population ]]; then
        echo "Plus"
      else
        echo "Vous avez trouvé le bon nombre d'habitants."
        return 0
      fi
      
      lives=$((lives-1))
      echo "Vies restantes : $lives"
    else
      echo "Nombre invalide."
    fi
  done
  
  echo "Perdu. Le nombre d'habitants était $target_population."
  return 1
}


if [[ $# -gt 0 ]] && cpValid $1; then
  play $1
else
  while true; do
    read -p "Saisissez un code postal valide : " code
    if cpValid $code;
    then
      play $code
      break
    else
      echo "Code postal invalide."
    fi
  done
fi