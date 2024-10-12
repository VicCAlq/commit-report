#!/usr/bin/env bash

case $1 in
*.lua)
    lua -l conf $1
    ;;
*)
    lua -l conf $1.lua
    ;;
esac
