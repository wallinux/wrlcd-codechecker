default: help

include common.mk

MACHINE		?= qemux86-64
DISTRO		?= wrlinux
KERNEL_TYPE	?= standard
IMAGE		?= wrlinux-image-small

OUT_DIR		?= $(TOP)/out
BUILD_DIR	?= $(OUT_DIR)/build_$(MACHINE)_$(KERNEL_TYPE)

WRL_INSTALL_DIR ?= /wr/installs/wrl-CD-mirror
WRL_BRANCH	?= WRLINUX_CI

WRL_OPTS	+= --dl-layers
WRL_OPTS	+= --accept-eula yes
WRL_OPTS	+= --distros $(DISTRO)
WRL_OPTS	+= --base-branch $(WRL_BRANCH)
WRL_OPTS	+= --machines $(MACHINE)

######################################################################################
BBPREP		= $(CD) $(OUT_DIR); \
		  source ./environment-setup-x86_64-wrlinuxsdk-linux; \
		  source ./oe-init-build-env $(BUILD_DIR) > /dev/null;

define bitbake
	$(BBPREP) bitbake $(BBARGS) $(1)
endef

define bitbake-task
	$(BBPREP) bitbake $(BBARGS) -c $(2) $(1)
endef

define bitbake-rebuild
	$(BBPREP) bitbake $(BBARGS) -c cleanall $(1)
	$(BBPREP) bitbake $(BBARGS) $(1)
endef

######################################################################################

Makefile.help::
	$(TRACE)
	$(call run-help, Makefile)
	$(GREEN)
	$(ECHO) " WRL_INSTALL_DIR: $(WRL_INSTALL_DIR)"
	$(ECHO) " MACHINE: $(MACHINE)"
	$(ECHO) " KERNEL_TYPE: $(KERNEL_TYPE)"
	$(ECHO) " IMAGE: $(IMAGE)"

help:: Makefile.help

list-machines: setup # list-machines
	$(TRACE)
	$(CD) $(OUT_DIR); ./wrlinux-x/setup.sh --$@

setup: $(OUT_DIR) # setup wrlinux CD
$(OUT_DIR):
	$(TRACE)
	$(MKDIR) $@
	$(CD) $@ ; \
		git clone --branch $(WRL_BRANCH) $(WRL_INSTALL_DIR)/wrlinux-x wrlinux-x; \
		REPO_MIRROR_LOCATION=$(WRL_INSTALL_DIR)	./wrlinux-x/setup.sh $(WRL_OPTS);

$(BUILD_DIR): | $(OUT_DIR)
	$(TRACE)
	$(BBPREP)

Makefile.configure:: # configure wrlinux machine build directory
	$(TRACE)
	$(MAKE) $(BUILD_DIR)
	$(eval localconf=$(BUILD_DIR)/conf/local.conf)
	$(SED) s/^MACHINE.*/MACHINE\ =\ \"$(MACHINE)\"/g $(localconf)
	$(IF) [ "$(KERNEL_TYPE)" == "preempt_rt" ]; then \
		grep -q KTYPE_ENABLED $(localconf); \
		if [ $$? = 1 ]; then \
			echo -e "\nKTYPE_ENABLED = \"preempt-rt\"" >> $(localconf); \
			echo -e "LINUX_KERNEL_TYPE = \"preempt-rt\"" >> $(localconf); \
			echo -e "PREFERRED_PROVIDER_virtual/kernel = \"linux-yocto-rt\"" >> $(localconf); \
		fi \
	fi
ifneq ($(BB_NUMBER_THREADS),)
	$(GREP) -q "BB_NUMBER_THREADS" $(localconf) || \
		echo "BB_NUMBER_THREADS = \"$(BB_NUMBER_THREADS)\"" >> $(localconf)
endif
ifneq ($(PARALLEL_MAKE),)
	$(GREP) -q "PARALLEL_MAKE" $(localconf) || \
		echo "PARALLEL_MAKE = \"$(PARALLEL_MAKE)\"" >> $(localconf)
endif
	$(GREP) -q "SKIP_META_GNOME_SANITY_CHECK" $(localconf) || \
		echo "SKIP_META_GNOME_SANITY_CHECK = \"1\"" >> $(localconf)
	$(ECHO) "SSTATE_DIR = \"$(OUT_DIR)/sstate-cache\"" >> $(localconf)
	$(ECHO) "SKIP_META_GNOME_SANITY_CHECK = \"1\"" >> $(localconf)

configure:: Makefile.configure

pkg.%: | $(BUILD_DIR) # build package %
	$(TRACE)
	$(call bitbake-rebuild, $*)

bbs: | $(BUILD_DIR) # start bitbake shell
	$(CD) $(OUT_DIR) ; \
		source ./environment-setup-x86_64-wrlinuxsdk-linux ; \
		source ./oe-init-build-env $(BUILD_DIR) > /dev/null; \
		$(SHELL) --rcfile <(cat ~/.bashrc ; echo 'PS1="\[\033[0;33m\]\u@bbshell:\W\$\[\033[00m\]$$ "')

image: | $(BUILD_DIR) # build image $(IMAGE)
	$(TRACE)
	$(Q)$(call bitbake, $(IMAGE) )

clean:: # remove machine build directory
	$(TRACE)
	$(RM) -r $(BUILD_DIR)

distclean:: # remove everything
	$(TRACE)
	$(RM) -r $(OUT_DIR)

ifndef INSIDE_CONTAINER
 include container.mk
endif

include codechecker.mk
