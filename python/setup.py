from distutils.core import setup
setup(name="Growl",
      version="0.0.1",
      description="Python bindings for posting notifications to the Growl daemon",
      author="Mark Rowe",
      author_email="bdash@users.sourceforge.net",
      url="http://Growl.info",
      scripts=["bin/gnotify"],
      py_modules=["Growl"])

