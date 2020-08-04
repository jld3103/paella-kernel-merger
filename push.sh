#!/usr/bin/env bash
set -x
cd kernel || exit 1
git push -f -u origin paella-mainline:master
git branch --unset-upstream
