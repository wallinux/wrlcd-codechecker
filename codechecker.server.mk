# codechecker.server.mk

CODECHECKER_MOUNT	?= $(OUT_DIR)/codechecker
CODECHECKER_REL		?= latest
CODECHECKER_IMAGE	?= codechecker/codechecker-web:$(CODECHECKER_REL)
CODECHECKER_CONTAINER	?= wrlcd_codechecker

#######################################################################
codechecker.server.create: # create codechecker container
	$(TRACE)
	$(MKDIR) $(CODECHECKER_MOUNT)
	-$(MCONTAINER) create -P --name $(CODECHECKER_CONTAINER) \
		-v $(CODECHECKER_MOUNT):/workspace \
		-p $(CODECHECKER_PORT):8001 \
		-i $(CODECHECKER_IMAGE)
	$(MKSTAMP)

codechecker.server.start: codechecker.server.create # start codechecker container
	$(TRACE)
	$(MCONTAINER) start $(CODECHECKER_CONTAINER)

codechecker.server.stop: # stop codechecker container
	$(TRACE)
	-$(MCONTAINER) stop -t 2 $(CODECHECKER_CONTAINER)

codechecker.server.rm: codechecker.server.stop # remove codechecker container
	$(TRACE)
	-$(MCONTAINER) rm $(CODECHECKER_CONTAINER)
	$(call rmstamp,codechecker.server.create)

codechecker.server.rmi: # remove codechecker image
	$(TRACE)
	$(MCONTAINER) rmi $(CODECHECKER_IMAGE)

codechecker.server.logs: # show codechecker container log
	$(TRACE)
	$(MCONTAINER) logs $(CODECHECKER_CONTAINER)

codechecker.server.help:
	$(call run-help, codechecker.server.mk)

#######################################################################

help:: codechecker.server.help

distclean:: codechecker.server.rm codechecker.server.rmi
