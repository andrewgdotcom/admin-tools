#!/bin/bash

# A QAD tool to migrate systemd units from under *.wants

for wants in /etc/systemd/system/*.wants; do
  if [[ -d $wants ]]; then
    UNITS=$(find $wants -maxdepth 1 -type f)
    for unit in $UNITS; do
        mv -i $unit /etc/systemd/system
        ln -s ../$(basename $unit) $wants/
    done
  fi
done
