# codechecker.server.mk

CODECHECKER_WORKSPACE	?= $(TOP)/codechecker
CODECHECKER_REL		?= latest
CODECHECKER_IMAGE	?= codechecker/codechecker-web:$(CODECHECKER_REL)
CODECHECKER_CONTAINER	?= wrlcd_codechecker

CODECHECKER_ID		= $(eval codechecker_id=$(shell $(CONTAINER) ps -a -q -f name=$(CODECHECKER_CONTAINER)))

#######################################################################

$(CODECHECKER_WORKSPACE):
	$(MKDIR) $@

codechecker.server.create: | $(CODECHECKER_WORKSPACE) # create codechecker container
	$(TRACE)
	$(CODECHECKER_ID)
	$(IF) [ -z "$(codechecker_id)" ]; then \
		$(CONTAINER) create -P --name $(CODECHECKER_CONTAINER) \
		-v $(CODECHECKER_WORKSPACE):/workspace \
		-p $(CODECHECKER_PORT):8001 \
		-i $(CODECHECKER_IMAGE); \
	fi

codechecker.server.start: codechecker.server.create # start codechecker container
	$(TRACE)
	$(MCONTAINER) start $(CODECHECKER_CONTAINER)

codechecker.server.stop: # stop codechecker container
	$(TRACE)
	-$(MCONTAINER) stop -t 2 $(CODECHECKER_CONTAINER)

codechecker.server.rm: codechecker.server.stop # remove codechecker container
	$(TRACE)
	-$(MCONTAINER) rm $(CODECHECKER_CONTAINER)

codechecker.server.rmi: # remove codechecker image
	$(TRACE)
	-$(MCONTAINER) rmi $(CODECHECKER_IMAGE)

codechecker.server.logs: # show codechecker container log
	$(TRACE)
	$(MCONTAINER) logs $(CODECHECKER_CONTAINER)

codechecker.server.help:
	$(call run-help, codechecker.server.mk)

codechecker.server.distclean: codechecker.server.rm codechecker.server.rmi
	$(TRACE)
	$(RM) -r $(CODECHECKER_WORKSPACE)

#######################################################################

help:: codechecker.server.help

distclean:: codechecker.server.distclean
