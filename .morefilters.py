# morefilters.py - morefilters
# $Id$
# $Version$
#
# [ based on interhg.py ]
#
# The `morefilters' Mercurial extension allows you to transform any text with a regular expression and returns the most recent version form tag for each revision.
#
# To enable this extension:
#
#   [extensions]
#   morefilters =
# _or_
#   hgext.morefilters =
#
# This is an example to link to a bug tracking system.
#
#   [morefilters]
#   re_escape_1 = s/issue(\d+)/ <a href="http:\/\/bts\/issue\1">issue\1<\/a> /
#
# You can add patterns to use re_escape_2, re_escape_3, ...
# For example:
#
#   re_escape_2 = s/(^|\s)#(\d+)\b/ <b>#\2<\/b> /
'''expanded keyword filters'''

import re, time
#from mercurial.hgweb import hgweb_mod
from mercurial import node, util
#from mercurial import ui, localrepo
#from node import *
#import binascii
from datetime import datetime, timedelta, tzinfo


# import keyword.expand (if present) for update hook
try:
    from hgext import keyword
    morefilters_kwexpand = keyword.expand
except ImportError:
    morefilters_kwexpand = None

# import template filter collection
try:
    # v1.2.1+
    from mercurial import templatefilters
    morefilters_filters = templatefilters.filters
except ImportError:
    # v0.9.4
    from mercurial import templater
    morefilters_filters = templater.common_filters


config_section = 'morefilters'

morefilters_table = []
morefilters_ui = None
morefilters_repo = None
morefilters_update_destination_parent = None

def reposetup(ui, repo):
    global morefilters_ui
    global morefilters_repo
    morefilters_ui = ui
    morefilters_repo = repo
    #ui.warn('got here')

def filters_re_escape(x):
    #morefilters_table[:] = []
    if len(morefilters_table) == 0 :    # assume that there is at least one pattern in the config file for processing (o/w we read it everytime)
        u = morefilters_ui
        num = 1
        while True:
            key = 're_escape_%d' % num
            pat = u.config(config_section, key, None)
            if pat == None:
                break
            pat = pat[2:-1]
            span = re.search(r'[^\\]/', pat).span()
            regexp = pat[:span[0] + 1]
            format = pat[span[1]:]
            format = re.sub(r'\\/', '/', format)
            regexp = re.compile(regexp)
            morefilters_table.append((regexp, format))
            num += 1
    escstr = x
    #escstr = ( "%d" % len(morefilters_table)) + '+' + escstr
    for pat in morefilters_table:
        regexp = pat[0]
        format = pat[1]
        escstr = regexp.sub(format, escstr)
    return escstr

# Notes:
# version is defined as <major>.<minor>.<release>.<build> (all sections are a single number except <build> which may have several dotted sections)
# Version is constructed based on the last _commited revision_.
# [TODO] version tags regexp is "[vV](?:\d+(?:\.\d+)*)|(?:\d+(?:\.\d+)+)" (aka, v is optional and of any case & version tag has a leading v _or_ at least two version numbers seperated by periods). Note: single non-V-prefix, non-dotted numbers are NOT a version strings (must use at least a prefix V or have at least two dotted sections, i.e. v1, 1.0, or v1.0).
#   * this is to allow for bug id tags as well (which are generally just generic numeric ids)
# _net == .NET version pattern
# _dated == human readable .NET version pattern (<date> is in YYYYMMDD format is substituted for <daysFromNETEpoch>)
# _vtdiff == <major>.<minor>.<release>.<secsFromLastVersionTag>
# _extended == [if version tag is just <major>.<minor> => <major>.<minor>.<date[as YYYYMMDD]>.<secsFromMidnite>; else => <major>.<minor>.<release>[.<x>].<secsFromVersionTagCommit> ]
# generally, check for enough version parts in any version tag (adding '.0's as needed to flesh out the version, but never cut down a version tag. Then append to that version tag as needed per function.

def _get_revnumber( n ):
    # n = node id (binary)
    l  = morefilters_repo   # local repository
    try:
        this_rev = l.changelog.rev(n)     # revision # of current revision {revision numbers are valid only for local repository}, range=[ 0 .. ]
    except:
        this_rev = -1   # beginning of the list (prior to initial revision [rev 0]) if unknown node id
    return this_rev

