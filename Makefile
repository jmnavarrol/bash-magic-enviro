# Main project's Makefile
SHELL := /bin/bash

export VERSION := v1.4.5
export DESTDIR := ${HOME}/bin
export SRCDIR := src
export BUILDDIR := build
export SCRIPT := bash-magic-enviro


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
	
# Expands templated values from main script
$(BUILDDIR)/$(SCRIPT): Makefile src/$(SCRIPT)
	@echo -e "$${C_BOLD}Expanding templated values...$${C_NC}"
	@./make-templating.sh
	
# Makes sure DESTDIR is in place
$(DESTDIR):
	mkdir --parents ${DESTDIR}
	
dev: $(BUILDDIR)/$(SCRIPT)
# Symlinks the main script
	@if ! [ -L ${DESTDIR}/${SCRIPT} ]; then \
		if [ -e ${DESTDIR}/${SCRIPT} ]; then \
			echo -en "$${C_YELLOW}WARNING:$${C_NC} about to delete $${C_BOLD}'${DESTDIR}/${SCRIPT}$${C_NC}'... "; \
			rm -rf "$(DESTDIR)/$(SCRIPT)"; \
			echo -e "$${C_GREEN}DONE$${C_NC}"; \
		fi; \
		echo -en "Creating $${C_BOLD}'${DESTDIR}/${SCRIPT}'$${C_NC} symlink for development... "; \
		current_pwd=$${PWD}; \
		( cd ${DESTDIR} && ln -s $${current_pwd}/build/$(SCRIPT) ${SCRIPT} ); \
		echo -e "$${C_GREEN}DONE$${C_NC}"; \
	fi
# Then, the modules
	@if ! [ -L ${DESTDIR}/${SCRIPT}_modules ]; then \
		if [ -e ${DESTDIR}/${SCRIPT}_modules ]; then \
			echo -en "$${C_YELLOW}WARNING:$${C_NC} about to delete $${C_BOLD}'${DESTDIR}/${SCRIPT}_modules$${C_NC}'... "; \
			rm -rf "$(DESTDIR)/$(SCRIPT)_modules"; \
			echo -e "$${C_GREEN}DONE$${C_NC}"; \
		fi; \
		echo -en "Creating $${C_BOLD}'${DESTDIR}/${SCRIPT}_modules'$${C_NC} symlink for development... "; \
		current_pwd=$${PWD}; \
		( cd ${DESTDIR} && ln -s $${current_pwd}/src/${SCRIPT}_modules ${SCRIPT}_modules ); \
		echo -e "$${C_GREEN}DONE$${C_NC}"; \
	fi
	
install: check $(BUILDDIR)/$(SCRIPT) $(DESTDIR)
	install --mode=0644 $(BUILDDIR)/$(SCRIPT) $(DESTDIR)/$(SCRIPT)
	@if [ -L "$(DESTDIR)/$(SCRIPT)_modules" ]; then \
		echo -en "$${C_YELLOW}WARNING:$${C_NC} about to delete $${C_BOLD}'$(DESTDIR)/$(SCRIPT)_modules$${C_NC}'... "; \
		rm -rf "$(DESTDIR)/$(SCRIPT)_modules"; \
		echo -e "$${C_GREEN}DONE$${C_NC}"; \
	fi
	install --target-directory="$(DESTDIR)/$(SCRIPT)_modules" --mode=0644 -D src/$(SCRIPT)_modules/*
	
uninstall: clean
	rm -f "$(DESTDIR)/$(SCRIPT)"
	rm -rf "$(DESTDIR)/$(SCRIPT)_modules"
	@echo -e "$${C_BOLD}'magic enviro'$${C_NC} script uninstalled: $${C_GREEN}OK$${C_NC}"
	
clean:
	rm -rf $(BUILDDIR)
	@echo -e "$${C_BOLD}'magic enviro'$${C_NC} sources cleaned: $${C_GREEN}OK$${C_NC}"
