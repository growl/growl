from distutils.core import setup
from distutils.command.install_scripts import install_scripts
import os
from distutils import log
from stat import ST_MODE

class appleLocalInstallWorkAround(install_scripts):
    # BAD BAD But this works :)
    def run (self):
        hold_dir = self.install_dir
        self.install_dir = "/usr/local/bin"
        r = install_scripts.run(self)
        self.install_dir = hold_dir
        return r

setup(name="Growl",
      version="0.0.1",
      description="Python bindings for posting notifications to the Growl daemon",
      author="Mark Rowe",
      author_email="bdash@users.sourceforge.net",
      url="http://Growl.info",
      scripts=["bin/gnotify"],
      cmdclass={'install_scripts':appleLocalInstallWorkAround},
      py_modules=["Growl"])

