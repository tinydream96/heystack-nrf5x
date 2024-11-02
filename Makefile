.PHONY: all help

HAS_DEBUG ?= 0
HAS_BATTERY ?= 0
MAX_KEYS ?= 500
KEY_ROTATION_INTERVAL ?= 3600
ADVERTISING_INTERVAL ?= 1000
RANDOM_ROTATE_KEYS ?= 1

GNU_INSTALL_ROOT ?= $(CURDIR)/nrf-sdk/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi

TARGETS := \
	nrf51822_xxac \
	nrf51822_xxac-dcdc \
	nrf52805_xxaa \
	nrf52805_xxaa-dcdc \
	nrf52810_xxaa \
	nrf52810_xxaa-dcdc \
	nrf52832_xxaa \
	nrf52832_xxaa-dcdc \
	nrf52832_yj17024

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all        - build all targets"
	@echo "  clean      - clean all targets"

# Define a recipe to build each target individually
define build_target
.PHONY: $(1)
DIR_$(1) := $(shell echo $(1) | cut -d'_' -f1)
GNU_INSTALL_ROOT_NO_SLASH := $(patsubst %/,%,$$(GNU_INSTALL_ROOT))
TOOLCHAIN_DIR := $(shell dirname $(GNU_INSTALL_ROOT_NO_SLASH))

$(1):
	$$(MAKE) -C $$(DIR_$(1))/armgcc \
		GNU_INSTALL_ROOT=$$(if $$(findstring nrf51,$$(DIR_$(1))),$$(GNU_INSTALL_ROOT_NO_SLASH)/,$$(GNU_INSTALL_ROOT_NO_SLASH)/bin/) \
		MAX_KEYS=$(MAX_KEYS) \
		HAS_DEBUG=$(HAS_DEBUG) \
		HAS_BATTERY=$(HAS_BATTERY) \
		KEY_ROTATION_INTERVAL=$(KEY_ROTATION_INTERVAL) \
		ADVERTISING_INTERVAL=$(ADVERTISING_INTERVAL) \
		RANDOM_ROTATE_KEYS=$(RANDOM_ROTATE_KEYS) \
		$(1) bin_$(1)

	mkdir -p ./release
	cp $$(DIR_$(1))/armgcc/_build/*_s???.bin ./release/
	@echo "# Build options for $(1)" > ./release/$(1).txt
	@echo "GNU_INSTALL_ROOT=$$(shell basename $$(GNU_INSTALL_ROOT))" >> ./release/$(1).txt
	@echo "MAX_KEYS=$(MAX_KEYS)" >> ./release/$(1).txt
	@echo "HAS_DEBUG=$(HAS_DEBUG)" >> ./release/$(1).txt
	@echo "HAS_BATTERY=$(HAS_BATTERY)" >> ./release/$(1).txt
	@echo "KEY_ROTATION_INTERVAL=$(KEY_ROTATION_INTERVAL)" >> ./release/$(1).txt
	@echo "ADVERTISING_INTERVAL=$(ADVERTISING_INTERVAL)" >> ./release/$(1).txt
	@echo "RANDOM_ROTATE_KEYS=$(RANDOM_ROTATE_KEYS)" >> ./release/$(1).txt


$(1)-clean:
	$$(MAKE) -C $$(DIR_$(1))/armgcc clean \
		GNU_INSTALL_ROOT=$$(if $$(findstring nrf51,$$(DIR_$(1))),$$(GNU_INSTALL_ROOT),$$(GNU_INSTALL_ROOT)/bin/)

endef

# Generate rules for each target in the TARGETS list
$(foreach target,$(TARGETS),$(eval $(call build_target,$(target))))

# Define all target to depend on all individual targets
all: $(TARGETS)

clean: $(foreach target,$(TARGETS),$(target)-clean)
	rm -rf ./release


.PHONY: sdk sdk-download sdk-unzip sdk-patch
sdk: sdk-download sdk-unzip sdk-patch

sdk-download:
	wget -c https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/sdks/nrf5/binaries/nrf5_sdk_17.1.0_ddde560.zip -O ./nrf-sdk/nRF5_SDK_17.1.0_ddde560.zip
	wget -c https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/sdks/nrf5/binaries/nrf5sdk1230.zip -O ./nrf-sdk/nRF5_SDK_12.3.0_d7731ad.zip
	wget -c https://github.com/NordicSemiconductor/nrfx/releases/download/v2.7.0/nrfx-3521c97d.zip -O ./nrf-sdk/nrfx-v2.7.0-3521c97d.zip
	wget -c https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz -O nrf-sdk/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz

sdk-unzip:
	mkdir -p ./nrf-sdk/nrfx
	cd ./nrf-sdk && unzip -o nRF5_SDK_17.1.0_ddde560.zip
	cd ./nrf-sdk && unzip -o nRF5_SDK_12.3.0_d7731ad.zip
	cd ./nrf-sdk/nrfx && unzip -o ../nrfx-v2.7.0-3521c97d.zip
	cd ./nrf-sdk && tar -xvf arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz
	cp -f ./nrf-sdk/nrfx/soc/nrfx_irqs*             nrf-sdk/nRF5_SDK_17.1.0_ddde560/modules/nrfx/soc/
	cp -f ./nrf-sdk/nrfx/soc/nrfx_coredep.h         nrf-sdk/nRF5_SDK_17.1.0_ddde560/modules/nrfx/soc/
	cp -f ./nrf-sdk/nrfx/drivers/nrfx_common.h      nrf-sdk/nRF5_SDK_17.1.0_ddde560/modules/nrfx/drivers/nrfx_common.h
	cp -f ./nrf-sdk/nrfx/drivers/src/prs/nrfx_prs.h nrf-sdk/nRF5_SDK_17.1.0_ddde560/modules/nrfx/drivers/src/prs/nrfx_prs.h

sdk-patch:
	# Not needed...
	# cd nrf-sdk && patch -p1 < patches/nrf-power-fix.patch