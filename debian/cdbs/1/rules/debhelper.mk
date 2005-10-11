# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2002,2003 Colin Walters <walters@debian.org>
# Description: Uses Debhelper to implement the binary package building stage
#  Note that we require debhelper (>= 4.1.0).
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

####
# General variables implemented by this rule file:
#
# DEB_INSTALL_DIRS_ALL
#   Subdirectories to create in installation staging directory for every package
# DEB_INSTALL_DIRS_<package>
#   Like the above, but for a particular package <package>.
# DEB_INSTALL_DOCS_ALL
#   Files which should go in /usr/share/doc/<package> for every package
# DEB_INSTALL_DOCS_<package>
#   Files which should go in /usr/share/doc/<package> for package
# DEB_INSTALL_CHANGELOGS_ALL
#   File which should be interpreted as upstream changelog
# DEB_COMPRESS_EXCLUDE
#   Shell wildcards matching files which should not be compressed.
# DEB_FIXPERMS_EXCLUDE
#   Shell wildcards matching files which should not have their permissions changed.
# DEB_DH_ALWAYS_EXCLUDE
#   Force builddeb to exclude files.  See the DH_ALWAYS_EXCLUDE section
#   in debhelper(7) for more details.
# DEB_SHLIBDEPS_LIBRARY_package
#   The name of the current library package
# DEB_SHLIBDEPS_INCLUDE
#   A space-separated list of library paths to search for dependency info
# DEB_SHLIBDEPS_INCLUDE_package
#   Like the above, but for a particular package.
# DEB_PERL_INCLUDE
#   A space-separated list of paths to search for perl modules
# DEB_PERL_INCLUDE_package
#   Like the above, but for a particular package.
# DEB_UPDATE_RCD_PARAMS
#   Arguments to pass to update-rc.d in init scripts
####
# Special variables used by this rule file:
#
# DEB_DH_MAKESHLIBS_ARGS_ALL
#   Arguments passed directly to dh_makeshlibs, for all packages
# DEB_DH_MAKESHLIBS_ARGS_<package>
#   Arguments passed directly to dh_makeshlibs, for a particular package <package>
# DEB_DH_MAKESHLIBS_ARGS
#   Completely override argument passing to dh_makeshlibs. 
# DEB_DH_SHLIBDEPS_ARGS
#   Completely override argument passing to dh_shlibdeps.
# DEB_DH_PERL_ARGS
#   Completely override argument passing to dh_perl.
####

ifndef _cdbs_bootstrap
_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class
endif

ifndef _cdbs_rules_debhelper
_cdbs_rules_debhelper := 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)

CDBS_BUILD_DEPENDS	:= $(CDBS_BUILD_DEPENDS), debhelper (>= 4.1.0)

DH_COMPAT=4

ifeq ($(DEB_VERBOSE_ALL), yes)
DH_VERBOSE = 1
endif

is_debug_package=$(if $(patsubst %-dbg,,$(cdbs_curpkg)),,yes)

DEB_INSTALL_DIRS_ALL =
DEB_INSTALL_CHANGELOGS_ALL = $(if $(DEB_ISNATIVE),,$(shell for f in ChangeLog Changelog Changes CHANGES; do if test -s $(DEB_SRCDIR)/$$f; then echo $(DEB_SRCDIR)/$$f; break; fi; done))
DEB_INSTALL_DOCS_ALL = $(filter-out $(DEB_INSTALL_CHANGELOGS_ALL),$(shell for f in README NEWS TODO BUGS AUTHORS THANKS; do if test -s $(DEB_SRCDIR)/$$f; then echo $(DEB_SRCDIR)/$$f; fi; done))

cdbs_add_dashx = $(foreach i,$(1),$(patsubst %,-X %,$(i)))

