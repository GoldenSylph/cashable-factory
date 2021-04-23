#!/bin/bash

echo Compiling...
truffle compile

if [[ ! -d ../cashable-frontend/src ]]; then
  echo The build folder in frontend does not exists. Creating...
  mkdir ../cashable-frontend/src
fi

echo Copying...
cp -r ./build ../cashable-frontend/src
echo Copied.