def _get_vtag( rev ):
    # rev = local revision number
    ui = morefilters_ui     # ui
    l  = morefilters_repo   # local repository

    v_ver   = '0.0'

    tags = l.tagslist()     # tags[] == [ {[0] == tag text, [1] == tagged revision id (binary)}, ... ], in revision order
    tags.reverse()          # most recent revisions first
    #ui.warn( "%s\n" % len(tags) )
    if len(tags) > 0:
        #ui.warn ( "====<tags>\n")
        i = 0
        re_prog = re.compile( r'(?i)^\s*v?\s*\d+(?:\.\d+)*\s*$' )
        for tag in tags:
            # find first version tag which is equal or older than current revision
            #(manifest, user, (time, timezone), files, desc, extra) = l.changelog.read(tag[1])
            (manifest, user, date, files, desc, extra) = l.changelog.read(tag[1])
            try:
                r = l.changelog.rev(tag[1])
            except:
                r = -2  # sort to the beginning of the list (prior to any unknown this_rev) if unknown node id (from tag[1])
            #ui.warn ( "[%s]\n" % i )
            #ui.warn ( "screv:    %s\n" % r )
            #ui.warn ( "tag[0]:   %s\n" % tag[0] )
            #ui.warn ( "manifest: %s\n" % node.hex(manifest) )
            #ui.warn ( "user:     %s\n" % user )
            #ui.warn ( "date:     %s\n" % util.datestr(date, format='%Y-%m-%d %H:%M:%S') )
            #ui.warn ( "==\n" )
            i = i + 1
            v_match = re_prog.match( tag[0] )
            if ( v_match and ( rev >= r ) ):
                v_ver = v_match.group(0)
                v_ver = re.sub( r'\s*', '', v_ver )     # remove all whitespace
                v_ver = re.sub( r'(?i)^v', '', v_ver )  # remove any leading 'v'
                break
    return (v_ver, tag[1])

def _version_net( n ):
    # .NET version style "<version='major.minor'>.<daysFromNETEpoch>.<secsFromMidnite/2>" (.NET epoch = Feb 1, 2000 [ from Essential .NET, Volume 1, Page 24, by Chris Sells])
    # ## see URLs: http://www.shahine.com/omar/AssemblyVersionBuildAndRevisionNumber.aspx, http://groups.google.com/group/microsoft.public.windows.file_system/msg/8702261793ca568d?q=AssemblyVersion+default&hl=en&lr=&ie=UTF-8&oe=UTF-8&rnum=1, http://msdn2.microsoft.com/en-us/library/system.reflection.assemblyversionattribute(VS.71).aspx ]
    # n == node id (binary)
    l = morefilters_repo    # local repository

    n = l.lookup(n)   # convert to full id

    this_rev = _get_revnumber(n)

    v_daysFNE  = '<no-days>'
    v_secsFM2  = '<no-secs>'

    date_NETepoch = datetime( 2000, 2, 1 )

    v_ver = _get_vtag( this_rev )[0]

    # check for partial version strings and pad with following '0's as needed
    v_ = v_ver.split('.')                               # split version string into sections (divided by '.')
    v_minlength = 2                                     # minimum number of version sections (eg, 2 == <major>.<minor>; 3 == <major>.<minor>.<release>, at a minimum)
    v_[len(v_):] = [ '0' ] * (v_minlength - len(v_))    # expand to minimum number of version sections

    #(manifest, user, date=(time, timezone), files, desc, extra) = l.changelog.read( node_id )
    n_time = l.changelog.read(n)[2][0]
    h = time.strftime( '%H', time.gmtime(n_time))    # most recent revision hour (UTC)
    m = time.strftime( '%M', time.gmtime(n_time))    # most recent revision minute (UTC)
    s = time.strftime( '%S', time.gmtime(n_time))    # most recent revision second (UTC)

    t_delta = datetime.utcfromtimestamp(n_time) - date_NETepoch
    v_daysFNE = "%s" % t_delta.days
    v_secsFM2 = "%s" % (int( (int(h) * 3600 + int(m) * 60 + int(s)) / 2 ))

    v_.append( v_daysFNE )
    v_.append( v_secsFM2 )

    v_ver = '.'.join( v_[:3] )      # recreate version string from sections
    v_build = '.'.join( v_[3:] )    # create build string from sections

#    return (v_ver, v_date, "%s" % v_build, "%s" % node.hex(n))
    return (v_ver, v_build, "%s" % node.hex(n))

