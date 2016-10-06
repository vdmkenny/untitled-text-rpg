#!/bin/bash
#
# Text-based RPG by Kenny Van de Maele
#

#Main Vars
GAMENAME="Placeholder title"
VERSION="v0.0.1a"
DEBUG=false
GAMELOOP=true

#Game Vars
PLAYERNAME=""
CURRENTMAP="overworld"
CURRENTX="0"
CURRENTY="0"

#Colors
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#all functions

function playercommand {
  #if no command, go back to game loop
  if [ -z $1 ];then
    if $DEBUG; then 
      echo -e "${GREEN}[DEBUG] ${NC}No command issued."
    fi
    return
  fi
  #normalise command
  #COMMAND=$(echo $1 | tr -dc '[:alnum:]' | tr '[:upper:]' '[:lower:]')

  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Command issued: $COMMAND"
  fi
 
  #process player command

  #check for multiple words
  if [[ $COMMAND == *" "* ]]; then
    WORD1=$(echo $COMMAND | cut -d " " -f 1)
    WORD2=$(echo $COMMAND | cut -d " " -f 2)
    WORD3=$(echo $COMMAND | cut -d " " -f 3)
  else
    WORD1=$COMMAND
  fi

  case $WORD1 in
    look )
      case $WORD2 in
        "" ) getroomdescription ; return;;
        at ) 
          case $WORD3 in
            "" ) echo "look at what?"; return 1;;
            floor|ground ) echo "It's dirty."; return ;;
            sky ) echo "It's blue."; return ;;
            room|area ) getroomdescription; return ;;
          esac
          ;;
        * )
      esac
      ;;
    * ) echo "I beg you pardon?"; return 1;;
  esac 

}

function getroomdescription {
  #which map are we on?
  case "$CURRENTMAP,$CURRENTX,$CURRENTY" in
    "overworld,0,0" ) echo "You find yourself in the starting area." ;;
     * ) echo "${RED}[ERROR] ${NC}Invalid room. You should not be here." return; ;;
  esac
}

COMMAND=""
#clear the terminal
clear
#New Game Introduction
echo -e "Welcome to ${RED}$GAMENAME $VERSION!${NC}"
#check if we are in debug
if $DEBUG; then
  echo -e "${GREEN}Debug mode enabled${NC}"
fi
echo

#get playername
echo "What is your name, adventurer?"
read -rp ">" PLAYERNAME

#if playername is null, repeat
while [ -z $PLAYERNAME ]; do
  echo "I didn't quite hear that..."
  read -rp ">" PLAYERNAME
done
#make playername blue always
PLAYERNAME="${BLUE}$PLAYERNAME${NC}"

echo
echo -e "Hello, $PLAYERNAME!"

#Main gameloop
echo "What will you do?"
read -rp ">" COMMAND
playercommand $COMMAND
while $GAMELOOP; do
  read -rp ">" COMMAND
  if playercommand $COMMAND; then echo "What will you do?"; fi

  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Player location: $CURRENTMAP,$CURRENTX,$CURRENTY"
  fi
done
