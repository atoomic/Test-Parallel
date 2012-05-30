#
#===============================================================================
#
#         FILE:  Parallel.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Nicolas Rochelemagne (NR), nicolas.rochelemagne@cpanel.net
#      COMPANY:  cPanel, Inc
#      VERSION:  1.0
#      CREATED:  05/30/2012 08:26:28
#     REVISION:  ---
#===============================================================================

package MyPackage;
use strict;
use warnings;
use v5.10;

__PACKAGE__->run(@ARGV) unless caller();

sub run {
    ## FIXME
    1;
}

sub sample_sub {
    my ($self, @options) = @_;

    my %default = (mykey => 'defaultvalue');
    my %config  = (%default, @options);

}

1;

