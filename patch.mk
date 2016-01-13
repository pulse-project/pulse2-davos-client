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
# Patching rules. To be able to use this rule, set the following:
# - patch_srcdir: dir to apply patches onto
#
# ... and call patched_srcdir target
#
stamp_patch = $(patch_srcdir)/.stamp-patches
CLEANFILES += $(stamp_patch)
do_patch = $(words $(wildcard patches/series))

# ZE high-level target
patched-srcdir: apply-patches-$(do_patch)

apply-patches: apply-patches-$(do_patch)
apply-patches-0: $(patch_srcdir)
apply-patches-1: $(patch_srcdir)/.stamp-patches

$(patch_srcdir)/.stamp-patches: patches/series $(patch_srcdir)
	patches=$(abspath $(CURDIR)/patches); \
	  cd $(patch_srcdir) && \
	  QUILT_PATCHES=$$patches quilt push -a; \
	  test "$$?" -eq 2 -o "$$?" -eq 0
	touch $@

unapply-patches: unapply-patches-$(do_patch)
unapply-patches-0:
unapply-patches-1:
	patches=$(abspath $(CURDIR)/patches); \
	  cd $(patch_srcdir) && \
	  QUILT_PATCHES=$$patches quilt pop -a; \
	  test "$$?" -eq 2 -o "$$?" -eq 0
	rm -f .stamp-patches

distclean-local: distclean-patch
distclean-patch:
	rm -rf .pc

.PHONY = apply-patches apply-patches-0 apply-patches-1 \
	unapply-patches unapply-patches-0 unapply-patches-1 \
	patched_srcdir
