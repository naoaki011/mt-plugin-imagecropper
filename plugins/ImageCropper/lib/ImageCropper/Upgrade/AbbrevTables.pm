package ImageCropper::Upgrade::AbbrevTables;

use strict;
use warnings;
use base qw( MT::ErrorHandler );
# use MT::Log::Log4perl qw( l4mtdump ); use Log::Log4perl qw( :resurrect ); my $logger ||= MT::Log::Log4perl->new();

=head1 NAME

   ImageCropper::Upgrade::AbbrevTables - An upgrade for Oracle compatibility

=head1 DESCRIPTION

This package is comprised of the handler for the C<abbrev_tables> upgrade
function. This upgrade restores Oracle compatibility lost at some point by 
the use of table, column and index names which exceeded the 30-character 
limit imposed by Oracle on all system identifiers.

The high-level solution to the problem is very simple and straightforward:
Shorten the datasource property values for two problematic object classes.

=over 4

=item * C<ImageCropper::Prototype>: CHANGE C<cropper_prototypes> TO C<crop>

=item * C<ImageCropper::PrototypeMap>: CHANGE C<cropper_prototypemaps> TO
C<crop_map>

=back

Of course, since the datasource is used as a namespace in not only tables
names but also all of the table's columns, indexes and sequences, the easiest
way to handle this is move the data to a new table created for us
automatically by MT::Upgrade.

=cut

###########################################################################

=head1 METHODS

=head2 legacy_properties()

Returns a reference to a hash of legacy class names to class properties. The
legacy classes will be dynamically created and will use the class defined by
the replaced_by_class property as the basis for its own properties.

=cut
sub legacy_properties {
    return {
        'ImageCropper::Prototype::Legacy' => {
            datasource        => 'cropper_prototypes',
            replaced_by_class => 'ImageCropper::Prototype',
        },
        'ImageCropper::PrototypeMap::Legacy' => {
            datasource        => 'cropper_prototypemaps',
            replaced_by_class => 'ImageCropper::PrototypeMap',
        }
    }
}

###########################################################################

=head2 run()

This method serves as the executor of the the C<abbrev_tables> upgrade
function. It executes the migration of legacy class content to the new tables
relying heavily on MT::Object::LegacyFactory for its work.

=cut
sub run {
    my $app          = shift;
    my $legacy_props = legacy_properties();
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    require MT::Object::LegacyFactory;

    # Iterate over each legacy class defined in legacy_properties()
    foreach my $class ( keys %$legacy_props ) {
        ###l4p $logger->info("Migrating data for $class");

        # Dynamically create class for accessing legacy data tables
        my $props = MT::Object::LegacyFactory->init_class(
            $class, $legacy_props->{$class}
        );

        # Migrate the data from legacy table to new table
        defined( my $migrated = $class->migrate_data() )
            or return $app->error( 'Legacy data migration failed: '
                                    .$class->errstr );

        # Safety check for remaining records
        if ( my $leftovers = $class->count() ) {
            $app->progress(sprintf(
                  '%d %s records were not fully migrated and will be left '
                . 'in %s for manual inspection and/or processing',
                    $leftovers, $class, $class->table_name
            ), 1);
            next;
        }

        # Remove the data table
        $class->remove_datasource or return $app->error( $class->errstr );

        $app->progress(sprintf( '%d %s records migrated',
                                $migrated, $props->{datasource}));
    }
}

1;

__END__
