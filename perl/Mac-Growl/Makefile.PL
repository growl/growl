use 5.008001;
use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mac::Growl',
    VERSION_FROM      => 'lib/Mac/Growl.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mac/Growl.pm', # retrieve abstract from module
       AUTHOR         => 'Nelson Elhage <nelhage@gmail.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
	LDDLFLAGS         => $Config{lddlflags} . " -framework CoreFoundation", #Link Core Foundation framework
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
