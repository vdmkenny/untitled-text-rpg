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
HOUSE_DOOR_OPEN=false
HAS_SWORD=false
HAS_CHEST_KEY=false
HAS_FISHING_POLE=false
IS_CHEST_UNLOCKED=false

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
  COMMAND=$(echo $COMMAND | sed 's/\sa\s/ /g' | sed 's/\sthe\s/ /g' | sed 's/\ssome\s/ /g' | sed 's/\son\s/ /g')
  
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
    WORD4=$(echo $COMMAND | cut -d " " -f 4)
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
        in|inside|down ) lookinsideobject $WORD3; return ;;
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
    use )  useobject $WORD2 $WORD3 $WORD4; return;;
    fish ) if [[ $WORD2 == "in" ]] || [[ $WORD2 == "down" ]]; then
        useobject pole $WORD3; return
      else
        useobject pole $WORD2; return
      fi
    ;;
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
        house|cabin )
          if $HOUSE_DOOR_OPEN; then
            warp house 0 0; return;
          else
            echo "The door is closed.";
          fi
        ;;
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
    "house,0,0" ) 	if $HOUSE_DOOR_OPEN; then
        echo "You exit the cabin."
        warp overworld 1 0;
      else
        echo "You can't walk through doors, dummy.";
      fi
    ;;
    
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
    "overworld,0,-1" ) echo "You're on a dead end, leading to an old water well. There is a road to the north." ; return ;;
    "overworld,-1,0" ) echo "You find yourself on a dead end. There is a road to the west." ; return ;;
    "overworld,1,0" ) echo "You find yourself on a road leading to a derelict cabin. There is a road to the east." ; return ;;
    "house,0,0" ) echo "You're inside a small abandoned cabin. It's mostly empty, but there's an rickety table in the center of the room with a small chest on it. There's also some fishing supplies in the corner, and a very disturbing painting of a clown on the wall." ; return ;;
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
          if $HAS_CHEST_KEY; then
            if ! $IS_CHEST_UNLOCKED; then
              IS_CHEST_UNLOCKED=true
              echo "You unlock the chest using the key."
            fi
            if $HOUSE_CHEST_OPEN; then
              echo "It's already opened!";
            fi
            if ! $HOUSE_CHEST_OPEN; then
              echo "With a creak of the tired hinges, the chest opens.";
              HOUSE_CHEST_OPEN=true;
            fi
            return
          else
            echo "You try to open the chest, but notice it is locked securely."
          fi
        ;;
        lock )
          if $IS_CHEST_UNLOCKED; then
            echo "It's already open!";
          fi
          if ! $IS_CHEST_UNLOCKED; then
            if ! $HAS_CHEST_KEY; then
              echo "You'll need a key for that.";
            else
              echo "You unlock the chest using the key.";
              IS_CHEST_UNLOCKED=true
            fi
          fi
        return;;
        door )
          if $HOUSE_DOOR_OPEN; then
            echo "It's wide open.";
          fi
          if ! $HOUSE_DOOR_OPEN; then
            echo "The door sticks quite badly, but you managed to push it open.";
            HOUSE_DOOR_OPEN=true;
          fi
        return;;
        * ) echo "Open what now?"; return;;
      esac
    ;;
    "overworld,1,0" )
      case $1 in
        door )
          if $HOUSE_DOOR_OPEN; then
            echo "It's wide open.";
          fi
          if ! $HOUSE_DOOR_OPEN; then
            echo "The door sticks quite badly, but you managed to push it open.";
            HOUSE_DOOR_OPEN=true;
          fi
        return;;
        * ) echo "Open what now?"; return;;
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
        door )
          if $HOUSE_DOOR_OPEN; then
            echo "You close the door like a civilised person.";
            HOUSE_DOOR_OPEN=false
          else
            echo "It's already closed!";
          fi
        return;;
        * ) echo "Open what now?"; return;;
      esac
    ;;
    "overworld,1,0" )
      case $1 in
        door )
          if $HOUSE_DOOR_OPEN; then
            echo "You close the door like a civilised person.";
            HOUSE_DOOR_OPEN=false
          else
            echo "It's already closed!";
          fi
        return;;
        * ) echo "Open what now?"; return;;
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
        table ) echo "It doesn't look very sturdy... or sanitary, for that matter.";;
        fishing|supplies )
          if ! $HAS_FISHING_POLE; then
            echo "A fishing pole and some lures. It's seen better days, but you can probably still catch fish with it."
          else
            echo "A pile of used fishing nick-nacks. After taking the pole, there's nothing useful left."
          fi
        ;;
        clown|painting ) echo "Creepy... It looks like it's eyes are following wherever you go in the room. I'm sure it's just an illusion.";;
        * ) echo "I'm not sure what you're referring to."; return;;
      esac
    ;;
    "overworld,0,-1" )
      case $1 in
        well )
          echo "It's an old, dried up well. Even the bucket is long gone.";
        ;;
        * ) echo "I'm not sure what you're referring to."; return;;
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
        * ) echo "Look inside what?";
      esac
    ;;
    "overworld,0,-1" )
      case $1 in
        well )
          echo "You peer down the well. As expected it's all dried up."
          if ! $HAS_CHEST_KEY; then
            echo "If you look closely, you can just about see something shiny down there.";
          fi
        ;;
        * ) echo "I'm not sure what you're referring to."; return;;
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
        fishing|pole|rod )
          if ! $HAS_FISHING_POLE; then
            HAS_FISHING_POLE=true;
            echo "You take the fishing pole. You're tempted to swing it at something, but resist the urge.";
          else
            echo "There's nothing useful left to take."
          fi
          return;
        ;;
        chest ) echo "It seems a bit heavy for that.";;
        lure* ) echo "I don't think I want those right now.";;
        * ) echo "I can't see a $1 right now." ;;
      esac
    ;;
    * ) echo "$1? I don't see a $1!";;
  esac
}

