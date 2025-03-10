# Main project's Makefile
SHELL := /usr/bin/env bash

export MAKEFILEDIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
export VERSION := $(shell cat ./VERSION)
export DESTDIR := ${HOME}/bin
export SRCDIR := src
export BUILDDIR := ${MAKEFILEDIR}/build
export BME_BASENAME := bash-magic-enviro
export VERSION_FILE := ${BME_BASENAME}.version

# Style table
export C_BOLD := \033[1m
export C_GREEN := \033[1;32m
export C_YELLOW := \033[1;1;33m
export C_RED := \033[1;31m
export C_NC := \033[0m

# Basic targets
.PHONY: targets date check test uninstall clean

targets:
	@echo -e "$${C_BOLD}Main targets are:$${C_NC}"
	@echo -e "\t$${C_BOLD}targets:$${C_NC} this one (default)."
	@echo -e "\t$${C_BOLD}date:$${C_NC} shows current date in CHANGELOG format."
	@echo -e "\t$${C_BOLD}check:$${C_NC} checks requirements."
	@echo -e "\t$${C_BOLD}build:$${C_NC} builds code out of sources."
	@echo -e "\t$${C_BOLD}dev:$${C_NC} creates symlinks for easier development of this tool."
	@echo -e "\t$${C_BOLD}test:$${C_NC} runs unitary tests."
	@echo -e "\t$${C_BOLD}install:$${C_NC} installs this product to your ~/bin/ directory."
	@echo -e "\t\tYou can also install BME globally with the help of $${C_BOLD}DESTDIR$${C_NC} var, i.e. (as root):"
	@echo -e "\t\t\`make DESTDIR=/opt/bme install\`"
	@echo -e "\t$${C_BOLD}uninstall:$${C_NC} uninstalls this product."
	@echo -e "\t\tYou can uninstall globally with $${C_BOLD}DESTDIR$${C_NC} var, i.e. (as root):"
	@echo -e "\t\t\`make DESTDIR=/opt/bme uninstall\`"
	@echo -e "\t$${C_BOLD}clean:$${C_NC} cleans build artifacts under source code."

date:
	@formated_date=`LC_ALL=C date +"%Y-%^b-%d"` \
	&& echo -e "$${C_BOLD}Changelog date is:$${C_NC} $${C_GREEN}$${formated_date}$${C_NC}"

check:
	@echo -e "$${C_BOLD}Checking requirements...$${C_NC}"
	@./make-checks.sh
	@echo -e "$${C_BOLD}Checking requirements:$${C_NC} $${C_GREEN}DONE!$${C_NC}"

# Builds BME modules
$(BUILDDIR)/$(BME_BASENAME)_modules: $(wildcard $(SRCDIR)/$(BME_BASENAME)_modules/*.module)
	@echo -e "$${C_BOLD}Building BME modules...$${C_NC}"
	@mkdir --parents $(BUILDDIR)/$(BME_BASENAME)_modules
	@for module in $^; do \
		echo -e "\tinstalling module $${C_BOLD}'$$module'$${C_NC}"; \
		install --mode=0644 $$module $(BUILDDIR)/$(BME_BASENAME)_modules/; \
	done
	@echo -e "$${C_BOLD}Building BME modules:$${C_NC} $${C_GREEN}DONE!$${C_NC}"

# Puts templated files in place
$(BUILDDIR)/$(VERSION_FILE): Makefile VERSION $(SRCDIR)/$(VERSION_FILE).tpl make-templating.sh
	@echo -e "$${C_BOLD}Expanding templated values...$${C_NC}"
	@./make-templating.sh
	@echo -e "$${C_BOLD}Expanding templated values:$${C_NC} $${C_GREEN}DONE!$${C_NC}"

# Builds main script
$(BUILDDIR)/$(BME_BASENAME): $(BUILDDIR)/$(VERSION_FILE) $(SRCDIR)/$(BME_BASENAME)
	@echo -e "$${C_BOLD}Building main script...$${C_NC}"
	install --mode=0644 $(SRCDIR)/$(BME_BASENAME) $(BUILDDIR)/$(BME_BASENAME)
	@echo -e "$${C_BOLD}Building main script:$${C_NC} $${C_GREEN}DONE!$${C_NC}"

# Builds BME
build: Makefile $(BUILDDIR)/$(BME_BASENAME)_modules $(BUILDDIR)/$(VERSION_FILE) $(BUILDDIR)/$(BME_BASENAME)
	@echo -e "$${C_BOLD}Building BME:$${C_NC} $${C_GREEN}DONE!$${C_NC}"

# Makes sure DESTDIR is in place
$(DESTDIR):
	mkdir --parents ${DESTDIR}


# Sets symlinks for easy development
dev: build
	@echo -e "$${C_BOLD}Setting BME in development mode...$${C_NC}"
	@./make-control-install.sh dev
	@echo -e "$${C_BOLD}Development mode:$${C_NC} $${C_GREEN}DONE!$${C_NC}"

test: build
	@echo -e "$${C_BOLD}Running unitary tests...$${C_NC}"
	@export BUILD_DIR=$$BUILDDIR; ./tests/maketests.sh
	@echo -e "$${C_BOLD}Unitary tests:$${C_NC} $${C_GREEN}DONE!$${C_NC}"

install: check build $(DESTDIR)
	@echo -e "$${C_BOLD}Installing BME to '$${DESTDIR}'...$${C_NC}"
	@./make-control-install.sh install
	@echo -e "$${C_BOLD}Installing BME:$${C_NC} $${C_GREEN}DONE$${C_NC}"

clean:
	rm -rf $(BUILDDIR)
	rm -rf tests/scratch
	rm -rf .here
	@echo -e "$${C_BOLD}'magic enviro'$${C_NC} sources cleaned: $${C_GREEN}OK$${C_NC}"

uninstall: clean
	@echo -e "$${C_BOLD}Uninstalling BME...$${C_NC}"
	@./make-control-install.sh uninstall
	@echo -e "$${C_BOLD}Uninstalling BME:$${C_NC} $${C_GREEN}DONE$${C_NC}"
