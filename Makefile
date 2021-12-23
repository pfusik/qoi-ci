CFLAGS = -O2 -Wall
GIMP_LDFLAGS = `gimptool-2.0 --libs`
ifeq ($(OS),Windows_NT)
EXEEXT = .exe
GIMP_LDFLAGS += -Wl,-subsystem,windows
XNVIEW_DIR = C:/Program Files/XnViewMP
SUDO = elevate
else
XNVIEW_DIR = /opt/XnView
endif
TRANSPILED = $(addprefix transpiled/QOI., c cpp cs js py swift) transpiled/QOIDecoder.java

all: png2qoi$(EXEEXT) Xqoi.usr $(TRANSPILED)

png2qoi$(EXEEXT): png2qoi.c QOI-stdio.c QOI-stdio.h transpiled/QOI.c
	$(CC) $(CFLAGS) -I transpiled -o $@ png2qoi.c QOI-stdio.c transpiled/QOI.c -lpng

file-qoi$(EXEEXT): file-qoi.c QOI-stdio.c QOI-stdio.h transpiled/QOI.c
	$(CC) $(CFLAGS) -I transpiled `gimptool-2.0 --cflags` -o $@ file-qoi.c QOI-stdio.c transpiled/QOI.c $(GIMP_LDFLAGS)

Xqoi.usr: Xqoi.c QOI-stdio.c QOI-stdio.h transpiled/QOI.c
	$(CC) $(CFLAGS) -I transpiled -o $@ Xqoi.c QOI-stdio.c transpiled/QOI.c -shared

install-gimp: file-qoi$(EXEEXT)
ifeq ($(OS),Windows_NT)
	# gimptool-2.0 broken on mingw64
	install -D $< `gimptool-2.0 --gimpplugindir`/plug-ins/file-qoi.exe
else ifdef BUILDING_PACKAGE
	install -D $< $(libdir)/gimp/2.0/plug-ins/file-qoi/file-qoi
else
	gimptool-2.0 --install-admin-bin $<
endif

install-xnview: Xqoi.usr
	$(SUDO) install -D -m 644 $< "$(XNVIEW_DIR)/Plugins/Xqoi.usr"

$(TRANSPILED): QOI.ci
	mkdir -p $(@D) && cito -o $@ $^

CLEAN = png2qoi$(EXEEXT) file-qoi$(EXEEXT) Xqoi.usr $(TRANSPILED) transpiled/QOI.h transpiled/QOI.hpp transpiled/QOIEncoder.java
clean:
	$(RM) $(CLEAN)

deb:
	debuild -b -us -uc

.PHONY: all install-gimp install-xnview clean deb

include win32/win32.mk
