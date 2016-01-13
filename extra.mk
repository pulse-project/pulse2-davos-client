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

#
# These rules allow to fetch and extract an extra archive.
#
# Variables to set:
#  extra_archive: archive file name
#  extra_uri: uri to fetch archive from
#
# Variables set:
#  extra_srcdir: path to root source dir
#
extra_srcdir = sources
extract = $(shell \
	    orig=`readlink -f $(extra_archive)`; \
	    mime=`file --brief --mime-type $$orig`; \
	    if test "$$mime" = "application/zip"; then \
	      echo 'unzip -d'; \
	    elif test "$$mime" = "application/x-gzip"; then \
	      echo 'tar zxCf'; \
	    elif test "$$mime" = "application/x-bzip2"; then \
	      echo 'tar jxCf'; \
	    elif test "$$mime" = "application/x-xz"; then \
	      echo 'tar JxCf'; \
	    else \
	      echo 'echo Unknown archive mimetype; exit 1'; \
	    fi)

$(extra_srcdir): $(extra_archive)
	if test "x$(extra_archive)" != "x"; then \
	  tmpdir=$(shell mktemp -d --tmpdir=$(CURDIR)) && \
	  $(extract) $$tmpdir/ $< && \
	  mv $$tmpdir/* $@ && \
	  rm -rf $$tmpdir; \
	else \
	  echo "###"; \
	  echo "### extra_archive is not set. Exiting."; \
	  echo "###"; \
	  exit 1; \
	fi

$(extra_archive):
	@if test "x$(extra_uri)" != "x"; then \
	  if test -e /usr/src/$(extra_archive); then \
	    ln -fs /usr/src/$(extra_archive) $@; \
	  else \
	    wget -O $@ $(extra_uri); \
	  fi; \
	else \
	  echo "###"; \
	  echo "### No URI provided to retrieve: $@"; \
	  echo "###"; \
	  false; \
	fi

distclean-local: distclean-extra
distclean-extra:
	rm -rf tmp.*
	rm -rf $(extra_srcdir)
