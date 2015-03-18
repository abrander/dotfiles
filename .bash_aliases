#!/bin/bash

svnup() {
	php -- $1 << 'EOF'
<?php

$cmd = "svn up --non-interactive";

if ($_SERVER['argc'] > 1)
    $cmd .= " -r {$_SERVER['argv'][1]}";

echo "Executing '{$cmd}'\n";

$svn_res = popen($cmd, 'r');

while ($line = fgets($svn_res))
{
	$line = trim($line);
	$pre = substr($line, 0, 4);
	switch ($pre)
	{
		case 'A   ':
			echo("\033[32m");
			break;
		case 'D   ':
			echo("\033[33m");
			break;
		case 'U   ':
			echo("\033[0m");
			break;
		case 'C   ':
			echo("\033[41m");
			break;
		case 'G   ':
			echo("\033[35m");
			break;
	}

	echo("{$line}\033[0m\n");
}

pclose($svn_res);
?>
EOF
}

svnst() {
	php $* << 'EOF'
<?php

$cmd = "svn st --non-interactive | sort";

if ($_SERVER['argc'] > 1)
    $cmd .= " {$_SERVER['argv'][1]}";

echo "Executing '{$cmd}'\n";

$svn_res = popen($cmd, 'r');

while($line = fgets($svn_res))
{
	$line = trim($line);
	$pre = substr($line, 0, 3);
	switch ($pre)
	{
		case 'A  ':
			echo("\033[32m");
			break;
		case 'M  ':
			echo("\033[33m");
			break;
		case 'D  ':
			echo("\033[31m");
			break;
		default:
			echo("\033[0m");
			break;
	}

	echo("{$line}\033[0m\n");
}

pclose($svn_res);
?>
EOF
}

svndi() {
	svn diff $* -x "-p -u" | colordiff
}

alias gitst='git status ; git log @{u}.. --pretty=oneline'
alias gitdi='git diff'
alias gitch='git checkout'

__svnstatus() {
	ver="$(svnversion)"

	# Early svn use "exported" for non-svn directories, later use "Unversioned directory"
	if [ ! "$ver" = "exported" ] && [ ! "$ver" = "Unversioned directory" ]; then
		echo "svn ${ver}"
	else
		echo ""
	fi
}

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

__vcsstatus() {
	VERSION=$(__svnstatus)

	if [ "${VERSION}" = "" ]; then
		VERSION=$(__gitstatus)
	fi

	echo ${VERSION}
}

PS1='($?) ${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\h\[\033[00m\]:\[\033[01;32m\]\w\[\033[00m\] [\[\033[36m\]$(__vcsstatus)\[\033[0m\]] \$ '

alias less="less -R"
alias cgrep="grep --include \*.c -r --color=always -A 6 -B 6 -n"
alias hgrep="grep --include \*.h -r --color=always -A 6 -B 6 -n"
alias pgrep='grep --include \*.php -r --color=always -A 2 -B 2 -n'
alias gogrep='grep --include \*.go -r --color=always -A 2 -B 2 -n'
alias jsgrep='grep --include \*.js -r --color=always -A 2 -B 2 -n'
alias htgrep='grep --include \*.html -r --color=always -A 2 -B 2 -n'
