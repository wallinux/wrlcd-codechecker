# arn-awallin-linux-l5 host config file
#
# Define where you have wrlinux
WRL_INSTALL_DIR	= /opt/projects/ericsson/installs/wrlinux_lts$(WRL_VER)

# Define to trace cmd's
# V=1

BB_NUMBER_THREADS       = 2
PARALLEL_MAKE 	  	= -j 4
OUT_DIR			= /opt/awallin/$(shell basename $(PWD))
CONTAINER_MOUNTS	+= -v $(OUT_DIR):$(OUT_DIR)

arn-awallin-linux-l5.configure: $(OUT_DIR)
	$(TRACE)
	$(Q)ln -sfn $(OUT_DIR) $(TOP)/out

configure::
	$(MAKE) arn-awallin-linux-l5.configure
