# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2005-2006 Jonas Smedegaard <dr@jones.dk>
# Description: Auto-update debian/control from debian/control.in
#  When the environment variable DEB_BUILD_OPTIONS contains the magic
#  string "update" the clean target is extended to auto-update
#  debian/control from debian/control.in where build-depends can contain
#  the magic string @cdbs@ expanded to build-dependencies known to cdbs,
#  and more...
#
#  In other words, with this in use don't edit debian/control directly,
#  but instead edit debian/control.in and invoke the following:
#    DEB_BUILD_OPTIONS=update fakeroot debian/rules clean
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

ifndef _cdbs_bootstrap
_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class
endif

ifndef _cdbs_rules_auto-update
_cdbs_rules_auto-update := 1

ifneq (,$(findstring update,$(DEB_BUILD_OPTIONS)))
DEB_AUTO_UPDATE_DEBIAN_CONTROL := yes
endif

# Avoid build-dependency on build-essential (to please ftpmasters)
CDBS_BUILD_DEPENDS :=
endif
