#!/bin/sh

git add . && git commit -m $1 && git push -u && \
cp ./README.md ~/Desktop/ && cp Source/Backgroundable.swift ~/Desktop/ && \
git checkout submodule && \
cp ~/Desktop/README.md ./ && cp ~/Desktop/Backgroundable.swift ./Source/ && \
git add . && git commit -m $1 && git push -u && \
git checkout master && \
git tag $2 && git push --tag && \
rm -rf ~/Desktop/README.md && rm -rf ~/Desktop/Backgroundable.swift
