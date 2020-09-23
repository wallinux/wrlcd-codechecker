# codechecker.mk

##CODECHECKER_REPO	= git@github.com:dl9pf/meta-codechecker.git
CODECHECKER_REPO	= git@github.com:wallinux/meta-codechecker.git
CODECHECKER_DIR		= $(GITROOT)/layers/meta-codechecker
CODECHECKER_BRANCH	?= master

CODECHECKER_PORT	?= 8002

ifdef INSIDE_CONTAINER
CODECHECKER_IP		?= $(HOSTIP)
else
CODECHECKER_IP		?= localhost
endif

#######################################################################

$(CODECHECKER_DIR):
	$(TRACE)
	-$(GIT) clone $(CODECHECKER_REPO) -b $(CODECHECKER_BRANCH) $@

codechecker.configure: $(BUILD_DIR) $(CODECHECKER_DIR) # allow network download and whitelist packages
	$(TRACE)
	$(eval localconf=$(BUILD_DIR)/conf/local.conf)
	$(eval ccconf=$(BUILD_DIR)/conf/codechecker.conf)
	$(RM) $(ccconf)
	$(GREP) -q codechecker.conf $(localconf); \
		if [ $$? = 1 ]; then \
			echo -e "\ninclude codechecker.conf" >> $(localconf); \
		fi
	$(ECHO) "# codechecker.conf" > $(ccconf)
	$(ECHO) "BB_NO_NETWORK = \"0\"" >> $(ccconf)
	$(ECHO) "#BB_FETCH_PREMIRRORONLY = \"0\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_codechecker += \"codechecker\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_codechecker += \"python3-thrift\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_codechecker += \"python3-codechecker-api\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_codechecker += \"python3-codechecker-api-shared\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_codechecker += \"python3-portalocker\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_clang-layer += \"clang\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_clang-layer += \"compiler-rt\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_clang-layer += \"libcxx\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_clang-layer += \"llvm-project-source-11.0.0\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_meta-python += \"python3-psutil\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_openembedded-layer += \"doxygen\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_openembedded-layer += \"nodejs\"" >> $(ccconf)
	$(ECHO) "PNWHITELIST_openembedded-layer += \"brotli\"" >> $(ccconf)
	$(ECHO) "THIRD_PARTY_DL_IGNORED_RECIPES += \"nodejs\"" >> $(ccconf)
	$(ECHO) "THIRD_PARTY_DL_IGNORED_RECIPES += \"brotli\"" >> $(ccconf)
	$(ECHO) "THIRD_PARTY_DL_IGNORED_RECIPES += \"python3-thrift\"" >> $(ccconf)
	$(ECHO) "INHERIT += \"codechecker\"" >> $(ccconf)
	$(ECHO) "CODECHECKER_ENABLED = \"1\"" >> $(ccconf)
	$(ECHO) "CODECHECKER_REPORT_HTML = \"1\""  >> $(ccconf)
	$(ECHO) "CODECHECKER_REPORT_STORE = \"1\""  >> $(ccconf)
	$(ECHO) "CODECHECKER_REPORT_HOST = \"http://$(CODECHECKER_IP):$(CODECHECKER_PORT)/Default\"" >> $(ccconf)
ifeq ($(V),1)
	@cat $(ccconf)
endif

codechecker.deconfigure: $(CODECHECKER_DIR) # remove configuration files
	$(TRACE)
	$(eval localconf=$(BUILD_DIR)/conf/local.conf)
	$(eval ccconf=$(BUILD_DIR)/conf/codechecker.conf)
	$(RM) $(ccconf)
	$(SED) '/codechecker/d' $(localconf)

# NOT WORKING, running it manually works fine
#codechecker.add_layer: $(CODECHECKER_DIR)# add codechecker layer
#	$(TRACE)
#	$(BBPREP) bitbake-layers add-layer $(CODECHECKER_DIR)
#	$(MKSTAMP)
#
#codechecker.remove_layer: # remove codechecker layer
#	$(TRACE)
#	-$(BBPREP) bitbake-layers remove-layer $(CODECHECKER_DIR)
#	$(call rmstamp,codechecker.add_layer)

codechecker.add_layer: $(BUILD_DIR) $(CODECHECKER_DIR) # add codechecker layer
	$(TRACE)
	$(eval layerconf=$(BUILD_DIR)/conf/bblayers.conf)
	$(GREP) -q $(CODECHECKER_DIR) $(layerconf); \
		if [ $$? = 1 ]; then \
			echo -e "BBLAYERS += \"$(CODECHECKER_DIR)\"" >> $(layerconf); \
		fi

codechecker.remove_layer: # remove codechecker layer
	$(TRACE)
	$(eval layerconf=$(BUILD_DIR)/conf/bblayers.conf)
	$(SED) '\:$(CODECHECKER_DIR):d' $(layerconf)

codechecker.update: $(CODECHECKER_DIR) # update codechecker layer
	$(TRACE)
	$(GIT) -C $< fetch --prune
	$(GIT) -C $< gc --auto
	$(GIT) -C $< checkout $(CODECHECKER_BRANCH) &> /dev/null || git checkout -b $(CODECHECKER_BRANCH) origin/$(CODECHECKER_BRANCH)
	$(GIT) -C $< pull

codechecker.enable:
	$(TRACE)
	$(MAKE) codechecker.add_layer
	$(MAKE) codechecker.configure

codechecker.disable:
	$(TRACE)
	$(MAKE) codechecker.deconfigure
	$(MAKE) codechecker.remove_layer

codechecker.distclean: # delete codechecker dir
	$(TRACE)
	$(MAKE) codechecker.remove_layer
	$(RM) -r $(CODECHECKER_DIR)
	$(call rmstamp,codechecker.configure)

codechecker.help:
	$(call run-help, codechecker.mk)

#######################################################################

help:: codechecker.help

update:: codechecker.update

distclean:: codechecker.distclean

ifndef INSIDE_CONTAINER
 include codechecker.server.mk
endif
