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

-include $(OUT_DIR)/wrlinux_version

######################################################################################
BBPREP		= $(CD) $(OUT_DIR); \
		  source ./environment-setup-x86_64-wrlinuxsdk-linux; \
		  source ./oe-init-build-env $(BUILD_DIR) > /dev/null;

define bitbake
	$(BBPREP) bitbake $(1)
endef

define bitbake-task
	$(BBPREP) bitbake $(1) -c $(2)
endef

######################################################################################

Makefile.help::
	$(TRACE)
	$(call run-help, Makefile)
	$(GREEN)
	$(ECHO) " WRL_INSTALL_DIR: $(WRL_INSTALL_DIR)"
	$(ECHO) " WRLINUX_VERSION: $(WRLINUX_VERSION)"
	$(ECHO) " MACHINE: $(MACHINE)"
	$(ECHO) " KERNEL_TYPE: $(KERNEL_TYPE)"
	$(ECHO) " IMAGE: $(IMAGE)"

help:: Makefile.help

list-machines: setup # list-machines
	$(TRACE)
	$(CD) $(OUT_DIR); ./wrlinux-x/setup.sh --$@

wrlinux_version:
	$(TRACE)
	$(Q)sed '/^WRLINUX_/!d' $(OUT_DIR)/layers/wrlinux/conf/wrlinux-version.inc | grep _VERSION | head -n -1 | tr -d ' ' > $(OUT_DIR)/$@

setup: $(OUT_DIR) # setup wrlinux CD
$(OUT_DIR):
	$(TRACE)
	$(MKDIR) $@
	$(CD) $@ ; \
		git clone --branch $(WRL_BRANCH) $(WRL_INSTALL_DIR)/wrlinux-x wrlinux-x; \
		REPO_MIRROR_LOCATION=$(WRL_INSTALL_DIR)	./wrlinux-x/setup.sh $(WRL_OPTS);
	$(MAKE) wrlinux_version

configure:: $(BUILD_DIR)  # configure wrlinux CD machine build directory
$(BUILD_DIR): | $(OUT_DIR)
	$(TRACE)
	$(CD) $(OUT_DIR) ; \
		source ./environment-setup-x86_64-wrlinuxsdk-linux; \
		source ./oe-init-build-env $@ > /dev/null; \
		echo "MACHINE = \"$(MACHINE)\"" >> conf/local.conf
	$(IF) [ "$(KERNEL_TYPE)" == "preempt_rt" ]; then \
		grep -q KTYPE_ENABLED $(BUILD_DIR)/conf/local.conf; \
		if [ $$? = 1 ]; then \
			echo -e "\nKTYPE_ENABLED = \"preempt-rt\"" >> $(BUILD_DIR)/conf/local.conf; \
			echo -e "LINUX_KERNEL_TYPE = \"preempt-rt\"" >> $(BUILD_DIR)/conf/local.conf; \
			echo -e "PREFERRED_PROVIDER_virtual/kernel = \"linux-yocto-rt\"" >> $(BUILD_DIR)/conf/local.conf; \
		fi \
	fi
	$(ECHO) "SSTATE_DIR = \"$(OUT_DIR)/sstate-cache\"" >> $(BUILD_DIR)/conf/local.conf

kernel: | $(BUILD_DIR) # build kernel
	$(TRACE)
	$(Q)$(call bitbake-task, virtual/kernel, configure)

bbs: | $(BUILD_DIR)
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
