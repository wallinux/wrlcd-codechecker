# Default settings
HOSTNAME	?= $(shell hostname)
USER		?= $(shell whoami)

# Don't inherit path from environment
export PATH	:= /bin:/usr/bin
export SHELL	:= /bin/bash
export TERM	:= xterm

# Optional configuration
-include hostconfig-$(HOSTNAME).mk
-include userconfig-$(USER).mk

TOP		:= $(shell pwd)

# Define V=1 to echo everything
ifneq ($(V),1)
 export Q=@
 MAKE := @make -s
else
 MAKE := make
endif

.PHONY:: help *.help

define run-help
	$(YELLOW)
	$(ECHO) -e "\n----- $@ -----"
	$(GREEN)
	$(GREP) ":" $(1) | grep -v grep | grep "\#" | grep -v "^#" | sed 's/:/#/' | cut -d'#' -f1,3 | sort | column -s'#' -t
	$(NORMAL)
endef

STAMPS_DIR = $(OUT_DIR)/.stamps
vpath % $(STAMPS_DIR)
MKSTAMP = $(Q)mkdir -p $(STAMPS_DIR) ; touch $(STAMPS_DIR)/$@
%.force:
	$(call rmstamp,$*)
	$(MAKE) $*

define rmstamp
	$(RM) $(STAMPS_DIR)/$(1)
endef

CD	= $(Q)cd
CP	= $(Q)cp -f
ECHO	= @echo
GIT	= $(Q)git
GREP	= $(Q)grep
IF	= $(Q)if
MKDIR	= $(Q)mkdir -p
RM	= $(Q)rm -f
SED	= $(Q)sed -i

RED     = @tput setaf 1
GREEN   = @tput setaf 2
YELLOW  = @tput setaf 3
BLUE    = @tput setaf 4
NORMAL  = @tput sgr0

ifeq ($(V),1)
 TRACE   = @(tput setaf 1; echo ------ $@; tput sgr0)
else
 TRACE   = @#
endif
