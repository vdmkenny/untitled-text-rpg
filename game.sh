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
  #COMMAND=$(echo $1 | tr -dc '[:alnum:]' | tr '[:upper:]' '[:lower:]')i

  #remove some middle words
  COMMAND=$(echo $COMMAND | sed 's/\sa\s/ /g' | sed 's/\sthe\s/ /g' | sed 's/\ssome\s/ /g')

  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Command issued: $COMMAND"
  fi
 
  #process player command
  WORD1=""
  WORD2=""
  WORD3=""
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
    take )
      case $WORD2 in
        "" ) echo "Take what?"; return 1 ;;
        nap ) echo "You take a short nap, only to feel even worse than before."; return ;;
      esac
      ;;
    go )
      case $WORD2 in
        north ) moveroom 0 +1; return;;
        south ) moveroom 0 -1; return;;
        east )  moveroom -1 0; return;;
        west )  moveroom +1 0; return;;
      esac
      ;;
    quit ) echo "Goodbye." ; exit;;
    * ) echo "I beg you pardon?"; return 1;;
  esac 

}

function moveroom { 
  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}About to move room, calculation: $CURRENTX$1,$CURRENTX$2"
  fi
  #keep last step incase we hit an invalid room
  PREVX=$CURRENTX
  PREVY=$CURRENTY

  CURRENTX=$(echo $(($CURRENTX$1)))
  CURRENTY=$(echo $(($CURRENTY$2)))

  TEST=$(getroomdescription) 
  if ! [ $? -eq 0 ]; then
    #rollback if invalid room
    CURRENTX=$PREVX
    CURRENTY=$PREVY
    echo "You can't go that way."
    return
  fi
  getroomdescription
}

function getroomdescription {
  #which map are we on?
  case "$CURRENTMAP,$CURRENTX,$CURRENTY" in
    "overworld,0,0" ) echo "You find yourself on a crossroad. There is a road in each direction." ; return ;;
    "overworld,0,1" ) echo "You find yourself on a dead end. There is a road to the south." ; return ;;
    "overworld,0,-1" ) echo "You find yourself on a dead end. There is a road to the north." ; return ;;
    "overworld,-1,0" ) echo "You find yourself on a dead end. There is a road to the west." ; return ;;
    "overworld,1,0" ) echo "You find yourself on a road leading to a house. There is a road to the east." ; return ;;
     * ) echo -e "${RED}[ERROR] ${NC}Invalid room. You should not be here." ; return 1;;
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
