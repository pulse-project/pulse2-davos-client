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

# Offline NT password and registry editor
extra_bin = $(extra_srcdir)/chntpw.static $(extra_srcdir)/reged.static
extra_version = 110511
extra_archive = chntpw-source-$(extra_version).zip
extra_uri = http://pogostick.net/~pnh/ntpasswd/$(extra_archive)

include $(topdir)/common.mk
include $(topdir)/extra.mk

all-local: $(extra_bin)

$(extra_bin):
	$(MAKE) $(extra_srcdir)
	$(MAKE) -C $(extra_srcdir)

install-local:
	mkdir -p $(DESTDIR)$(postinstdir)/bin
	$(install_BIN) --strip $(extra_srcdir)/chntpw.static $(DESTDIR)$(postinstdir)/bin/chntpw
	$(install_BIN) --strip $(extra_srcdir)/reged.static $(DESTDIR)$(postinstdir)/bin/reged

clean:
	$(MAKE) -C $(extra_srcdir) clean

