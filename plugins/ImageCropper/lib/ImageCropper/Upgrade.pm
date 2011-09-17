package ImageCropper::Upgrade;

use strict;
use warnings;
use Carp qw( croak );
# use YAML;
# use MT::Log::Log4perl qw( l4mtdump ); use Log::Log4perl qw( :resurrect ); my $logger ||= MT::Log::Log4perl->new();

=head1 NAME

  ImageCropper::Upgrade - ImageCropper upgrade functions

=head1 DESCRIPTION

This class was founded with the mission of providing a loving home for and
catering to the special needs of wayward Perl upgrade functions.

It is our greatest hope that by removing them their former ill-suited and
hostile living environment (the YAML config file) and putting them amongst
their own kind, they may one day realize their full potential and grow into
their rightful role as valuable, first-class members of society.

=cut

#############################################################################

=head1 METHODS

=head2 prototype_map_key( $map_obj )

This method is the sole handler for the C<cropper_key_change> upgrade function
introduced with schema version 6. This method modifies all
ImageCropper::PrototypeMap records by simply migrating their C<prototype_id>
value to the C<prototype_key> field.

=cut
sub prototype_map_key {
    my $map = shift;
    my $pid = $map->prototype_id;
    $map->prototype_key('custom_' . $pid);
}

1;