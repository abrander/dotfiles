#!/bin/bash

alias gitst='git status ; git log @{u}.. --pretty=oneline'
alias gitdi='git diff'
alias gitch='git checkout'

export MANPAGER="sh -c 'col -bx | batcat -l man -p'"

__gitstatus() {
	# Look for a .mute file. Useful for slow
	# filesystems or slow servers.
	local MUTED=0
	x=`pwd`
	while [ "$x" != "/" ] ; do
		test -f "$x/.gitmute" && MUTED=1
		x=`dirname "$x"`
	done

	if [[ "$MUTED" == "1" ]]; then
		echo MUTED
		return 0
	fi

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

# Cache the hostname. It rarely changes.
__HOSTNAME=$(hostname -f)

__COLOR=$(cat ~/.color 2>/dev/null || echo -en "\033[01;36m")

__set_title() {
	# BASH_COMMAND is not reliable here. We must parse history.
	local CMD=$(history 1 | cut -c8-)

	local TITLE="${__HOSTNAME}: ${CMD} ${__CWD}"

	echo -en "\033]0;${TITLE}\007"
}

__reset_colors() {
	echo -en "\033[0m"
}

PS0='$(__timer_start)$(__reset_colors)$(typeset __CWD="\w";__set_title)'

# initialize the first command execution to avoid starting with a highlighted exitcode.
__commands[1]=

__build_ps1() {
	local EXITCODE="$?"

	# Colors
	local RESET='\[\033[00m\]'
	local GREEN='\[\033[01;32m\]'
	local CYAN='\[\033[36m\]'
	local ERROR='\[\033[1;37;41m\]'
	local BLACK='\[\033[0;30;30m\]'

	local TITLE='\[\033]0;\h: \w\007\]'

	if (($EXITCODE != 0)); then
		local EXITCOLOR="${ERROR}"
	fi

	PS1="${TITLE}${RESET}(${EXITCOLOR}\${__commands[\#]+${BLACK}}${EXITCODE}\${__commands[\#]=}${RESET}) $(__timer_elapsed) \[${__COLOR}\]\h${RESET}:${GREEN}\w${RESET} [${CYAN}$(__gitstatus)${RESET}]\$ \[${__COLOR}\]"
}

PROMPT_COMMAND='__build_ps1'

export GOPATH=$HOME
export PATH=$PATH:$GOPATH/bin:$HOME/.local/bin

alias ..="cd .."
alias -- -="cd -"
alias less="less -R"
alias cgrep="grep --include \*.c -r --color=always -A 6 -B 6 -n"
alias hgrep="grep --include \*.h -r --color=always -A 6 -B 6 -n"
alias pgrep='grep --include \*.php -r --color=always -A 2 -B 2 -n'
alias gogrep='grep --include \*.go -r --color=always -A 2 -B 2 -n'
alias jsgrep='grep --include \*.js -r --color=always -A 2 -B 2 -n'
alias htgrep='grep --include \*.html -r --color=always -A 2 -B 2 -n'
alias jgrep='grep --include \*.java -r --color=always -A 2 -B 2 -n'

# For Docker
alias dip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"
