#!/bin/bash
#
# MUD Game by Kenny Van de Maele
#

#Main Vars
GAMENAME="Placeholder title"
VERSION="v0.0.1a"
DEBUG=true
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
  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Command issued: $1"
  fi
}

function getroom {
  echo  
}

#New Game Introduction
echo -e "Welcome to ${RED}$GAMENAME $VERSION!${NC}"
#check if we are in debug
if $DEBUG; then
  echo -e "${GREEN}Debug mode enabled${NC}"
fi
echo

COMMAND=""
#clear the terminal
clear

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
while $GAMELOOP; do
  echo "What will you do?"
  read -rp ">" COMMAND
 
  playercommand $COMMAND

  if $DEBUG; then 
    echo -e "${GREEN}[DEBUG] ${NC}Player location: $CURRENTMAP,$CURRENTX,$CURRENTY"
  fi
done