def _version_vtdiff( n ):
    # 'vtdiff' version style "<version='major.minor.release'>.<secsFromLastVersionTag>"
    # n == node id (binary)
    l = morefilters_repo    # local repository

    n = l.lookup(n)   # convert to full id

    this_rev = _get_revnumber(n)

    v_daysFNE  = '<no-days>'
    v_secsFM2  = '<no-secs>'

    (v_ver, v_ver_n) = _get_vtag( this_rev )

    v_ver_date = datetime.utcfromtimestamp(l.changelog.read(v_ver_n)[2][0])

    # check for partial version strings and pad with following '0's as needed
    v_ = v_ver.split('.')                               # split version string into sections (divided by '.')
    v_minlength = 3                                     # minimum number of version sections (eg, 2 == <major>.<minor>; 3 == <major>.<minor>.<release>, at a minimum)
    v_[len(v_):] = [ '0' ] * (v_minlength - len(v_))    # expand to minimum number of version sections

    #(manifest, user, date=(time, timezone), files, desc, extra) = l.changelog.read( node_id )
    n_time = l.changelog.read(n)[2][0]

    t_delta = datetime.utcfromtimestamp(n_time) - v_ver_date
    v_secsFLVT = "%s" % (t_delta.days * 24*60*60 + t_delta.seconds )

    v_.append( v_secsFLVT )

    v_ver = '.'.join( v_[:3] )      # recreate version string from sections
    v_build = '.'.join( v_[3:] )    # create build string from sections

#    return (v_ver, v_date, "%s" % v_build, "%s" % node.hex(n))
    return (v_ver, v_build, "%s" % node.hex(n))

def _version_dated(n):
    # 'dated' version style "<version='x.y'>.<date>.<secsFromMidnite>"
    # Note: <date> is in YYYYmmdd format
    u = morefilters_ui
    l = morefilters_repo

    v_date   = '<no-date>'
    v_secsFM = '<no-secs>'
    #v_build = '<no-build>'

    n = l.lookup(n)   # convert to full id

    this_rev = _get_revnumber(n)

    v_ver = _get_vtag( this_rev )[0]

    # check for partial version strings and pad with following '0's as needed
    v_ = v_ver.split('.')                               # split version string into sections (divided by '.')
    v_minlength = 2                                     # minimum number of version sections (eg, 2 == <major>.<minor>; 3 == <major>.<minor>.<release>, at a minimum)
    v_[len(v_):] = [ '0' ] * (v_minlength - len(v_))    # expand to minimum number of version sections

    #(manifest, user, date=(time, timezone), files, desc, extra) = l.changelog.read( node_id )
    n_time = l.changelog.read(n)[2][0]
    v_date = time.strftime( '%Y%m%d', time.gmtime(n_time)) # most recent revision date (UTC) as "YYYYMMDD"
    h = time.strftime( '%H', time.gmtime(n_time))          # most recent revision hour (UTC)
    m = time.strftime( '%M', time.gmtime(n_time))          # most recent revision minute (UTC)
    s = time.strftime( '%S', time.gmtime(n_time))          # most recent revision second (UTC)
    v_secsFM = "%s" % (int( int(h) * 3600 + int(m) * 60 + int(s) ))

    #if (len(v_) < 3):
    #    v_.append( vdate )
    #    v_.append( "%05s" % int(v_secsFM) )
    #else:
    #    v_.append( vdate + v_secsFM )

    v_.append( v_date )
    v_.append( v_secsFM )

    v_ver = '.'.join( v_[:3] )      # recreate version string from sections
    v_build = '.'.join( v_[3:] )    # create build string from sections

    return (v_ver, v_build, "%s" % node.hex(n))

