#!/bin/sh

repo forall -c "git checkout tvierling-$1; git pull --rebase"
