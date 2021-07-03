# Main project's Makefile
SHELL := /bin/bash
DESTDIR := $${HOME}/bin
SCRIPT := bash-magic-enviro

# Style table
export C_BOLD := \033[1m
export C_GREEN := \033[1;32m
export C_YELLOW := \033[1;1;33m
export C_RED := \033[1;31m
export C_NC := \033[0m

# Basic targets
.PHONY: targets check uninstall

targets:
	@echo -e "$${C_BOLD}Main targets are:$${C_NC}"
	@echo -e "\t$${C_BOLD}targets:$${C_NC} this one (default)."
	@echo -e "\t$${C_BOLD}check:$${C_NC} checks requirements."
	@echo -e "\t$${C_BOLD}dev:$${C_NC} creates symlinks for easier development of this tool."
	@echo -e "\t$${C_BOLD}install:$${C_NC} installs this product."
	@echo -e "\t$${C_BOLD}uninstall:$${C_NC} uninstalls this product."
	
check:
	@echo -e "$${C_BOLD}Checking requirements...$${C_NC}"
# Checks if ~/bin exists
	@if [ ! -d ~/bin ]; then \
		echo -e "$${C_RED}ERROR:$${C_NC} $${C_BOLD}'~/bin'$${C_NC} doesn't exist."; \
		echo -en "\tDo you want me to create it? [y/N] " && read ans && [ $${ans:-N} = y ]; \
		case "$$ans" in \
			[yY]) \
				echo -en "\tCreating bin dir... "; \
				mkdir --mode=0750 ~/bin; \
				if [ $$? -eq 0 ]; then \
					echo -e "$${C_GREEN}OK$${C_NC}"; \
					exit 0; \
				else \
					echo -e "\t$${C_RED}FAIL$${C_NC}"; \
					exit 1; \
				fi ;; \
			*) \
				echo -e "\t$${C_BOLD}NOT$${C_NC} creating '~/bin' dir."; \
				exit 1;; \
		esac; \
	else \
		echo -e "\t$${C_BOLD}~/bin$${C_NC} exists: $${C_GREEN}OK$${C_NC}"; \
	fi
# Checks if ~/bin is in path
	@if [[ ! "$$PATH" =~ (^|:)"$${HOME}/bin"(:|$$) ]]; then \
		echo -en "$${C_RED}ERROR:$${C_NC} $${C_BOLD}'~/bin'$${C_NC} not in path. "; \
		echo -e "You need to add it!"; \
		echo -e "\t$${C_BOLD}PATH:$${C_NC} $${PATH}"; \
		exit 1; \
	else \
		echo -e "\t$${C_BOLD}~/bin$${C_NC} in PATH: $${C_GREEN}OK$${C_NC}"; \
	fi
	
dev: check
# Symlinks the main script
	@if ! [ -L ${DESTDIR}/${SCRIPT} ]; then \
		if [ -e ${DESTDIR}/${SCRIPT} ]; then \
			echo -en "$${C_YELLOW}WARNING:$${C_NC} about to delete $${C_BOLD}'${DESTDIR}/${SCRIPT}$${C_NC}'... "; \
			rm -rf "$(DESTDIR)/$(SCRIPT)"; \
			echo -e "$${C_GREEN}DONE$${C_NC}"; \
		fi; \
		echo -en "Creating $${C_BOLD}'${DESTDIR}/${SCRIPT}'$${C_NC} symlink for development... "; \
		current_pwd=$${PWD}; \
		( cd ${DESTDIR} && ln -s $${current_pwd}/src/${SCRIPT} ${SCRIPT} ); \
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
	
install: check
	install --mode=0640 src/$(SCRIPT) $(DESTDIR)/$(SCRIPT)
	@if [ -L "$(DESTDIR)/$(SCRIPT)_modules" ]; then \
		echo -en "$${C_YELLOW}WARNING:$${C_NC} about to delete $${C_BOLD}'$(DESTDIR)/$(SCRIPT)_modules$${C_NC}'... "; \
		rm -rf "$(DESTDIR)/$(SCRIPT)_modules"; \
		echo -e "$${C_GREEN}DONE$${C_NC}"; \
	fi
	install --target-directory="$(DESTDIR)/$(SCRIPT)_modules" --mode=0640 -D src/$(SCRIPT)_modules/*
	
uninstall:
	rm -f "$(DESTDIR)/$(SCRIPT)"
	@echo -e "$${C_BOLD}'magic enviro'$${C_NC} script uninstalled: $${C_GREEN}OK$${C_NC}"
	