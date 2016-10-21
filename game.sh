#!/bin/bash
#
# Text-based RPG by Kenny Van de Maele
#

#Main Vars
GAMENAME="Untitled Text RPG"
VERSION="v0.0.5"
DEBUG=true
GAMELOOP=true
PROMPT="${BLUE}>${NC}"
SAVEFILE="./savegame"
NEWGAME=true

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
IS_GOBLIN_DEAD=false

#Colors
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#all functions

# Debug
# If debug is set to true,
# echo some debugging info
debug () {

  if $DEBUG
  then
    echo -e "${GREEN}[DEBUG] ${NC} $@"
  fi
}

# Error
# echo the error with the correct colors
error () {
  echo -e "${RED}[ERROR] ${NC} $@"
}

# Echohelp
# help is a cmd in bash, don't overwrite it
echohelp () {
  echo -e "${BLUE}[HELP] ${NC} $@"
}

function checkforsavegame {
#check if there's an existing savegame.
  if [ -f $SAVEFILE  ]; then
  read -p "Savegame found. Continue this adventure? (y/n): " choice
  case "$choice" in
    y|Y ) loadgame;;
    n|N ) return;;
    * ) echo Invalid Choice.; checkforsavegame ;;
  esac
  fi
}

function loadgame {
  if [ -f $SAVEFILE ]; then
    source $SAVEFILE
    debug Loaded save file $SAVEFILE
    echo Savegame loaded.
    echo "Hello again, $PLAYERNAME!"
    getroomdescription
    NEWGAME=false
  else
    debug file $SAVEFILE not found.
    echo No savegame found!
  fi
}

function savegame {
  if [ ! -f $SAVEFILE ]; then
    debug No savefile found. Creating new one.
    touch $SAVEFILE
  fi

  debug Saving variables to $SAVEFILE
  echo "#untitled-text-rpg-savegame" > $SAVEFILE
  echo "#editing this file will probably break your game experience" >> $SAVEFILE
  echo "#this file was created by version $VERSION and may not work in later versions" >> $SAVEFILE
  echo "PLAYERNAME=$PLAYERNAME" >> $SAVEFILE
  echo "CURRENTMAP=$CURRENTMAP" >> $SAVEFILE
  echo "CURRENTX=$CURRENTX" >> $SAVEFILE
  echo "CURRENTY=$CURRENTY" >> $SAVEFILE
  echo "HOUSE_CHEST_OPEN=$HOUSE_CHEST_OPEN" >> $SAVEFILE
  echo "HOUSE_DOOR_OPEN=$HOUSE_DOOR_OPEN" >> $SAVEFILE
  echo "HAS_SWORD=$HAS_SWORD" >> $SAVEFILE
  echo "HAS_CHEST_KEY=$HAS_CHEST_KEY" >> $SAVEFILE
  echo "HAS_FISHING_POLE=$HAS_FISHING_POLE" >> $SAVEFILE
  echo "IS_CHEST_UNLOCKED=$IS_CHEST_UNLOCKED" >> $SAVEFILE
  echo "IS_GOBLIN_DEAD=$IS_GOBLIN_DEAD" >> $SAVEFILE

  echo "Your progress was saved."
}

function playercommand {
  #if no command, go back to game loop
  if [ -z $1 ];then
    debug No command issued.
    return
  fi
  #normalise command
  #COMMAND=$(echo $1 | tr -dc '[:alnum:]' | tr '[:upper:]' '[:lower:]')i

  #remove some middle words
  COMMAND=$(echo $COMMAND | sed 's/\sa\s/ /g' | sed 's/\sthe\s/ /g' | sed 's/\ssome\s/ /g' | sed 's/\son\s/ /g')

  debug Command issued: $COMMAND

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
    grab|take )
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
    stab|kill )
        case $WORD2 in
          goblin ) useobject sword goblin; return;;
          * ) echo "Stab what?"; return;;
        esac
    ;;
    exit )  exitroom; return;;
    show )
      case $WORD2 in
       inventory ) showinventory;;
       * ) echo "Show what?";;
      esac
    ;;
    inventory )  showinventory; return;;
    help )  showhelp; return;;
    load )  loadgame ;;
    save )  savegame ;;
    quit )  echo "Goodbye." ; exit;;
    * ) echo "I beg your pardon?"; return 1;;
  esac

}

