#
# (c) 2010-2011 Mandriva, http://www.mandriva.com
#
# Author(s):
#  Nicolas Rueff
#  Jean Parpaillon
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
SUBDIRS = dmidecode chntpw fuse ntfs3g ddrescue

topdir = $(abspath ..)
include $(topdir)/common.mk
include $(topdir)/extra.mk

install-local:
	mkdir -p $(DESTDIR)$(postinstdir)/bin
	$(install_BIN) bin/mountdisk $(DESTDIR)$(postinstdir)/bin/mountdisk
	$(install_BIN) bin/fix-winxp-blue-screen-after-hardware-change $(DESTDIR)$(postinstdir)/bin/fix-winxp-blue-screen-after-hardware-change
	mkdir -p $(DESTDIR)$(postinstdir)/lib
	$(install_DATA) lib/libpostinst.sh $(DESTDIR)$(postinstdir)/lib/libpostinst.sh
	cp -a lib/fix-winxp-blue-screen-after-hardware-change $(DESTDIR)$(postinstdir)/lib/
	mkdir -p $(DESTDIR)$(postinstdir)/winutils
	$(install_DATA) winutils/newsid.exe $(DESTDIR)$(postinstdir)/winutils/newsid.exe
	mkdir -p $(DESTDIR)$(postinstdir)/macutils
	cp -a macutils $(DESTDIR)$(postinstdir)/
	mkdir -p $(DESTDIR)$(postinstdir)/linuxutils
	cp -a linuxutils $(DESTDIR)$(postinstdir)/
	chmod 0755 $(DESTDIR)$(postinstdir)/macutils/pulse2-inventory-agent/install.sh
	mkdir -p $(DESTDIR)$(postinstdir)/sysprep/drivers
