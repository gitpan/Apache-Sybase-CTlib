package Apache::Sybase::CTlib;

use strict;
use Apache ();
use Apache::Log ();
use Sybase::CTlib;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '1.01';

my(%Connected);
my @ChildConnect;
my $r=shift;
 
sub connect_on_init { push @ChildConnect, [@_] }
if(Apache->can_stack_handlers) {
   Apache->push_handlers(PerlChildInitHandler => sub {
      for my $aref (@ChildConnect) {
         shift @$aref;
         Apache::Sybase::CTlib->connect(@$aref);
      }
   });
}
 
sub connect {
   my($self, @args) = @_;
   my($uid, $pwd, $srv) = @args;
   my $idx = join ":", (@args) || (@{$self});
   return $Connected{$idx} if $Connected{$idx};
   $Connected{$idx} = Sybase::CTlib->ct_connect($uid, $pwd, $srv);
   return undef if ! $Connected{$idx};
   if ($Connected{$idx}) {
      Apache->server->log->notice("Starting database connection to $srv");
   }
   else {
      Apache->server->log->error("Failed connection to $srv");
   }
}
 
sub DESTROY {
#
# Sybase::CTlib->ct_connect will automatically close when the process ends.
# This should work fine when the Apache child process exits.
#
}

1;
__END__

=head1 NAME

Apache::Sybase::CTlib - Perl extension for creating persistant database connections to sybase using Apache and Sybperl.

=head1 SYNOPSIS

use Apache::Sybase::CTlib;

Apache::Sybase::CTlib->connect_on_init("user", "password", "server");

=head1 DESCRIPTION

This module allows Apache/Modperl/Sybperl users to connect to sybase data servers, and maintain persistant connections. The advantage should be clear, as this avoids the overhead of creating a connection, gathering data, and then destroying the connection with every query.

Place the above commands in your startup file for apache:

In httpd.conf

PerlRequire /apache/startup.pl

In /apache/startup.pl

use Apache::Sybase::CTlib;

Apache::Sybase::CTlib->connect_on_init("user", "password", "server");

If you want to have that user start in a specific database, be sure to set the defdb in syslogins.

=head1 AUTHOR

Mark A. Downing, mdowning@rdatasys.com
http://www.wm7d.net/

=head1 SEE ALSO

perl(1).

=cut
