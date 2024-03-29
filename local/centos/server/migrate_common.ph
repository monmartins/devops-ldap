#
# $Id: migrate_common.ph,v 1.22 2003/04/15 03:09:33 lukeh Exp $
#
# Copyright (c) 1997-2003 Luke Howard.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#        This product includes software developed by Luke Howard.
# 4. The name of the other may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE LUKE HOWARD ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL LUKE HOWARD BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

#
# Common defines for MigrationTools
#

# Naming contexts. Key is $PROGRAM with migrate_ and .pl 
# stripped off. 
$NETINFOBRIDGE = (-x "/usr/sbin/mkslapdconf");

if ($NETINFOBRIDGE) {
        $NAMINGCONTEXT{'aliases'}           = "cn=aliases";
        $NAMINGCONTEXT{'fstab'}             = "cn=mounts";
        $NAMINGCONTEXT{'passwd'}            = "cn=users";
        $NAMINGCONTEXT{'netgroup_byuser'}   = "cn=netgroup.byuser";
        $NAMINGCONTEXT{'netgroup_byhost'}   = "cn=netgroup.byhost";
        $NAMINGCONTEXT{'group'}             = "cn=groups";
        $NAMINGCONTEXT{'netgroup'}          = "cn=netgroup";
        $NAMINGCONTEXT{'hosts'}             = "cn=machines";
        $NAMINGCONTEXT{'networks'}          = "cn=networks";
        $NAMINGCONTEXT{'protocols'}         = "cn=protocols";
        $NAMINGCONTEXT{'rpc'}               = "cn=rpcs";
        $NAMINGCONTEXT{'services'}          = "cn=services";
} else {
        $NAMINGCONTEXT{'aliases'}           = "ou=Aliases";
        $NAMINGCONTEXT{'fstab'}             = "ou=Mounts";
        $NAMINGCONTEXT{'passwd'}            = "ou=People";
        $NAMINGCONTEXT{'netgroup_byuser'}   = "nisMapName=netgroup.byuser";
        $NAMINGCONTEXT{'netgroup_byhost'}   = "nisMapName=netgroup.byhost";
        $NAMINGCONTEXT{'group'}             = "ou=Group";
        $NAMINGCONTEXT{'netgroup'}          = "ou=Netgroup";
        $NAMINGCONTEXT{'hosts'}             = "ou=Hosts";
        $NAMINGCONTEXT{'networks'}          = "ou=Networks";
        $NAMINGCONTEXT{'protocols'}         = "ou=Protocols";
        $NAMINGCONTEXT{'rpc'}               = "ou=Rpc";
        $NAMINGCONTEXT{'services'}          = "ou=Services";
}

# Default DNS domain
$DEFAULT_MAIL_DOMAIN = "techinterview.local";

# Default base 
$DEFAULT_BASE = "dc=techinterview,dc=local";

# Turn this on for inetLocalMailReceipient
# sendmail support; add the following to 
# sendmail.mc (thanks to Petr@Kristof.CZ):
##### CUT HERE #####
#define(`confLDAP_DEFAULT_SPEC',`-h "ldap.padl.com"')dnl
#LDAPROUTE_DOMAIN_FILE(`/etc/mail/ldapdomains')dnl
#FEATURE(ldap_routing)dnl
##### CUT HERE #####
# where /etc/mail/ldapdomains contains names of ldap_routed
# domains (similiar to MASQUERADE_DOMAIN_FILE).
# $DEFAULT_MAIL_HOST = "mail.padl.com";

# turn this on to support more general object clases
# such as person.
$EXTENDED_SCHEMA = 1;

#
# allow environment variables to override predefines
#
if (defined($ENV{'LDAP_BASEDN'})) {
        $DEFAULT_BASE = $ENV{'LDAP_BASEDN'};
}

if (defined($ENV{'LDAP_DEFAULT_MAIL_DOMAIN'})) {
        $DEFAULT_MAIL_DOMAIN = $ENV{'LDAP_DEFAULT_MAIL_DOMAIN'};
}

if (defined($ENV{'LDAP_DEFAULT_MAIL_HOST'})) {
        $DEFAULT_MAIL_HOST = $ENV{'LDAP_DEFAULT_MAIL_HOST'};
}

# binddn used for alias owner (otherwise uid=root,...)
if (defined($ENV{'LDAP_BINDDN'})) {
        $DEFAULT_OWNER = $ENV{'LDAP_BINDDN'};
}

if (defined($ENV{'LDAP_EXTENDED_SCHEMA'})) {
        $EXTENDED_SCHEMA = $ENV{'LDAP_EXTENDED_SCHEMA'};
}

# If we haven't set the default base, guess it automagically.
if (!defined($DEFAULT_BASE)) {
        $DEFAULT_BASE = &domain_expand($DEFAULT_MAIL_DOMAIN);
        $DEFAULT_BASE =~ s/,$//o;
}

# Default Kerberos realm
#if ($EXTENDED_SCHEMA) {
#       $DEFAULT_REALM = $DEFAULT_MAIL_DOMAIN;
#       $DEFAULT_REALM =~ tr/a-z/A-Z/;
#}

if (-x "/usr/sbin/revnetgroup") {
        $REVNETGROUP = "/usr/sbin/revnetgroup";
} elsif (-x "/usr/lib/yp/revnetgroup") {
        $REVNETGROUP = "/usr/lib/yp/revnetgroup";
}

