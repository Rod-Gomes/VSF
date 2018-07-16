# makefile to build VSF
VCLDIR = /etc/varnish/security
INSTALLGROUP = root

RULES = $(shell ls vcl/rules/*.vcl)

build: libvmod-vsf/src/.libs/libvmod-vsf.so vcl

libvmod-vsf/src/.libs/libvmod-vsf.so: libvmod-vsf/utf8proc/utf8proc.c
	@cd libvmod-vsf && ./autogen.sh
	@cd libvmod-vsf && ./configure
	@${MAKE} -C libvmod-vsf

libvmod-vsf/utf8proc/utf8proc.c:
	@git submodule init
	@git submodule update

vcl:
	@${MAKE} -C vcl

install: 
	@${MAKE} -C libvmod-vsf $@
	install -o root -g ${INSTALLGROUP} -d ${DESTDIR}${VCLDIR}
	install -o root -g ${INSTALLGROUP} -d ${DESTDIR}${VCLDIR}/rules
	install -o root -g ${INSTALLGROUP} -d ${DESTDIR}${VCLDIR}/build
	install -o root -g ${INSTALLGROUP} -m 644 vcl/vsf.vcl ${DESTDIR}${VCLDIR}
	install -o root -g ${INSTALLGROUP} -m 644 vcl/config.vcl ${DESTDIR}${VCLDIR}
	install -o root -g ${INSTALLGROUP} -m 644 vcl/handlers.vcl ${DESTDIR}${VCLDIR}
	install -o root -g ${INSTALLGROUP} -m 644 vcl/local.vcl.example ${DESTDIR}${VCLDIR}/local.vcl
	for rule in ${RULES}; do install -o root -g ${INSTALLGROUP} -m 644 $$rule ${DESTDIR}${VCLDIR}/rules/$${rule#vcl/rules/}; done
	install -o root -g ${INSTALLGROUP} -m 644 vcl/build/variables.vcl ${DESTDIR}${VCLDIR}/build/variables.vcl

check: build vcl-check
	@${MAKE} -C libvmod-vsf $@

vcl-check:
	cp vcl/local.vcl.example vcl/local.vcl
	sed -i "s@import vsf;@import vsf from \"$$PWD/libvmod-vsf/src/.libs/libvmod_vsf.so\";@" vcl/vsf.vcl
	varnishtest tests/*.vtc
	rm vcl/local.vcl
	sed -i 's/import vsf from .*$$/import vsf;/' vcl/vsf.vcl
	
.PHONY: build check vcl-check vcl