function showhelp {
  echohelp "So, you're stuck? Try some of the following commands:"
  echohelp *go north, south, west, east, ...
  echohelp *open X
  echohelp *close X
  echohelp *use X on Y
  echohelp *look at, in X
  echohelp *take X
  echohelp *show inventory
  echohelp *There are lots of other obvious and not so obvious commands!
}

function showinventory {
  HAS_SOMETHING=false
  echo "In your possession, you have:"
  if $HAS_SWORD; then
    echo " * A short sword"
    HAS_SOMETHING=true
  fi
  if $HAS_FISHING_POLE; then
    echo " * A fishing pole"
    HAS_SOMETHING=true
  fi
  if $HAS_CHEST_KEY; then
    echo " * A key"
    HAS_SOMETHING=true
  fi
  if ! $HAS_SOMETHING; then
    echo "...nothing!"
  fi
}

function moveroom {
  debug About to move room, calculation: $CURRENTX$1,$CURRENTX$2
  #keep last step incase we hit an invalid room
  PREVX=$CURRENTX
  PREVY=$CURRENTY

  CURRENTX=$(echo $(($CURRENTX$1)))
  CURRENTY=$(echo $(($CURRENTY$2)))
 
  if [ "$CURRENTMAP,$CURRENTX,$CURRENTY" == "overworld,-2,0" ]; then
    #block path if goblin is alive
    if ! $IS_GOBLIN_DEAD; then 
      #rollback if invalid room
      debug "Goblin is still alive, rolling back movement."
      CURRENTX=$PREVX
      CURRENTY=$PREVY
      echo "You try to pass the goblin, but it agressively blocks your path with his spear, and pushes you back."
      return
    fi
  fi

  #check if room exists
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
    debug No room specified.
    echo -e "Where?"
    return
  fi
  debug Trying to enter room: $1
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
  debug Trying to exit room: $CURRENTMAP,$CURRENTX,$CURRENTY
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
  debug Warping to $1,$2,$3
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
    "overworld,-1,0" ) echo "You're on a path surrounded by trees. It leads either east or west." ; 
    if ! $IS_GOBLIN_DEAD; then
      echo "There's a mean looking goblin blocking the path towards the east. It looks like he's guarding it." 
    else
      echo "A dead goblin is laying in the middle of the path. It's quite brutal."
    fi
    return ;;
    "overworld,-2,0" ) echo "You're on a path ending at the entrance of a cave. To the west, it goes back into the woods." ; return ;;
    "overworld,1,0" ) echo "You find yourself on a road leading to a derelict cabin. The road goes east and west." ; return ;;
    "overworld,2,0" ) echo "The path leads onto a dead end. There's a small open area surrounded by trees. In the center of this clearing, there is a perfect circle of mushrooms growing." ; return ;;
    "house,0,0" ) echo "You're inside a small abandoned cabin. It's mostly empty, but there's an rickety table in the center of the room with a small chest on it. There's also some fishing supplies in the corner, and a very disturbing painting of a clown on the wall." ; return ;;
    * ) error Invalid room. You should not be here; return 1;;
  esac
}

