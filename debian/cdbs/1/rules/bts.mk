# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2004 Jonas Smedegaard <dr@jones.dk>
# Description: Install control files for the Debian Bug Tracking System
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

ifndef _cdbs_class_bts
_cdbs_class_bts := 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)

$(patsubst %,install/%,$(DEB_ALL_PACKAGES)) :: install/% :
	@if test -e "debian/$(cdbs_curpkg).bts" || test -e "debian/bts" || test -n "$(DEBEMAIL)"; then \
		mkdir -p "debian/$(cdbs_curpkg)/usr/share/bug/$(cdbs_curpkg)"; \
			if test -e "debian/$(cdbs_curpkg).bts"; then \
			install "debian/$(cdbs_curpkg).bts" "debian/$(cdbs_curpkg)/usr/share/bug/$(cdbs_curpkg)/bts"; \
		elif test -e "debian/bts"; then \
			install "debian/bts" "debian/$(cdbs_curpkg)/usr/share/bug/$(cdbs_curpkg)/bts"; \
		elif test -n "$(DEBEMAIL)"; then \
			echo "Send-To: $(DEBEMAIL)" > "debian/$(cdbs_curpkg)/usr/share/bug/$(cdbs_curpkg)/bts"; \
		fi; \
	else \
		echo "DEBEMAIL unset and no bts file for $(cdbs_curpkg); not diverting"; \
	fi

endif
