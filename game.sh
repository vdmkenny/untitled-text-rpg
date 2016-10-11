#!/bin/bash
#
# Text-based RPG by Kenny Van de Maele
#

#Main Vars
GAMENAME="Placeholder title"
VERSION="v0.0.2"
DEBUG=false
GAMELOOP=true

#Game Vars
PLAYERNAME=""
CURRENTMAP="overworld"
CURRENTX="0"
CURRENTY="0"
HOUSE_CHEST_OPEN=false
HAS_SWORD=false

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
            * ) inspectobject $WORD3; return ;;
          esac
          ;;
	around ) getroomdescription; return ;;
	in|inside ) lookinsideobject $WORD3; return ;;
        * )
      esac
      ;;
    take )
      case $WORD2 in
        "" ) echo "Take what?"; return 1 ;;
        nap ) echo "You take a short nap, only to feel even worse than before."; return ;;
        * ) takeobject $WORD2; return ;;
      esac
      ;;
    go )
      case $WORD2 in
        n|north )   moveroom 0 +1; return;;
        s|south )   moveroom 0 -1; return;;
        e|east )    moveroom -1 0; return;;
        w|west )    moveroom +1 0; return;;
        in|inside ) enterroom $WORD3; return;;
        * ) echo "Go where?"; return;;
      esac
      ;;
    enter ) enterroom $WORD2; return;;
    open )  openobject $WORD2; return;;
    close|shut )  closeobject $WORD2; return;;
    inspect )  inspectobject $WORD2; return;;
    exit )  exitroom; return;;
    quit )  echo "Goodbye." ; exit;;
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

function enterroom { 
  if [ -z $1 ];then
    if $DEBUG; then 
      echo -e "${GREEN}[DEBUG] ${NC}No room specified."
    fi
    echo -e "Where?"
    return
  fi
  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Trying to enter room: $1"
  fi
  #which map are we on?
  case "$CURRENTMAP,$CURRENTX,$CURRENTY" in
    "overworld,1,0" )
      case $1 in
        house ) warp house 0 0; return;; 
      esac
      ;;
     * ) echo "There is no $1 here...";;
  esac
}

function exitroom { 
  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Trying to exit room: $CURRENTMAP,$CURRENTX,$CURRENTY"
  fi
  #which map are we on?
  case "$CURRENTMAP,$CURRENTX,$CURRENTY" in
    "house,0,0" ) warp overworld 1 0;;
     * ) echo "We're already outside!";;
  esac
}
function warp {
  if $DEBUG; then 
     echo -e "${GREEN}[DEBUG] ${NC}Warping to $1,$2,$3"
  fi
  CURRENTMAP=$1
  CURRENTX=$2
  CURRENTY=$3
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
    "house,0,0" ) echo "You're inside a small abandoned house. It's empty, except for a chest in the middle of the room." ; return ;;
     * ) echo -e "${RED}[ERROR] ${NC}Invalid room. You should not be here." ; return 1;;
  esac
}

function openobject { 
  if [ -z $1 ];then
    if $DEBUG; then 
      echo -e "${GREEN}[DEBUG] ${NC}No object specified."
    fi
    echo -e "Open what?"
    return
  fi
  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Trying to open: $1"
  fi
  #which map are we on?
  case "$CURRENTMAP,$CURRENTX,$CURRENTY" in
    "house,0,0" )
      case $1 in
        chest ) 
          if $HOUSE_CHEST_OPEN; then
            echo "It's already opened!"; 
          fi
          if ! $HOUSE_CHEST_OPEN; then
            echo "With a creak of the tired hinges, the chest opens."; 
            HOUSE_CHEST_OPEN=true;
          fi
          return;;
      esac
      ;;
     * ) echo "$1? I don't see a $1!";;
  esac
}

function closeobject { 
  if [ -z $1 ];then
    if $DEBUG; then 
      echo -e "${GREEN}[DEBUG] ${NC}No object specified."
    fi
    echo -e "Close what?"
    return
  fi
  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Trying to close: $1"
  fi
  #which map are we on?
  case "$CURRENTMAP,$CURRENTX,$CURRENTY" in
    "house,0,0" )
      case $1 in
        chest ) 
          if ! $HOUSE_CHEST_OPEN; then
            echo "It's not open to begin with."; 
          fi
          if $HOUSE_CHEST_OPEN; then
            echo "You close the chest's lid, which falls shut with a loud thud."; 
            HOUSE_CHEST_OPEN=false;
          fi
          return;;
      esac
      ;;
     * ) echo "$1? I don't see a $1!";;
  esac
}

function inspectobject { 
  if [ -z $1 ];then
    if $DEBUG; then 
      echo -e "${GREEN}[DEBUG] ${NC}No object specified."
    fi
    echo -e "What now?"
    return
  fi
  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Trying to inspect: $1"
  fi
  #which map are we on?
  case "$CURRENTMAP,$CURRENTX,$CURRENTY" in
    "house,0,0" )
      case $1 in
        chest ) 
          echo "It's chest made of wood. It looks really old and worn."
          if ! $HOUSE_CHEST_OPEN; then
            echo "It's closed shut."; 
          fi
          if $HOUSE_CHEST_OPEN; then
            echo "It's currently open."; 
          fi
          return;;
      esac
      ;;
     * ) echo "$1? I don't see a $1!";;
  esac
}

function lookinsideobject { 
  if [ -z $1 ];then
    if $DEBUG; then 
      echo -e "${GREEN}[DEBUG] ${NC}No object specified."
    fi
    echo -e "Inside what?"
    return
  fi
  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Trying to look inside: $1"
  fi
  #which map are we on?
  case "$CURRENTMAP,$CURRENTX,$CURRENTY" in
    "house,0,0" )
      case $1 in
        chest ) 
          if ! $HOUSE_CHEST_OPEN; then
            echo "The chest is closed, and definitely not transparant. Maybe you should try opening it first?"; 
          fi
          if $HOUSE_CHEST_OPEN; then
		echo "You peer into the chest with hopeful eyes..."
		if $HAS_SWORD; then
			echo "There's nothing in there but dirt."
		else
			echo "There's a shortsword in there! It's obviously well used, but it still looks sharp."
		fi
          fi
          return;;
      esac
      ;;
     * ) echo "$1? I don't see a $1!";;
  esac
}

function takeobject { 
  if [ -z $1 ];then
    if $DEBUG; then 
      echo -e "${GREEN}[DEBUG] ${NC}No object specified."
    fi
    echo -e "Take what?"
    return
  fi
  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Trying to take: $1"
  fi
  #which map are we on?
  case "$CURRENTMAP,$CURRENTX,$CURRENTY" in
    "house,0,0" )
      case $1 in
      sword ) if $HOUSE_CHEST_OPEN; then
                if ! $HAS_SWORD; then
                  HAS_SWORD=true;
                  echo "You pick up the sword from the chest. It makes a pleasing sshinggg sound while doing so.";
		else
		  echo "There was only one... Don't get greedy."
		fi
              else
                echo "I can't see a sword right now.";
              fi
	      return;
      ;;
      * ) echo "I can't see a $1 right now." ;; 
      esac
     ;;
     * ) echo "$1? I don't see a $1!";;
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
