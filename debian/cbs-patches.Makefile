# These are based on Colin's Build System
DEB_PATCHDIRS ?= debian/patches
DEB_PATCHES ?= $(foreach dir,$(DEB_PATCHDIRS),$(shell echo $(wildcard $(dir)/*.patch) $(wildcard $(dir)/*.diff)))

pre-build:
	# Emptly rule to please CBS patch rules

# The patch subsystem
apply-patches: pre-build debian/stamp-patched
debian/stamp-patched: $(DEB_PATCHES)
debian/stamp-patched reverse-patches:
	@echo "patches: $(DEB_PATCHES)"
	@set -e ; reverse=""; patches="$(DEB_PATCHES)"; \
	  if [ "$@" = "reverse-patches" ]; then \
	    reverse="-R"; \
	    for patch in $$patches; do reversepatches="$$patch $$reversepatches"; done; \
	    patches="$$reversepatches"; \
	  fi; \
	  for patch in $$patches; do \
	  level=$(head $$patch | egrep '^#DPATCHLEVEL=' | cut -f 2 -d '='); \
	  success=""; \
	  if [ -z "$$level" ]; then \
	    echo -n "Trying "; if test -n "$$reverse"; then echo -n "reversed "; fi; echo -n "patch $$patch at level "; \
	    for level in 0 1 2; do \
	      if test -z "$$success"; then \
	        echo -n "$$level..."; \
	        if cat $$patch | patch $$reverse --dry-run -p$$level 1>$$patch.level-$$level.log 2>&1; then \
	          if cat $$patch | patch $$reverse --no-backup-if-mismatch -V never -p$$level 1>$$patch.level-$$level.log 2>&1; then \
	            success=yes; \
	            touch debian/stamp-patch-$$(basename $$patch); \
	            echo "success."; \
	          fi; \
	        fi; \
	      fi; \
	    done; \
	    if test -z "$$success"; then \
	      if test -z "$$reverse"; then \
	        echo "failure."; \
	        exit 1; \
	       else \
	         echo "failure (ignored)."; \
	       fi \
	    fi; \
	  else \
	    echo -n "Trying patch $$patch at level $$level..."; \
	    if cat $$patch | patch $$reverse --no-backup-if-mismatch -V never -p$$level 1>$$patch.log 2>&1; then \
	      touch debian/stamp-patch-$$(basename $$patch); \
	      echo "success."; \
	    else \
	      echo "failure:"; \
	      cat $$patch.log; \
	      if test -z "$$reverse"; then exit 1; fi; \
	    fi; \
	  fi; \
	done
	if [ "$@" = "debian/stamp-patched" ]; then touch debian/stamp-patched; fi

post-patches: debian/stamp-post-patches
debian/stamp-post-patches: apply-patches
#	$(internal_invoke) deb-post-patches
	touch $@