function openobject {
  if [ -z $1 ];then
    debug No object specified.
    echo -e "Open what?"
    return
  fi
  debug Trying to open: $1
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
    debug No object specified.
    echo -e "Close what?"
    return
  fi
  debug Trying to close: $1
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
    debug No object specified.
    echo -e "What now?"
    return
  fi
  debug Trying to inspect: $1
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
    "overworld,-1,0" )
      case $1 in
        goblin )
          if $IS_GOBLIN_DEAD; then
            echo "It's very dead."
          else
            echo "A very mean and agressive creature. It has a pale, greenish skin, and is dressed in shoddy, makeshift armour. Despite this, it has both the size and intelligence of a 6 year old."
          fi
        ;;
        * ) echo "$1? I don't see a $1!";;
      esac
    ;;
    * ) echo "$1? I don't see a $1!";;
  esac
}

function lookinsideobject {
  if [ -z $1 ];then
    debug No object specified.
    echo -e "Inside what?"
    return
  fi
  debug Trying to look inside: $1
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
    debug No object specified.
    echo -e "Take what?"
    return
  fi
  debug Trying to take: $1
  #which map are we on?
  case "$CURRENTMAP,$CURRENTX,$CURRENTY" in
    "house,0,0" )
      case $1 in
        shortsword|sword ) if $HOUSE_CHEST_OPEN; then
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
    "overworld,0,-1" )
      case $1 in
        shiny|key ) echo "The well it too deep, you can't reach it!" ;;
        * ) echo "$1? I don't see a $1!" ;;
      esac
    ;;
    * ) echo "$1? I don't see a $1!";;
  esac
}

function useobject {
  OBJECT1=$1
  OBJECT2=$2

  if [ -z $1 ];then
    debug No use object specified.
    echo -e "Use what?"
    return
  fi
  if [ -z $2 ];then
    debug No object to use on specified.
    echo -e "Use it on what?"
    return 1
  fi
  #incase of "fishing pole or fishing rod"
  if [[ "$2" == "pole" ]] || [[ "$2" == "rod" ]]; then
    debug Shifting object arguments because of fishing pole.
    OBJECT1=$2
    OBJECT2=$3
  fi
  debug Trying to use $OBJECT1 on $OBJECT2
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
    key )
      case $OBJECT2 in
        chest|lock )
          if $HAS_CHEST_KEY; then
            if [[ "$CURRENTMAP,$CURRENTX,$CURRENTY" == "house,0,0" ]]; then
              echo "You unlock the chest using the key."
              IS_CHEST_UNLOCKED=true
            else
              echo "There's no $OBJECT2 around, I'm afraid."
            fi
          else
            echo "This would be a smart thing to do... If you actually had a key.";
          fi
        ;;
        * ) echo "That sounds fun... but I better not."
      esac
    ;;
    sword )
      if $HAS_SWORD; then
        case $OBJECT2 in
          goblin ) 
            if ! $IS_GOBLIN_DEAD; then
              echo "Not expecting your sudden attack, you manage to cleanly stab the goblin between the ribs. It's eyes widen, and falls to floor. Some dark green blood pools around him."
              IS_GOBLIN_DEAD=true
            else
              echo "That's just morbid."
            fi
          ;;
          * ) echo "Stab a $OBJECT2? Why?";;
        esac
      else
        echo "Stabbing something is much easier when you have something pointy."
      fi
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
debug ${GREEN}Debug mode enabled${NC}
echo

#check for exiting savegames first
checkforsavegame
if $NEWGAME; then
  #get playername
  echo "What is your name, adventurer?"
  read -rp "$PROMPT" PLAYERNAME

  #if playername is null, repeat
  while [ -z "$PLAYERNAME" ]; do
    echo "I didn't quite hear that..."
    read -rp "$PROMPT" PLAYERNAME
  done
  echo -e "Hello, $PLAYERNAME!"
fi

#Main gameloop
echo "What will you do?"
read -rp "$PROMPT" COMMAND
playercommand $COMMAND
while $GAMELOOP; do
  read -rp "$PROMPT" COMMAND
  if playercommand $COMMAND; then echo "What will you do?"; fi

  debug Player location: $CURRENTMAP,$CURRENTX,$CURRENTY
done