function useobject {
  echo "arguments: $1 $2 $3"
  
  OBJECT1=$1
  OBJECT2=$2
  
  if [ -z $1 ];then
    if $DEBUG; then
      echo -e "${GREEN}[DEBUG] ${NC}No use object specified."
    fi
    echo -e "Use what?"
    return
  fi
  if [ -z $2 ];then
    if $DEBUG; then
      echo -e "${GREEN}[DEBUG] ${NC}No object to use on specified."
    fi
    echo -e "Use it on what?"
    return 1
  fi
  #incase of "fishing pole or fishing rod"
  if [[ "$2" == "pole" ]] || [[ "$2" == "rod" ]]; then
    if $DEBUG; then
      echo -e "${GREEN}[DEBUG] ${NC}Shifting object arguments because of fishing pole."
    fi
    OBJECT1=$2
    OBJECT2=$3
  fi
  if $DEBUG; then
    echo -e "${GREEN}[DEBUG] ${NC}Trying to use $OBJECT1 on $OBJECT2"
  fi
  #which item are we using?
  case "$OBJECT1" in
    pole|rod )
      case $OBJECT2 in
        well|water )
          if $HAS_FISHING_POLE; then
            if [[ "$CURRENTMAP,$CURRENTX,$CURRENTY" == "overworld,0,-1" ]]; then
              if ! $HAS_CHEST_KEY; then
                HAS_CHEST_KEY=true
                echo "You throw your fishing line down the well... reeling in a shiny key!"
              else
                echo "You throw your fishing line down the well... But it seems there's nothing left to fish."
              fi
            else
              echo "There's no well around."
            fi
          else
            echo "You don't have a fishing pole!";
          fi
        ;;
        * ) echo "That sounds fun... but I better not."
      esac
    ;;
    * ) echo "A $1? I don't think you have one of those..." ;;
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