DEB_DH_MAKESHLIBS_ARGS = $(DEB_DH_MAKESHLIBS_ARGS_ALL) $(DEB_DH_MAKESHLIBS_ARGS_$(cdbs_curpkg))
DEB_DH_SHLIBDEPS_ARGS = $(if $(DEB_SHLIBDEPS_LIBRARY_$(cdbs_curpkg)),-L $(DEB_SHLIBDEPS_LIBRARY_$(cdbs_curpkg))) $(if $(DEB_SHLIBDEPS_INCLUDE_$(cdbs_curpkg))$(DEB_SHLIBDEPS_INCLUDE),-l $(shell echo $(DEB_SHLIBDEPS_INCLUDE_$(cdbs_curpkg)):$(DEB_SHLIBDEPS_INCLUDE) | perl -pe 's/ /:/g;'))

DEB_DH_BUILDDEB_ENV = $(if $(DEB_DH_ALWAYS_EXCLUDE),DH_ALWAYS_EXCLUDE=$(DEB_DH_ALWAYS_EXCLUDE),)
DEB_DH_PERL_ARGS = $(if $(DEB_PERL_INCLUDE_$(cdbs_curpkg))$(DEB_PERL_INCLUDE),$(shell echo $(DEB_PERL_INCLUDE_$(cdbs_curpkg)) $(DEB_PERL_INCLUDE)))

pre-build::
	if [ -z "$(DEB_DH_COMPAT_DISABLE)" ]; then \
	  if ! test -f debian/compat; then echo $(DH_COMPAT) > debian/compat; fi; \
	fi

clean::
	dh_clean

common-install-prehook-arch common-install-prehook-indep:: common-install-prehook-impl
common-install-prehook-impl::
	dh_clean -k
	dh_installdirs -A $(DEB_INSTALL_DIRS_ALL)

$(patsubst %,install/%,$(DEB_ALL_PACKAGES)) :: install/%:
	dh_installdirs -p$(cdbs_curpkg) $(DEB_INSTALL_DIRS_$(cdbs_curpkg))

# Create .debs or .udebs as we see fit
$(patsubst %,binary/%,$(DEB_PACKAGES)) :: binary/% : binary-makedeb/%
$(patsubst %,binary/%,$(DEB_UDEB_PACKAGES)) :: binary/% : binary-makeudeb/%

####
# General Debian package creation rules.
####

# This rule is called once for each (non-udeb) package.  It does the work
# of installing to debian/<packagename>; this includes running
# dh_install to split the source from debian/tmp, as well as installing
# ChangeLogs and the like.
$(patsubst %,binary-install/%,$(DEB_PACKAGES)) :: binary-install/%:
	dh_installdocs -p$(cdbs_curpkg) $(DEB_INSTALL_DOCS_ALL) $(DEB_INSTALL_DOCS_$(cdbs_curpkg)) 
	dh_installexamples -p$(cdbs_curpkg) $(DEB_INSTALL_EXAMPLES_$(cdbs_curpkg))
	dh_installman -p$(cdbs_curpkg) $(DEB_INSTALL_MANPAGES_$(cdbs_curpkg)) 
	dh_installinfo -p$(cdbs_curpkg) $(DEB_INSTALL_INFO_$(cdbs_curpkg)) 
	dh_installmenu -p$(cdbs_curpkg) $(DEB_DH_INSTALL_MENU_ARGS)
	dh_installcron -p$(cdbs_curpkg) $(DEB_DH_INSTALL_CRON_ARGS)
	dh_installinit -p$(cdbs_curpkg) $(if $(DEB_UPDATE_RCD_PARAMS),--update-rcd-params=$(DEB_UPDATE_RCD_PARAMS),$(if $(DEB_UPDATE_RCD_PARAMS_$(cdbs_curpkg)),--update-rcd-params=$(DEB_UPDATE_RCD_PARAMS_$(cdbs_curpkg)))) $(DEB_DH_INSTALLINIT_ARGS) 
