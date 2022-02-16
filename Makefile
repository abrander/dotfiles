TARGETS := .bash_aliases .dircolors .vimrc

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
