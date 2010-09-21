package Moose::Meta::Method::Accessor::Native::String::length;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Reader';

sub _minimum_arguments { 0 }
sub _maximum_arguments { 0 }

sub _return_value {
    my ( $self, $slot_access ) = @_;

    return "length $slot_access";
}

1;