# container.mk

CROPS			?= 1
CONTAINER		?= docker

#################################################################

docker.%: # make container.% with docker 
	$(MAKE) container.$* CONTAINER=docker

podman.%:  # make container.% with podman
	$(MAKE) container.$* CONTAINER=podman

#################################################################

ifdef CROPS
 CONTAINER_DISTRO	?= crops_poky
 CONTAINER_DISTRO_VER	?= latest
else
 CONTAINER_DISTRO	?= ubuntu
 CONTAINER_DISTRO_VER	?= 18_04
endif

CONTAINER_TAG		?= wrlcd
CONTAINER_DT		?= $(CONTAINER_DISTRO)-$(CONTAINER_DISTRO_VER)
CONTAINER_NAME		?= $(USER)_$(CONTAINER_TAG)_$(CONTAINER_DT)
CONTAINER_IMAGE_REPO	?= $(USER)_$(CONTAINER_DISTRO)_$(CONTAINER_DISTRO_VER)
CONTAINER_IMAGE		?= $(CONTAINER_IMAGE_REPO):$(CONTAINER_TAG)
CONTAINER_HOSTNAME	?= $(CONTAINER_TAG)_$(CONTAINER_DT).eprime.com
#CONTAINER_BUILDARGS	?= --no-cache
HOSTIP			?= $(shell /sbin/ifconfig docker0 | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

MCONTAINER		?= $(Q)$(CONTAINER)

define run-container-exec
	$(MCONTAINER) exec -e HOSTIP=$(HOSTIP) -u $(1) $(2) $(CONTAINER_NAME) $(3)
endef

CONTAINER_MOUNTS	+= -v $(WRL_INSTALL_DIR):$(WRL_INSTALL_DIR):ro
CONTAINER_MOUNTS	+= -v $(GITROOT):$(GITROOT)
CONTAINER_MOUNTS	+= -v $(HOME):$(HOME)

CONTAINER_NAME_RUNNING	= $(eval container_name_running=$(shell $(CONTAINER) inspect -f {{.State.Running}} $(CONTAINER_NAME)))
CONTAINER_NAME_ID	= $(eval container_name_id=$(shell $(CONTAINER) ps -a -q -f name=$(CONTAINER_NAME)))
CONTAINER_IMAGE_ID	= $(eval container_image_id=$(shell $(CONTAINER) images -q $(CONTAINER_IMAGE) 2> /dev/null))

ifneq ($(V),1)
DEVNULL			?= > /dev/null
endif
#######################################################################

.PHONY:: container.* hostconfig-$(CONTAINER_HOSTNAME).mk

container.build: $(GITROOT)/container/Dockerfile-$(CONTAINER_TAG).$(CONTAINER_DT) # build container image
	$(TRACE)
ifneq ($(V),1)
	$(eval quiet=-q)
endif
	$(MCONTAINER) build $(quiet) $(CONTAINER_BUILDARGS) --pull -f $< \
		-t "$(CONTAINER_IMAGE)" $(GITROOT)/container

container.prepare.ubuntu::
	$(TRACE)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(call run-container-exec, root, , sh -c "echo $(host_timezone) > /etc/timezone" )
	$(call run-container-exec, root, , ln -sfn /usr/share/zoneinfo/$(host_timezone) /etc/localtime )
	$(call run-container-exec, root, , dpkg-reconfigure -f noninteractive tzdata 2> /dev/null)
	$(call run-container-exec, root, , sh -c "ln -sfn /bin/bash /bin/sh" )

container.prepare.crops_poky:: container.prepare.ubuntu

container.prepare:
	$(TRACE)
	$(MCONTAINER) start $(CONTAINER_NAME) $(DEVNULL)
	$(call run-container-exec, root, , groupadd -f -g $(shell id -g) $(shell id -gn) )
	$(call run-container-exec, root, , useradd --shell /bin/sh -M -d $(HOME) -u $(shell id -u) $(USER) -g $(shell id -g) )
	$(MAKE) container.prepare.$(CONTAINER_DISTRO)
	$(MAKE) container.stop

CONTAINER_OPTS ?= --ipc host --net host --privileged

container.make:
	$(TRACE)
	$(CONTAINER_IMAGE_ID)
	$(IF) [ -z "$(container_image_id)" ]; then make --no-print-directory container.build; fi
	$(MCONTAINER) create -P --name $(CONTAINER_NAME) \
		$(CONTAINER_MOUNTS) \
		$(CONTAINER_OPTS) \
		-h $(CONTAINER_HOSTNAME) \
		-e INSIDE_CONTAINER=yes \
		-i $(CONTAINER_IMAGE) $(DEVNULL)
	$(MAKE) container.prepare

container.create: # create container container
	$(TRACE)
	$(CONTAINER_NAME_ID)
	$(IF) [ -z "$(container_name_id)" ]; then make --no-print-directory container.make; fi

container.start: container.create # start container container
	$(TRACE)
	$(MCONTAINER) start $(CONTAINER_NAME) $(DEVNULL)

container.stop: # stop container container
	$(TRACE)
	$(MCONTAINER) stop -t 1 $(CONTAINER_NAME) $(DEVNULL) || true

container.rm: container.stop # remove container container
	$(TRACE)
	$(MCONTAINER) rm $(CONTAINER_NAME) $(DEVNULL) || true

container.rmi: # remove container image
	$(TRACE)
	$(MCONTAINER) rmi $(CONTAINER_IMAGE) || true

container.logs: # show container log
	$(TRACE)
	$(MCONTAINER) logs $(CONTAINER_NAME)

container.shell: container.start hostconfig-$(CONTAINER_HOSTNAME).mk # start container shell as $(USER)
	$(TRACE)
	$(call run-container-exec, $(USER), -it, /bin/sh -c "cd $(TOP); exec /bin/bash")

container.rootshell: container.start # start container shell as root
	$(TRACE)
	$(call run-container-exec, root, -it, /bin/sh -c "cd /root; exec /bin/bash")

hostconfig-$(CONTAINER_HOSTNAME).mk:
	$(TRACE)
	$(ECHO) "# $@" > $@
	$(ECHO) "WRL_INSTALL_DIR=$(WRL_INSTALL_DIR)" >> $@

container.make.%: container.start hostconfig-$(CONTAINER_HOSTNAME).mk  # run make inside container, e.g. make container.make.all"
	$(call run-container-exec, $(USER), -t, make -s -C $(TOP) $*)

container.clean: # stop and remove container container and remove configs
	$(TRACE)
	$(MAKE) container.rm
	$(RM) hostconfig-$(CONTAINER_HOSTNAME).mk

container.distclean: container.clean # remove image
	$(TRACE)
	$(MAKE) container.rmi

container.help:
	$(CONTAINER_IMAGE_ID)
	$(CONTAINER_NAME_ID)
	$(CONTAINER_NAME_RUNNING)
	$(call run-help, container.mk)
	$(GREEN)
	$(ECHO) " CONTAINER_DISTRO: $(CONTAINER_DISTRO):$(CONTAINER_DISTRO_VER)"
	$(ECHO) " IMAGE: $(CONTAINER_IMAGE) id=$(container_image_id)"
	$(ECHO) " CONTAINER: $(CONTAINER_NAME) id=$(container_name_id) running=$(container_name_running)"
	$(NORMAL)

#######################################################################

clean:: container.clean

distclean:: container.distclean

help:: container.help
