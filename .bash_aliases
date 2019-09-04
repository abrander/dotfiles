#!/bin/bash

alias gitst='git status ; git log @{u}.. --pretty=oneline'
alias gitdi='git diff'
alias gitch='git checkout'

__gitstatus() {
	branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

	# If git rev-parse doesn't return 0, we're not in a git controlled directory
	if [ "${?}" != "0" ]; then
		exit
	fi

	remote="$(git config --get branch.${branch}.remote 2>/dev/null)/${branch} "
	remoterev="$(git log -n 1 --pretty="format:%h" ${remote} 2>/dev/null) "

	ver="git ${remote} ${remoterev} "

	while read -r line
	do
		if [ "${line[0]}" = "??" ]; then
			ver="$ver-"
		else
			ver="${ver}${line}"
		fi
	done < <(git status --porcelain 2>/dev/null | awk '{print $1}')

	AHEAD=$(git log @{u}.. --pretty=oneline | wc -l)
	if [ "${AHEAD}" != "0" ]; then
		ver="$ver +${AHEAD}"
	fi

	BEHIND=$(git log ..@{u} --pretty=oneline | wc -l)
	if [ "${BEHIND}" != "0" ]; then
		ver="$ver -${BEHIND}"
	fi

	echo $ver
}

TIMINGPATH=/dev/shm/start.$BASHPID

__now() {
	# Milliseconds since Epoch
	echo $(($(date +%s%N)/1000000))
}

__timer_start() {
	__now > $TIMINGPATH
}

__timer_elapsed() {
	local NOW=$(__now)
	local START=$(cat $TIMINGPATH 2>/dev/null)

	rm -f $TIMINGPATH

	if [ ! -z $START ]; then
		local ELAPSED=$(($NOW - $START))

		if (($ELAPSED < 60000)); then
			printf "[%5dms]" $ELAPSED
		else
			printf "[%6ds]" $(($ELAPSED/1000))
		fi
	else
		echo "[       ]"
	fi
}

PS0='$(__timer_start)'

# initialize the first command execution to avoid starting with a highlighted exitcode.
__commands[1]=

__build_ps1() {
	local EXITCODE="$?"

	# Colors
	local RESET='\[\033[00m\]'
	local BLUE='\[\033[01;34m\]'
	local GREEN='\[\033[01;32m\]'
	local CYAN='\[\033[36m\]'
	local ERROR='\[\033[1;37;41m\]'
	local BLACK='\[\033[0;30;30m\]'

	if (($EXITCODE != 0)); then
		local EXITCOLOR="${ERROR}"
	fi

	PS1="\# (${EXITCOLOR}\${__commands[\#]+${BLACK}}${EXITCODE}\${__commands[\#]=}${RESET}) $(__timer_elapsed) ${BLUE}\h${RESET}:${GREEN}\w${RESET} [${CYAN}$(__gitstatus)${RESET}]\$ "
}

PROMPT_COMMAND='__build_ps1'

export GOPATH=$HOME

alias less="less -R"
alias cgrep="grep --include \*.c -r --color=always -A 6 -B 6 -n"
alias hgrep="grep --include \*.h -r --color=always -A 6 -B 6 -n"
alias pgrep='grep --include \*.php -r --color=always -A 2 -B 2 -n'
alias gogrep='grep --include \*.go -r --color=always -A 2 -B 2 -n'
alias jsgrep='grep --include \*.js -r --color=always -A 2 -B 2 -n'
alias htgrep='grep --include \*.html -r --color=always -A 2 -B 2 -n'

# For Docker
alias dip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"
