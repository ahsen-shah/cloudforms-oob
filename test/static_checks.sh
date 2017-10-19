#!/bin/bash

# ShellCheck
shopt -s globstar
shellcheck -- **/*.sh
