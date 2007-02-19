DESTDIR=$HOME/Library/Widgets/Growl.wdgt

all:
	make -C GrowlWidgetPlugin all

install:
	rm -rfd $(DESTDIR)
	mkdir -p $(DESTDIR)
	cp -f *.png GrowlWidget.* *.plist $(DESTDIR)
	cp -R GrowlWidgetPlugin/build/Deployment/GrowlWidgetPlugin.widgetplugin $(DESTDIR)
	/Developer/Tools/SetFile -a E $(DESTDIR)

clean:
	make -C GrowlWidgetPlugin clean