def _version_dated_compressed(n):
    # 'dated_compressed' version style "<version='x.y.z[...]'>.<date&secsFromMidnite>"
    # Note: <date&secsFromMidnight> is in YYYYmmddsssss format
    u = morefilters_ui
    l = morefilters_repo

    v_date   = '<no-date>'
    v_secsFM = '<no-secs>'
    #v_build = '<no-build>'

    n = l.lookup(n)   # convert to full id

    this_rev = _get_revnumber(n)

    v_ver = _get_vtag( this_rev )[0]

    # check for partial version strings and pad with following '0's as needed
    v_ = v_ver.split('.')                               # split version string into sections (divided by '.')
    v_minlength = 3                                     # minimum number of version sections (eg, 2 == <major>.<minor>; 3 == <major>.<minor>.<release>, at a minimum)
    v_[len(v_):] = [ '0' ] * (v_minlength - len(v_))    # expand to minimum number of version sections

    #(manifest, user, date=(time, timezone), files, desc, extra) = l.changelog.read( node_id )
    n_time = l.changelog.read(n)[2][0]
    v_date = time.strftime( '%Y%m%d', time.gmtime(n_time)) # most recent revision date (UTC) as "YYYYMMDD"
    h = time.strftime( '%H', time.gmtime(n_time))          # most recent revision hour (UTC)
    m = time.strftime( '%M', time.gmtime(n_time))          # most recent revision minute (UTC)
    s = time.strftime( '%S', time.gmtime(n_time))          # most recent revision second (UTC)
    v_secsFM = "%s" % (int( int(h) * 3600 + int(m) * 60 + int(s) ))

    v_.append( v_date + "%05u" % int(v_secsFM) )

    v_ver = '.'.join( v_[:3] )      # recreate version string from sections
    v_build = '.'.join( v_[3:] )    # create build string from sections

    return (v_ver, v_build, "%s" % node.hex(n))

def _version_extended(n):
    # _extended == [if version tag is just <major>.<minor> => <major>.<minor>.<date[as YYYYMMDD]>.<secsFromMidnite>; else => <major>.<minor>.<release>[.<x>].<secsFromVersionTagCommit> ]
    # [ALTERNATIVELY...]'extended' version style "<version='x.y.z'>.<date&secsFromMidnite>" (<date&secsFromMidnight> is in YYYYmmddsssss format ); note: secsFromMidnight must be 5 characters long with leading '0's to sort correctly; the last section of the final version string (<date&secsFromMidnite>) is up to 48-bits long and will _not_ fit into a long (32-bit) integer
    u = morefilters_ui
    l = morefilters_repo

    v_ver   = '0.0.0'
    v_date  = '<no-date>'
    v_sfm   = '<no-secsFromMidnite>'
    v_build = '<no-build>'

    #n = node.hex(l.lookup(n))   # convert to full id (as hexadecimal string)
    n = l.lookup(n)   # convert to full id

    try:
        this_rev = l.changelog.rev(n)     # revision # of current revision {revision numbers are valid only for local repository}
    except:
        this_rev = -1 # beginning of the list if unknown

#    v_date = util.datestr( l.changelog.read(n)[2], format='%Y%m%d', timezone=False)  # most recent revision date (local time)
#    h = util.datestr( l.changelog.read(n)[2], format='%H', timezone=False)
#    m = util.datestr( l.changelog.read(n)[2], format='%M', timezone=False)
#    s = util.datestr( l.changelog.read(n)[2], format='%S', timezone=False)
    v_date = time.strftime( '%Y%m%d', time.gmtime(l.changelog.read(n)[2][0]))   # most recent revision date (UTC) as "YYYYMMDD"
    h = time.strftime( '%H', time.gmtime(l.changelog.read(n)[2][0]))            # most recent revision hour (UTC)
    m = time.strftime( '%M', time.gmtime(l.changelog.read(n)[2][0]))            # most recent revision minute (UTC)
    s = time.strftime( '%S', time.gmtime(l.changelog.read(n)[2][0]))            # most recent revision second (UTC)
    v_sfm = int(h) * 3600 + int(m) * 60 + int(s)
    v_build = v_date + "%05u" % (v_sfm)

    tags = l.tagslist()     # tags[] == [ {[0] == tag text, [1] == tagged revision id (binary)}, ... ], in revision order
    tags.reverse()          # most recent revisions first
    #u.warn( "%s\n" % len(tags) )
    if len(tags) > 0:
        #u.warn ( "vdate:   %s\n" % v_date )
        #u.warn ( "H:      %s\n" % h )
        #u.warn ( "M:      %s\n" % m )
        #u.warn ( "S:      %s\n" % s )
        #u.warn ( "H*3600: %s\n" % (int(h) * 3600) )
        #u.warn ( "====<tags>\n")
        i = 0
        re_prog = re.compile('v?(\\d+(?:\\.\\d+)*)', re.I)
        for tag in tags:
            # find first version tag which is equal or older than current revision
            #(manifest, user, (time, timezone), files, desc, extra) = l.changelog.read(tag[1])
            (manifest, user, date, files, desc, extra) = l.changelog.read(tag[1])
            try:
                r = l.changelog.rev(tag[1])
            except:
                r = -2 # sort to the beginning of the list if unknown
            #u.warn ( "[%s]\n" % i )
            #u.warn ( "screv #:  %s\n" % r )
            #u.warn ( "screv id: %s\n" % node.hex(tag[1]) )  # tag[1] == tagged revision id (binary)
            #u.warn ( "tag[0]:   %s\n" % tag[0] )            # tag[0] == tag text
            #u.warn ( "manifest: %s\n" % node.hex(manifest) )
            #u.warn ( "user:     %s\n" % user )
            #u.warn ( "date:     %s\n" % util.datestr(date, format='%Y-%m-%d %H:%M:%S') )
            #u.warn ( "==\n" )
            i = i + 1
            v_match = re_prog.match( tag[0] )
            if ( v_match and ( this_rev >= r ) ):
                v_ver = v_match.group(1)
                break
    #u.warn("====\n")
    u.warn ( "n:        %s\n" % node.hex(n) )
    u.warn ( "screv(n): %s\n" % this_rev )
    u.warn ( "v_ver:    %s\n" % v_ver )
    u.warn ( "v_date:   %s\n" % v_date )
    u.warn ( "v_build:  %s\n" % v_build )
    #u.warn("====\n")

    #v_str = 'v' + v_ver + '.' + v_date + "%s" % v_build + " (screv %s)" % this_rev
    v = v_ver.split('.')
    return (v_ver, v_build, "%s" % node.hex(n))

