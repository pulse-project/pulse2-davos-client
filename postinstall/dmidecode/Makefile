#
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
topdir = $(abspath ../..)

# dmidecode tool
extra_bin = $(extra_srcdir)/dmidecode
extra_version = 3.0
extra_archive = dmidecode-$(extra_version).tar.gz
extra_uri = http://download.savannah.gnu.org/releases/dmidecode/$(extra_archive)

include $(topdir)/common.mk
include $(topdir)/extra.mk

all-local: $(extra_bin)

$(extra_bin):
	$(MAKE) $(extra_srcdir)
	$(MAKE) -C $(extra_srcdir) LDFLAGS="-static"

install-local:
	mkdir -p $(DESTDIR)$(postinstdir)/bin
	$(install_BIN) --strip $(extra_srcdir)/dmidecode $(DESTDIR)$(postinstdir)/bin/dmidecode

clean:
	$(MAKE) -C $(extra_srcdir) clean