$classmap{'o'} = 'organization';
$classmap{'dc'} = 'domain';
$classmap{'l'} = 'locality';
$classmap{'ou'} = 'organizationalUnit';
$classmap{'c'} = 'country';
$classmap{'nismapname'} = 'nisMap';
$classmap{'cn'} = 'container';

sub parse_args
{
        if ($#ARGV < 0) {
                print STDERR "Usage: $PROGRAM infile [outfile]\n";
                exit 1;
        }

        $INFILE = $ARGV[0];

        if ($#ARGV > 0) {
                $OUTFILE = $ARGV[1];
        }
}

sub open_files
{
        open(INFILE);
        if ($OUTFILE) {
                open(OUTFILE,">$OUTFILE");
                $use_stdout = 0;
        } else {
                $use_stdout = 1;
        }
}

# moved from migrate_hosts.pl
# lukeh 10/30/97
sub domain_expand
{
        local($first) = 1;
        local($dn);
        local(@namecomponents) = split(/\./, $_[0]);
        foreach $_ (@namecomponents) {
                $first = 0;
                $dn .= "dc=$_,";
        }
        $dn .= $DEFAULT_BASE;
        return $dn;
}

# case insensitive unique
sub uniq
{
        local($name) = shift(@_);
        local(@vec) = sort {uc($a) cmp uc($b)} @_;
        local(@ret);
        local($next, $last);
        foreach $next (@vec) {
                if ((uc($next) ne uc($last)) &&
                        (uc($next) ne uc($name))) {
                        push (@ret, $next);
                }
                $last = $next;
        }
        return @ret;
}

# concatenate naming context and 
# organizational base
sub getsuffix
{
        local($program) = shift(@_);
        local($nc);
        $program =~ s/^migrate_(.*)\.pl$/$1/;
        $nc = $NAMINGCONTEXT{$program};
        if ($nc eq "") {
                return $DEFAULT_BASE;
        } else {
                return $nc . ',' . $DEFAULT_BASE;
        }
}

sub ldif_entry
{
# remove leading, trailing whitespace
        local ($HANDLE, $lhs, $rhs) = @_;
        local ($type, $val) = split(/\=/, $lhs);
        local ($dn);

        if ($rhs ne "") {
                $dn = $lhs . ',' . $rhs;
        } else {
                $dn = $lhs;
        }

        $type =~ s/\s*$//o;
        $type =~ s/^\s*//o;
        $type =~ tr/A-Z/a-z/;
        $val =~ s/\s*$//o;
        $val =~ s/^\s*//o;

        print $HANDLE "dn: $dn\n";
        print $HANDLE "$type: $val\n";
        print $HANDLE "objectClass: top\n";
        print $HANDLE "objectClass: $classmap{$type}\n";
        if ($EXTENDED_SCHEMA) {
                if ($DEFAULT_MAIL_DOMAIN) {
                        print $HANDLE "objectClass: domainRelatedObject\n";
                        print $HANDLE "associatedDomain: $DEFAULT_MAIL_DOMAIN\n";
                }
        }

        print $HANDLE "\n";
}

# Added Thu Jun 20 16:40:28 CDT 2002 by Bob Apthorpe
# <apthorpe@cynistar.net> to solve problems with embedded plusses in
# protocols and mail aliases.
sub escape_metacharacters
{
        local($name) = @_;

        # From Table 3.1 "Characters Requiring Quoting When Contained
        # in Distinguished Names", p87 "Understanding and Deploying LDAP
        # Directory Services", Howes, Smith, & Good.

        # 1) Quote backslash
        # Note: none of these are very elegant or robust and may cause
        # more trouble than they're worth. That's why they're disabled.
        # 1.a) naive (escape all backslashes)
        # $name =~ s#\\#\\\\#og;
        #
        # 1.b) mostly naive (escape all backslashes not followed by
        # a backslash)
        # $name =~ s#\\(?!\\)#\\\\#og;
        #
        # 1.c) less naive and utterly gruesome (replace solitary
        # backslashes)
        # $name =~ s{           # Replace
        #               (?<!\\) # negative lookbehind (no preceding backslash)
        #               \\      # a single backslash
        #               (?!\\)  # negative lookahead (no following backslash)
        #       }
        #       {               # With
        #               \\\\    # a pair of backslashes
        #       }gx;
        # Ugh. Note that s#(?:[^\\])\\(?:[^\\])#////#g fails if $name
        # starts or ends with a backslash. This expression won't work
        # under perl4 because the /x flag and negative lookahead and
        # lookbehind operations aren't supported. Sorry. Also note that
        # s#(?:[^\\]*)\\(?:[^\\]*)#////#g won't work either.  Of course,
        # this is all broken if $name is already escaped before we get
        # to it. Best to throw a warning and make the user import these
        # records by hand.

        # 2) Quote leading and trailing spaces
        local($leader, $body, $trailer) = ();
        if (($leader, $body, $trailer) = ($name =~ m#^( *)(.*\S)( *)$#o)) {
                $leader =~ s# #\\ #og;
                $trailer =~ s# #\\ #og;
                $name = $leader . $body . $trailer;
        }

        # 3) Quote leading octothorpe (#)
        $name =~ s/^#/\\#/o;

        # 4) Quote comma, plus, double-quote, less-than, greater-than,
        # and semicolon
        $name =~ s#([,+"<>;])#\\$1#g;

        return $name;
}

1;