def _version(n):
    # returns (version, build, revision_id)
    return _version_net(n)

def filters_version_net(n):
    return "%s.%s" % _version_net(n)[0:2]

def filters_version_dated(n):
    return "%s.%s" % _version_dated(n)[0:2]

def filters_version_dated_compressed(n):
    return "%s.%s" % _version_dated_compressed(n)[0:2]

def filters_version_vtdiff(n):
    return "%s.%s" % _version_vtdiff(n)[0:2]

def filters_version_full(n):
    v = _version(n)
#    return "%s.%s (rfp %s)" % ('.'.join( v[:-2] ), v[-2], v[-1])
    return "%s.%s (rfp %s)" % v

def filters_version(n):
    v = _version(n)
#    return "%s.%s.%s" % (v[0], v[1], v[2])
#    return "%s.%s" % ('.'.join( v[:-2] ), v[-2])
    return "%s.%s" % v[0:2]

def filters_utcdate(date):
    '''Returns hgdate in cvs-like UTC format. [from keywords.py]'''
    return time.strftime('%Y/%m/%d %H:%M:%S UTC', time.gmtime(date[0]))

def filters_minidate(date):
    # compact date format (no seconds) [UTC]
    #return util.datestr(date, '%Y/%m/%d:%H:%M:%S')
    return time.strftime('%Y/%m/%d:%H:%M', time.gmtime(date[0]))

def _v_major(v):
    # v == <major>.<minor>.<release>.<build (may be multiple dotted parts)>
    # returns ( major version )
    ver = v.split('.')
    return ver[0]

def _v_minor(v):
    # v == <major>.<minor>.<release>.<build (may be multiple dotted parts)>
    # returns ( minor version )
    ver = v.split('.')
    return ver[1]

def _v_release(v):
    # v == <major>.<minor>.<release>.<build (may be multiple dotted parts)>
    # returns ( release )
    ver = v.split('.')
    return ver[2]

def _v_build(v):
    # v == <major>.<minor>.<release>.<build (may be multiple dotted parts)>
    # returns ( build )
    ver = v.split('.')
    return '.'.join( ver[3:] )

def _v_mm(v):
    # v == <major>.<minor>.<release>.<build (may be multiple dotted parts)>
    # returns ( major.minor version )
    ver = v.split('.')
    return '.'.join( ver[:2] )      # ver[0].ver[1]

def _v_mmr(v):
    # v == <major>.<minor>.<release>.<build (may be multiple dotted parts)>
    # returns ( major.minor.release )
    ver = v.split('.')
    return '.'.join( ver[:3] )      # ver[0].ver[1].ver[2]

