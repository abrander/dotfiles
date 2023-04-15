TARGETS := .bash_aliases .dircolors .vimrc .config/terminator/config

all: ${TARGETS}

.PHONY: ${TARGETS}

define LINKIT
	ln -f -s ${CURDIR}/$@ ~/$@
endef

.bash_aliases:
	$(LINKIT)

.dircolors:
	$(LINKIT)

.vimrc:
	$(LINKIT)

.config/terminator/config:
	mkdir -p ~/.config/terminator
	$(LINKIT)
