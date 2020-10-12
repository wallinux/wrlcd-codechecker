# codechecker.server.mk

CODECHECKER_WORKSPACE	?= $(TOP)/codechecker
CODECHECKER_REL		?= latest
CODECHECKER_IMAGE	?= codechecker/codechecker-web:$(CODECHECKER_REL)
CODECHECKER_CONTAINER	?= wrlcd_codechecker

CODECHECKER_ID		= $(eval codechecker_id=$(shell $(CONTAINER) ps -a -q -f name=$(CODECHECKER_CONTAINER)))

define run-cc-exec
	$(MCONTAINER) exec $(1) $(CODECHECKER_CONTAINER) $(2)
endef

#######################################################################

$(CODECHECKER_WORKSPACE):
	$(MKDIR) $@

codechecker.server.prepare:
	$(TRACE)
	$(MCONTAINER) start $(CODECHECKER_CONTAINER)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(call run-cc-exec, , sh -c "echo $(host_timezone) > /etc/timezone" )
	$(call run-cc-exec, , ln -sfn /usr/share/zoneinfo/$(host_timezone) /etc/localtime )
	$(call run-cc-exec, , dpkg-reconfigure -f noninteractive tzdata 2> /dev/null)
	$(MAKE) codechecker.server.stop

codechecker.server.create: | $(CODECHECKER_WORKSPACE) # create codechecker container
	$(TRACE)
	$(CODECHECKER_ID)
	$(IF) [ -z "$(codechecker_id)" ]; then \
		$(CONTAINER) create -P --name $(CODECHECKER_CONTAINER) \
		-v $(CODECHECKER_WORKSPACE):/workspace \
		-p $(CODECHECKER_PORT):8001 \
		-i $(CODECHECKER_IMAGE); \
		make codechecker.server.prepare; \
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

codechecker.server.shell: # start shell in container
	$(TRACE)
	$(call run-cc-exec, -it, /bin/sh -c "/bin/bash")

codechecker.server.help:
	$(call run-help, codechecker.server.mk)
	$(GREEN)
	$(ECHO) " SERVER: http://$(CODECHECKER_IP):$(CODECHECKER_PORT)/Default"
	$(NORMAL)

codechecker.server.distclean: codechecker.server.rm codechecker.server.rmi
	$(TRACE)
	$(RM) -r $(CODECHECKER_WORKSPACE)

#######################################################################

help:: codechecker.server.help

distclean:: codechecker.server.distclean