# TODO: change 'working' to 'node_working' taking no argument (used as primary token), ? is this possible or does it have to be a 'filter' taking an argument even though it doesn't need one
# TODO: note rationale for using/needing working == has to do with correct versioning of file at a given node level
def filters_working(n):
    # node filter
    # note: working directory will lag on updates (being source/original working revision id instead of the final/destination revision id) when using "hg update ..." ; not sure how to fix that?
    # * FIXED: using preupdate and update hooks to set the destination parent id
    # [2009-05-25] * BETTER FIX: use post-update hook to run expand (removes the save parent process using a pre-update hook, etc)
    ## ignores input node
    ## TODO: ?follow both parents if present
    #u = morefilters_ui
    n_new = morefilters_update_destination_parent
    #u.warn ( "m:working:morefilters_update_destination_parent:   %s\n" % morefilters_update_destination_parent )
    #u.warn ( "m:working:n_new:   %s\n" % n_new )
    l = morefilters_repo
    if n_new == None:
        ctx = l.workingctx()
        parents = ctx.parents()
        n_new = node.hex(parents[0].node())
    n_new = node.hex(l.lookup(n_new))   # expand to full length hex id
#
    #u.warn ( "m:working:n_new(update):   %s\n" % n_new )
    #u.warn ( "m:working:lookup'.':   %s\n" % node.hex(l.lookup(".")) )
    #if ( morefilters_update_destination_parent != None):
    #    ctx = l.changectx(l.lookup(morefilters_update_destination_parent))
    #    parents = ctx.parents()
    #    #u.warn ( "m:working:lookup'm_u_p':   %s\n" % node.hex(parents[0].node()) )
    return "%s" % n_new


# add filters to template filters collection
morefilters_filters["re_escape"] = filters_re_escape
morefilters_filters["version"] = filters_version
morefilters_filters["version_full"] = filters_version_full
#
morefilters_filters["version_net"] = filters_version_net
morefilters_filters["version_dated"] = filters_version_dated
morefilters_filters["version_dated_compressed"] = filters_version_dated_compressed
morefilters_filters["version_vtdiff"] = filters_version_vtdiff
#
morefilters_filters["v_major"] = _v_major
morefilters_filters["v_minor"] = _v_minor
morefilters_filters["v_release"] = _v_release
morefilters_filters["v_build"] = _v_build
morefilters_filters["v_mm"] = _v_mm
morefilters_filters["v_mmr"] = _v_mmr
#
#morefilters_filters["utcdate"] = filters_utcdate
morefilters_filters["minidate"] = filters_minidate
morefilters_filters["working"] = filters_working

## hook for updates (to prevent 'working' filter lag for keyword expansion when using update)
##def hook(ui, repo, hooktype, node=None, source=None, **kwargs):
#def hook_preupdate(ui, repo, hooktype, **kwargs):
#    global morefilters_update_destination_parent
#    if hooktype != 'preupdate':
#        raise util.Abort(_('config error - hook type "%s" cannot stop '
#                           'incoming changesets') % hooktype)
#    morefilters_update_destination_parent = kwargs["parent1"]
#    #u = morefilters_ui
#    #u.warn ( "m:preupdate:parent1:   %s\n" % kwargs["parent1"] )
#    #u.warn ( "m:preupdate:parent2:   %s\n" % kwargs["parent2"] )
#    #u.warn ( "m:preupdate:morefilters_update_destination_parent:   %s\n" % morefilters_update_destination_parent )
#
#def hook_update(ui, repo, hooktype, **kwargs):
#    # hook update to keep 'working' filter current during an update (note: this is _only_ needed to correctly expand keywords during a repository update)
#    global morefilters_update_destination_parent
#    if hooktype != 'update':
#        raise util.Abort(_('config error - hook type "%s" cannot stop '
#                           'incoming changesets') % hooktype)
#    #u = morefilters_ui
#    #u.warn ( "m:update:nulling\n" )
#    #u.warn ( "m:preupdate:morefilters_update_destination_parent:   %s\n" % morefilters_update_destination_parent )
#
#    # kwexpand full repository to update any dangling keywords (such as $Version$)
#    ## Note: this can kill repository efficiency if too many files are checked for keyword expansion (as all files marked for expansion will be checked with every update)
#    ## * generally, to preserve normal efficiency, enable keyword expansion (and this hook) only in specific repositories with specific (small population) target files using '.hg/hgrc'.
#    if ( morefilters_kwexpand != None ):
#            morefilters_kwexpand( ui, repo )
#    morefilters_update_destination_parent = None

# hook for updates (to prevent 'working' filter lag for keyword expansion when using update)
# [use hgrc post-commit and post-update to engage expansion]
def expand(ui, repo, hooktype, **args):
    #ui.warn ( "morefilters.expanding [using keyword.expand]" )
    #keyword.expand ( ui, repo )
    if ( morefilters_kwexpand != None ):
            morefilters_kwexpand( ui, repo )
    #pass
