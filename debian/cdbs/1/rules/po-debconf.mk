# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003-2005 Jonas Smedegaard <dr@jones.dk>
# Description: Woody-compatible debconf template l12n
#  Usage: Add this to all debconf-using packages in debian/control:
#	Depends: ${debconf-depends} (where applicable)
#  If using debhelper.mk, make sure to include this first.
#  If not using debhelper.mk, something like the following should be
#  added to debian/rules:
#	dpkg-gencontrol -V'debconf-depends=debconf (>= $(PODEBCONF_MINDEBCONFVER))'
#  Based on this email by Colin Watson <cjwatson@flatline.org.uk>:
#  http://lists.debian.org/debian-i18n/2003/debian-i18n-200307/msg00026.html

#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307 USA.

# Hack for woody compatibility. This makes sure that the
# debian/templates file shipped in the source package doesn't specify
# encodings, which woody's debconf can't handle. If building on a system
# with po-debconf installed (conveniently debhelper (>= 4.1.16) depends
# on it), the binary-arch target will generate a better version for
# sarge.

ifndef _cdbs_bootstrap
_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class
endif

ifndef _cdbs_rules_podebconf
_cdbs_rules_podebconf := 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)

CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), debhelper (>= 4.1.16), po-debconf

PODEBCONF_MASTERSUFFIX := master
PODEBCONF_TEMPLATEFILES := $(basename $(shell sed 's|[^]]*] ||' debian/po/POTFILES.in))

ifeq (,$(wildcard /usr/bin/po2debconf))
PODEBCONF_PO2DEBCONF := no
DEB_DH_GENCONTROL_DASHDASHARGS += -V'debconf-depends=debconf (>= 0.5)'
else
PODEBCONF_PO2DEBCONF := yes
DEB_DH_GENCONTROL_DASHDASHARGS += -V'debconf-depends=debconf (>= 1.2.0) | debconf-2.0'
endif

DEB_PHONY_RULES += podebconf-sanity-check

clean:: podebconf-sanity-check

podebconf-sanity-check:
	@if ! grep -s -e '$${debconf-depends}' debian/control; then \
		echo 'ERROR: No packages depend on $${debconf-depends}!'; \
		exit 1; \
	fi

ifeq ($(PODEBCONF_PO2DEBCONF),yes)
# the remaining rules won't work on woody (that's the whole point!)

DEB_PHONY_RULES += podebconf-mksimpletemplates podebconf-mkutftemplates

# Make templates woody-compatible in source package
clean:: podebconf-mksimpletemplates
podebconf-mksimpletemplates:
	echo 1 > debian/po/output
	for tmpl in $(PODEBCONF_TEMPLATEFILES); do\
		po2debconf debian/$$tmpl.$(PODEBCONF_MASTERSUFFIX) > debian/$$tmpl; \
	done
	rm -f debian/po/output

# Make templates UTF-encoded in binary packages
common-binary-arch common-binary-indep:: podebconf-mkutftemplates
podebconf-mkutftemplates:
	for tmpl in $(PODEBCONF_TEMPLATEFILES); do\
		po2debconf -e utf8 debian/$$tmpl.$(PODEBCONF_MASTERSUFFIX) > debian/$$tmpl; \
	done

endif
endif
