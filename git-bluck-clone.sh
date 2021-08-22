#!/bin/bash

if [! "$(git --version)" ]; then
    echo "This script requires git!" && exit 1
fi

readarray array <<< $( cat "$@" )

mkdir -p ~/git && cd ~/git

for element in ${array[@]}
do
  echo "cloning $element"
  git clone $element
done