# (c) 2011 Mandriva, http://www.mandriva.com
#
# $Id$
#
# This file is part of Pulse 2, http://pulse2.mandriva.org
#
# Pulse 2 is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Pulse 2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Pulse 2; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
include $(topdir)/version.mk

.DEFAULT_GOAL = all
DISTCLEANFILES = 
CLEANFILES = *~
ARCHITECTURE = i386
CC = gcc

archivebase = $(project)-$(version)-source
archivedate := $(shell date +%Y%m%d%H%M%S)
binarybase := $(project)-$(linux_version)+$(archivedate)

#
# Paths
#
imaginglibdir = /usr/lib/pulse2/imaging
imagingdir = /var/lib/pulse2/imaging

bootloaderdir = $(imagingdir)/bootloader
disklessdir = $(imagingdir)/diskless
postinstdir = $(imagingdir)/postinst
computersdir = $(imagingdir)/computers
mastersdir = $(imagingdir)/masters

initramfsdir = $(imagingdir)/initramfs/initrd
initcdfsdir = $(imagingdir)/initramfs/initrdcd

# Tools related dirs
lrs_topdir = $(topdir)/tools/revosave
bindir = $(initramfsdir)/bin
usrbindir = $(initramfsdir)/usr/bin
libdir = $(initramfsdir)/lib
usrlibdir = $(initramfsdir)/usr/lib
rcdir = $(initramfsdir)/etc/init.d
revobindir = $(initramfsdir)/revobin

#
# Tools
#
install = $(shell which install)
install_DATA = $(install) -m 644
install_BIN = $(install) -m 755

#
# Some useful rules
#
gcc_arch = $(shell gcc -dumpmachine | sed 's/^\([^-]\+\)-.*/\1/')

check-arch:
	@case $(gcc_arch) in \
	  i?86) \
	    ;; \
	  *) \
	    echo "###"; \
	    echo "### Must be built on i386 system"; \
	    echo "###"; \
	    exit 1; \
	    ;; \
	esac

check-root:
	@if test `id -u` -ne 0; then \
	  echo "###"; \
	  echo "### You must be root"; \
	  echo "###"; \
	  exit 1; \
	fi

# Stolen from a automake generated makefile, a little bit modified:
# - Do not use portable 'cd'
# - Dir local rules are called *-local, not *-am
# - Do not use maintainer-clean target
# - Must handle the case *-local rules are not defined
RECURSIVE_TARGETS = all-recursive install-recursive
RECURSIVE_CLEAN_TARGETS = clean-recursive distclean-recursive

all: all-recursive
install: install-recursive
clean: clean-recursive
distclean: distclean-recursive

$(RECURSIVE_TARGETS):
	@fail= failcom='exit 1'; \
	for f in x $$MAKEFLAGS; do \
	  case $$f in \
	    *=* | --[!k]*);; \
	    *k*) failcom='fail=yes';; \
	  esac; \
	done; \
	dot_seen=no; \
	target=`echo $@ | sed s/-recursive//`; \
	list='$(SUBDIRS)'; for subdir in $$list; do \
	  echo "Making $$target in $$subdir"; \
	  local_target=; \
	  if test "$$subdir" = "."; then \
	    dot_seen=yes; \
	    local_target="$$target-local"; \
	  else \
	    local_target="$$target"; \
	  fi; \
	  (cd $$subdir && $(MAKE) $$target-common && $(MAKE) $$local_target) \
	  || eval $$failcom; \
	done; \
	if test "$$dot_seen" = "no"; then \
	  $(MAKE) $$target-common && $(MAKE) $$target-local || exit 1; \
	fi; test -z "$$fail"

all-common: check-arch

ifeq ($(nobuild),1)
install-common:
else
install-common: all
endif
	mkdir -p $(imagingdir)

$(RECURSIVE_CLEAN_TARGETS):
	@fail= failcom='exit 1'; \
	for f in x $$MAKEFLAGS; do \
	  case $$f in \
	    *=* | --[!k]*);; \
	    *k*) failcom='fail=yes';; \
	  esac; \
	done; \
	dot_seen=no; \
	rev=''; list='$(SUBDIRS)'; for subdir in $$list; do \
	  if test "$$subdir" = "."; then :; else \
	    rev="$$subdir $$rev"; \
	  fi; \
	done; \
	rev="$$rev ."; \
	target=`echo $@ | sed s/-recursive//`; \
	for subdir in $$rev; do \
	  echo "Making $$target in $$subdir"; \
	  local_target=; \
	  if test "$$subdir" = "."; then \
	    local_target="$$target-local"; \
	  else \
	    local_target="$$target"; \
	  fi; \
	  (cd $$subdir && $(MAKE) $$local_target $$target-common) \
	  || eval $$failcom; \
	done && test -z "$$fail"

clean-common:
	find -name '*~' -exec rm {} \;
	for file in $(CLEANFILES); do \
	  rm -f $$file; \
	done

distclean-common: clean
	for file in $(DISTCLEANFILES); do \
	  rm -f $$file; \
	done
	for dir in `find -type d -name 'tmp.*'`; do \
	  rm -rf $$dir; \
	done

#
# Dummy rules in case they are not included in calling Makefile
#
all-local:
install-local:
clean-local:
distclean-local:

.PHONY = $(RECURSIVE_CLEAN_TARGETS) $(RECURSIVE_TARGETS) all-local \
	install-local clean-local distclean-local check-arch \
	check-root

.PHONY: $(PHONY)
