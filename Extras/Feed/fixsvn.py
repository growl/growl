#!/usr/bin/python

import sys
import os

def spawnc(cmd, *args):
    rv = os.spawnl(os.P_WAIT, cmd, os.path.basename(cmd), *args)
    if rv != 0:
        raise OSError, 'failed: %s (%d)' % (' '.join((cmd,) + args), rv)

def move(oldpath, newdir):
    # print 'mv', oldpath, os.path.join(newdir, os.path.basename(oldpath))
    os.rename(oldpath, os.path.join(newdir, os.path.basename(oldpath)))

def rename(oldpath, newname):
    # print 'mv', oldpath, os.path.join(os.path.dirname(oldpath), newname)
    os.rename(oldpath, os.path.join(os.path.dirname(oldpath), newname))

def rm_rf(dir):
    # print 'rm -rf', dir
    spawnc('/bin/rm', '-rf', dir)

def svn_cleanup(dir):
    # print 'svn cleanup', dir
    spawnc('/usr/local/bin/svn', 'cleanup', dir)

def svn_up(dir):
    # print 'svn up', dir
    spawnc('/usr/local/bin/svn', 'up', dir)

def ditto(src, dst):
    # print 'mkdir', dst
    os.mkdir(dst)
    # print 'ditto -rsrc', src, dst
    spawnc('/usr/bin/ditto', '-rsrc', src, dst)
    
for dir in sys.argv[1:]:
    print 'processing', dir
    if not os.path.exists(dir):
        print 'nonexistent:', dir
        continue
    if not os.path.isdir(dir):
        print 'not a directory:', dir
        continue
    new = dir + '.new'
    # first, move the directory out of the way
    rename(dir, new)
    # clean up the parent first, considering an operation may have failed
    svn_cleanup(os.path.dirname(dir))
    # then, restore with old information
    svn_up(dir)
    # remove the old .svn directory or any fragments if they exist
    rm_rf(os.path.join(new, '.svn'))
    # move the restored .svn directory to the new directory
    move(os.path.join(dir, '.svn'), new)
    # remove the old directory
    rm_rf(dir)
    # move the directory back
    rename(new, dir)


