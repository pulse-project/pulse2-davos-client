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

extra_bin = $(extra_srcdir)/src/lowntfs-3g
extra_version = 2012.1.15
extra_archive = ntfs-3g_ntfsprogs-$(extra_version).tgz
extra_uri = http://tuxera.com/opensource/$(extra_archive)

include $(topdir)/common.mk
include $(topdir)/extra.mk

all-local: $(extra_bin)

$(extra_bin): $(extra_srcdir)/Makefile
	$(MAKE) -C $(extra_srcdir)

$(extra_srcdir)/Makefile:
	$(MAKE) $(extra_srcdir)
	cd $(extra_srcdir) && ./configure --enable-mtab=no --disable-library

install-local:
	mkdir -p $(DESTDIR)$(postinstdir)/bin
	$(install_BIN) --strip $(extra_bin) $(DESTDIR)$(postinstdir)/bin/ntfs-3g
	ln -sf ntfs-3g $(DESTDIR)$(postinstdir)/bin/mount.ntfs
	$(install_BIN) --strip $(extra_srcdir)/ntfsprogs/ntfsresize $(DESTDIR)$(postinstdir)/bin/ntfsresize

clean:
	$(MAKE) -C $(extra_srcdir) clean