#	dh_installdebconf -p$(cdbs_curpkg) $(DEB_DH_INSTALLDEBCONF_ARGS)
	dh_installemacsen -p$(cdbs_curpkg) $(if $(DEB_EMACS_PRIORITY),--priority=$(DEB_EMACS_PRIORITY)) $(if $(DEB_EMACS_FLAVOR),--flavor=$(DEB_EMACS_FLAVOR)) $(DEB_DH_INSTALLEMACSEN_ARGS)
	dh_installpam -p$(cdbs_curpkg) $(DEB_DH_INSTALLPAM_ARGS)
	dh_installlogrotate -p$(cdbs_curpkg) $(DEB_DH_INSTALLLOGROTATE_ARGS)
	if test -x /usr/bin/dh_installlogcheck; then dh_installlogcheck -p$(cdbs_curpkg) $(DEB_DH_INSTALLLOGCHECK_ARGS); fi
	dh_installchangelogs -p$(cdbs_curpkg) $(DEB_DH_INSTALLCHANGELOGS_ARGS) $(DEB_INSTALL_CHANGELOGS_ALL) $(DEB_INSTALL_CHANGELOGS_$(cdbs_curpkg))
	dh_install -p$(cdbs_curpkg) $(if $(DEB_DH_INSTALL_SOURCEDIR),--sourcedir=$(DEB_DH_INSTALL_SOURCEDIR)) $(DEB_DH_INSTALL_ARGS)
	dh_link -p$(cdbs_curpkg) $(DEB_DH_LINK_ARGS) $(DEB_DH_LINK_$(cdbs_curpkg))

# This rule is called after all packages have been installed, and their
# post-install hooks have been run.
common-binary-post-install-arch:: $(patsubst %,binary-post-install/%,$(DEB_ARCH_REGULAR_PACKAGES))
common-binary-post-install-indep:: $(patsubst %,binary-post-install/%,$(DEB_INDEP_REGULAR_PACKAGES))

# This rule is called once for each package; it's a general hook
# to do things like remove files, etc.
$(patsubst %,binary-post-install/%,$(DEB_PACKAGES)) :: binary-post-install/%: binary-install/%

# This rule is called after installation and the post-install hooks,
# to strip files.
$(patsubst %,binary-strip/%,$(DEB_ARCH_REGULAR_PACKAGES)) :: binary-strip/%: common-binary-post-install-arch binary-strip-IMPL/%
$(patsubst %,binary-strip/%,$(DEB_INDEP_REGULAR_PACKAGES)) :: binary-strip/%: common-binary-post-install-indep binary-strip-IMPL/%
$(patsubst %,binary-strip-IMPL/%,$(DEB_PACKAGES)) :: binary-strip-IMPL/%: 
	if test "$(is_debug_package)"; then :; else dh_strip -p$(cdbs_curpkg) $(foreach entry,$(DEB_STRIP_EXCLUDE),$(patsubst %,-X %,$(entry))) $(DEB_DH_STRIP_ARGS); fi

# This rule is called after stripping; it compresses, fixes permissions,
# and sets up shared library information.
$(patsubst %,binary-fixup/%,$(DEB_PACKAGES)) :: binary-fixup/%: binary-strip/%
	dh_compress -p$(cdbs_curpkg) $(foreach entry,$(DEB_COMPRESS_EXCLUDE),$(patsubst %,-X %,$(entry))) $(DEB_DH_COMPRESS_ARGS)
	dh_fixperms -p$(cdbs_curpkg) $(foreach entry,$(DEB_FIXPERMS_EXCLUDE),$(patsubst %,-X %,$(entry))) $(DEB_DH_FIXPERMS_ARGS)
	if test "$(is_debug_package)"; then :; else dh_makeshlibs -p$(cdbs_curpkg) $(DEB_DH_MAKESHLIBS_ARGS); fi

# This rule is called right before building the binary .deb packages
# for each package, but after the binary-predeb hooks have been run.
common-binary-predeb-arch:: $(patsubst %,binary-predeb/%,$(DEB_ARCH_REGULAR_PACKAGES))
common-binary-predeb-indep:: $(patsubst %,binary-predeb/%,$(DEB_INDEP_REGULAR_PACKAGES))

# This rule is called right before a packages' .deb file is made.
# It is a good place to make programs setuid, change the scripts in DEBIAN/, etc. 
$(patsubst %,binary-predeb/%,$(DEB_PACKAGES)) :: binary-predeb/%: binary-fixup/%
	dh_installdeb -p$(cdbs_curpkg) $(DEB_DH_INSTALLDEB_ARGS)
	dh_perl -p$(cdbs_curpkg) $(DEB_DH_PERL_ARGS)

