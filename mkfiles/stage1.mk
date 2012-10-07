.INTERMEDIATE: stage1 stage1-spool stage1-moonbase stage1-toolchain stage1-build stage1-cache

.SECONDARY: $(ISO_TARGET)/.stage1-spool $(ISO_TARGET)/.stage1-moonbase $(ISO_TARGET)/.stage1-toolchain $(ISO_TARGET)/.stage1

stage1: stage1-cache


# install the sources
$(ISO_TARGET)/.stage1-spool: download
	@echo stage1-spool
	@mkdir -p $(ISO_TARGET)/var/spool/lunar
	@cp $(ISO_SOURCE)/spool/* $(ISO_TARGET)/var/spool/lunar/
	@touch $@

stage1-spool: $(ISO_TARGET)/.stage1-spool


# generate the required cache files
$(ISO_TARGET)/.stage1-moonbase: bootstrap install-moonbase
	@echo stage1-moonbase
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_module_index
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_depends_cache
	@$(ISO_SOURCE)/scripts/chroot-build lsh update_plugins
	@touch $@

stage1-moonbase: $(ISO_TARGET)/.stage1-moonbase


# first build sequence to get the toolchain installed properly
$(ISO_TARGET)/.stage1-toolchain: stage1-moonbase stage1-spool
	@echo stage1-toolchain
	@yes n | tr -d '\n' | $(ISO_SOURCE)/scripts/chroot-build lin -rc kernel-headers glibc binutils gcc binutils glibc
	@touch $@

stage1-toolchain: $(ISO_TARGET)/.stage1-toolchain


# first time build all the require modules for a minimal system
STAGE1_MODULES=acl attr bash bzip2 coreutils cracklib dialog diffutils e2fsprogs file findutils gawk glib-2 gmp grep gzip installwatch less libcap libffi libmpc lunar make mpfr ncurses net-tools patch pcre perl procps readline sed shadow tar util-linux wget xz zlib

$(ISO_TARGET)/.stage1: stage1-toolchain
	@echo stage1-build
	@yes n | tr -d '\n' | $(ISO_SOURCE)/scripts/chroot-build lin -rc $(STAGE1_MODULES)
	@touch $@

stage1-build: $(ISO_TARGET)/.stage1


# replace the cache with the new build cache
$(ISO_SOURCE)/cache/.stage1: stage1-build
	@echo stage1-cache
	@rm -rf $(ISO_SOURCE)/cache
	@cp -r $(ISO_TARGET)/var/cache/lunar $(ISO_SOURCE)/cache
	@grep $(patsubst %,-e^%:,$(STAGE1_MODULES)) $(ISO_TARGET)/var/state/lunar/packages | cat > $(ISO_SOURCE)/cache/packages
	@tar -cjf $(ISO_SOURCE)/cache/fixup-$(ISO_BUILD).tar.bz2 -C $(ISO_TARGET) lib/$(ISO_LD_LINUX) lib/libc.so.6 lib/libdl.so.2 lib/libm.so.6 lib/librt.so.1 lib/libpthread.so.0 lib/libnss_files.so.2 lib/libutil.so.1 lib/libnsl.so.1 lib/libcrypt.so.1
	@touch $@

stage1-cache: $(ISO_SOURCE)/cache/.stage1