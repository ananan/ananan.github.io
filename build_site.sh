#!/bin/bash

mkdocs build
cp -R site/* ../
git add ./
git commit -m "Mod"
git push origin master