# This rule is called to create a package.  Generally it's not going to be
# useful to hook things onto this rule.
$(patsubst %,binary-makedeb/%,$(DEB_ARCH_REGULAR_PACKAGES)) :: binary-makedeb/% : common-binary-predeb-arch binary-makedeb-IMPL/%
$(patsubst %,binary-makedeb/%,$(DEB_INDEP_REGULAR_PACKAGES)) :: binary-makedeb/% : common-binary-predeb-indep binary-makedeb-IMPL/%
$(patsubst %,binary-makedeb-IMPL/%,$(DEB_PACKAGES)) :: binary-makedeb-IMPL/% : 
	dh_shlibdeps -p$(cdbs_curpkg) $(DEB_DH_SHLIBDEPS_ARGS)
	dh_gencontrol -p$(cdbs_curpkg) $(DEB_DH_GENCONTROL_ARGS)
	dh_md5sums -p$(cdbs_curpkg) $(DEB_DH_MD5SUMS_ARGS)
	$(DEB_DH_BUILDDEB_ENV) dh_builddeb -p$(cdbs_curpkg) $(DEB_DH_BUILDDEB_ARGS)

## Deprecated
common-binary-post-install:: common-binary-post-install-arch common-binary-post-install-indep
common-binary-predeb:: common-binary-predeb-arch common-binary-predeb-indep

####
# The special .udeb building rules.  Note they don't handle the arch/indep
# split yet.
#### 

$(patsubst %,binary-install-udeb/%,$(DEB_UDEB_PACKAGES)) :: binary-install-udeb/%:
	dh_installcron -p$(cdbs_curpkg) $(DEB_DH_INSTALLCRON_ARGS)
#	dh_installdebconf -p$(cdbs_curpkg) $(DEB_DH_INSTALLDEBCONF_ARGS)
	dh_installpam -p$(cdbs_curpkg) $(DEB_DH_INSTALLPAM_ARGS)
	dh_installinit -p$(cdbs_curpkg) $(DEB_DH_INSTALLINIT_ARGS)
	dh_install -p$(cdbs_curpkg) $(DEB_DH_INSTALL_ARGS)

common-binary-post-install-udeb:: $(patsubst %,binary-post-install-udeb/%,$(DEB_UDEB_PACKAGES))

$(patsubst %,binary-post-install-udeb/%,$(DEB_UDEB_PACKAGES)) :: binary-post-install-udeb/%: binary-install-udeb/%

$(patsubst %,binary-makeudeb/%,$(DEB_UDEB_PACKAGES)) :: binary-makeudeb/% : common-binary-post-install-udeb
	dh_strip -p$(cdbs_curpkg) $(foreach entry,$(DEB_STRIP_EXCLUDE),$(patsubst %,-X %,$(entry))) $(DEB_DH_STRIP_ARGS)
	dh_compress -p$(cdbs_curpkg) $(foreach entry,$(DEB_COMPRESS_EXCLUDE),$(patsubst %,-X %,$(entry)))
	dh_fixperms -p$(cdbs_curpkg) $(foreach entry,$(DEB_FIXPERMS_EXCLUDE),$(patsubst %,-X %,$(entry)))
	dh_makeshlibs -p$(cdbs_curpkg) $(DEB_DH_MAKESHLIBS_ARGS)
	dh_installdeb -p$(cdbs_curpkg) $(DEB_DH_INSTALLDEB_ARGS)
	dh_perl -p$(cdbs_curpkg) $(DEB_DH_PERL_ARGS)
	dh_shlibdeps -p$(cdbs_curpkg) $(DEB_DH_SHLIBDEPS_ARGS)
	# udebs should only have a 'control' file
	rm -f debian/$(cdbs_curpkg)/DEBIAN/*
	dh_gencontrol -p$(cdbs_curpkg) -- -fdebian/files~
	dpkg-distaddfile $(cdbs_curpkg)_$(DEB_NOEPOCH_VERSION)_$(DEB_ARCH).udeb debian-installer optional
	$(DEB_DH_BUILDDEB_ENV) dh_builddeb -p$(cdbs_curpkg) --filename=$(cdbs_curpkg)_$(DEB_NOEPOCH_VERSION)_$(DEB_ARCH).udeb

endif