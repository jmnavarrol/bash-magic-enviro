# Main project's Makefile
SHELL := /bin/bash

export VERSION := v1.4.7
export DESTDIR := ${HOME}/bin
export SRCDIR := src
export BUILDDIR := build
export SCRIPT := bash-magic-enviro
export VERSION_FILE := ${SCRIPT}.version

# Style table
export C_BOLD := \033[1m
export C_GREEN := \033[1;32m
export C_YELLOW := \033[1;1;33m
export C_RED := \033[1;31m
export C_NC := \033[0m

# Basic targets
.PHONY: targets check uninstall clean

targets:
	@echo -e "$${C_BOLD}Main targets are:$${C_NC}"
	@echo -e "\t$${C_BOLD}targets:$${C_NC} this one (default)."
	@echo -e "\t$${C_BOLD}check:$${C_NC} checks requirements."
	@echo -e "\t$${C_BOLD}build:$${C_NC} builds code out of sources."
	@echo -e "\t$${C_BOLD}dev:$${C_NC} creates symlinks for easier development of this tool."
	@echo -e "\t$${C_BOLD}install:$${C_NC} installs this product to your ~/bin/ directory."
	@echo -e "\t\tYou can also install BME globally with the help of $${C_BOLD}DESTDIR$${C_NC} var, i.e. (as root):"
	@echo -e "\t\t\`make DESTDIR=/opt/bme install\`"
	@echo -e "\t$${C_BOLD}uninstall:$${C_NC} uninstalls this product."
	@echo -e "\t\tYou can uninstall globally with $${C_BOLD}DESTDIR$${C_NC} var, i.e. (as root):"
	@echo -e "\t\t\`make DESTDIR=/opt/bme uninstall\`"
	@echo -e "\t$${C_BOLD}clean:$${C_NC} cleans build artifacts under source code."
	
check:
	@echo -e "$${C_BOLD}Checking requirements...$${C_NC}"
	@./make-checks.sh
	@echo -e "$${C_BOLD}Checking requirements:$${C_NC} $${C_GREEN}DONE!$${C_NC}"
	
# Builds BME modules
$(BUILDDIR)/$(SCRIPT)_modules: $(wildcard $(SRCDIR)/$(SCRIPT)_modules/*.module)
	@echo -e "$${C_BOLD}Building BME modules...$${C_NC}"
	@mkdir --parents $(BUILDDIR)/$(SCRIPT)_modules
	@for module in $^; do \
		echo -e "\tinstalling module $${C_BOLD}'$$module'$${C_NC}"; \
		install --mode=0644 $$module $(BUILDDIR)/$(SCRIPT)_modules/; \
	done
	@echo -e "$${C_BOLD}Building BME modules:$${C_NC} $${C_GREEN}DONE!$${C_NC}"
	
# Puts templated files in place
$(BUILDDIR)/$(VERSION_FILE): Makefile $(SRCDIR)/$(VERSION_FILE).tpl make-templating.sh
	@echo -e "$${C_BOLD}Expanding templated values...$${C_NC}"
	@./make-templating.sh
	@echo -e "$${C_BOLD}Expanding templated values:$${C_NC} $${C_GREEN}DONE!$${C_NC}"
	
# Builds main script
$(BUILDDIR)/$(SCRIPT): $(BUILDDIR)/$(VERSION_FILE) $(SRCDIR)/$(SCRIPT)
	@echo -e "$${C_BOLD}Building main script...$${C_NC}"
	install --mode=0644 $(SRCDIR)/$(SCRIPT) $(BUILDDIR)/$(SCRIPT)
	@echo -e "$${C_BOLD}Building main script:$${C_NC} $${C_GREEN}DONE!$${C_NC}"
	
# Builds BME
build: $(BUILDDIR)/$(SCRIPT)_modules $(BUILDDIR)/$(VERSION_FILE) $(BUILDDIR)/$(SCRIPT)
	@echo -e "$${C_BOLD}Building BME...$${C_NC}"
	@echo -e "$${C_BOLD}Building BME:$${C_NC} $${C_GREEN}DONE!$${C_NC}"
	
# Makes sure DESTDIR is in place
$(DESTDIR):
	mkdir --parents ${DESTDIR}
	

# Sets symlinks for easy development
dev: build
	@echo -e "$${C_BOLD}Setting BME in development mode...$${C_NC}"
	@./make-control-install.sh dev
	@echo -e "$${C_BOLD}Development mode:$${C_NC} $${C_GREEN}DONE!$${C_NC}"
	
install: check build $(DESTDIR)
	@echo -e "$${C_BOLD}Installing BME...$${C_NC}"
	@./make-control-install.sh install
	@echo -e "$${C_BOLD}Installing BME:$${C_NC} $${C_GREEN}DONE$${C_NC}"
	
clean:
	rm -rf $(BUILDDIR)
	@echo -e "$${C_BOLD}'magic enviro'$${C_NC} sources cleaned: $${C_GREEN}OK$${C_NC}"
	
uninstall: clean
	rm -f "$(DESTDIR)/$(SCRIPT)"
	rm -f "$(DESTDIR)/$(VERSION_FILE)"
	rm -rf "$(DESTDIR)/$(SCRIPT)_modules"
	@echo -e "$${C_BOLD}'magic enviro'$${C_NC} script uninstalled: $${C_GREEN}OK$${C_NC}"
