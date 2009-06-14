# updatestate.py
#
# `updatestate' is a Mercurial extension which allows updating/overriding the dirstate for any specified file within the repo.
#
# To enable this extension:
#
#   [extensions]
#   updatestate = ...
# _or_
#   hgext.updatestate =
'''update/override working dirstate for specified file(s)'''

from mercurial import hg
#from mercurial import node
from mercurial import dirstate
import os

## FROM URLref: http://www.selenic.com/mercurial/wiki/WritingExtensions
# every command must take a ui and and repo as arguments.
# opts is a dict where you can find other command line flags
#
# Other parameters are taken in order from items on the command line that
# don't start with a dash.  If no default value is given in the parameter list,
# they are required.
#
# For experimenting with Mercurial in the python interpreter:
# Getting the repository of the current dir:
#    >>> from mercurial import hg, ui
#    >>> repo = hg.repository(ui.ui(), path = ".")

def printparents(ui, r, n, **opts):
    # The doc string below will show up in hg help
    """Print parent information"""

    # repo can be indexed based on tags, an sha1, or a revision number
    ctx = r.changectx(n)
    parents = ctx.parents()

    #if hg.islocal(r):
    #    ui.write("repo is LOCAL\n")
    #else:
    #    ui.write("repo is NON-LOCAL\n")

    if opts['long']:
        # the hex representation of a context returns the full sha1
        ui.write("long %s %s\n" % (node.hex(parents[0].node()), node.hex(parents[1].node())))
    else:
        # default == opts['short']
        ui.write("default %s %s\n" % (parents[0], parents[1]))


def update_dirstate(ui, r, *files):
    """Update specified FILE(s) in the working dirstate"""

    for f in files:
        #ui.warn( "IN FOR f in files loop\n" )
        #ui.warn( "os.sep = '%s'\n" % os.sep )
        #ui.warn( "f = '%s'\n" % f )
        f = os.path.normpath(f)
        #ui.warn( "NORMALIZED: f = '%s'\n" % f )
        ctx = r.changectx()
        if not ctx:
            raise hg.RepoError(_('no revision checked out'))
        man = ctx.manifest()
        man_files = man.keys()
        in_manifest = 0
        for mf in man_files:
            #ui.warn( "man_file: '%s'\n" % x )
            if f == os.path.normpath(mf):
                in_manifest = 1
                break
        if in_manifest and not man.linkf(mf):
            #ui.warn( "IN IF f in man_files ...\n" )
            #fp = r.file(f)
            #ui.warn( "GOT fp\n" )
            data = file(mf).read()
            #ui.warn( "GOT data\n" )
            r.wwrite(mf, data, man)
            #ui.warn( "writing\n" )
            r.dirstate.normal(mf)
            ui.write( "'%s' -- UPDATED and NORMALIZED in WORKING DIRSTATE\n" % f )
        r.dirstate.write()


cmdtable = {
    # cmd name        function call
    "print-parents": (printparents,
                     # see mercurial/fancyopts.py for all of the command flag options
                     [('s', 'short', None, 'print short form'),
                      ('l', 'long', None, 'print long form')],
                     "[options] REV"),
    "update-dirstate": (update_dirstate,
                     [],
                     "FILE ...")
}
