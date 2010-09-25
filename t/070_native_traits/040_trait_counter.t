#!/usr/bin/perl

use strict;
use warnings;

use Moose ();
use Moose::Util::TypeConstraints;
use Test::Exception;
use Test::More;
use Test::Moose;

{
    my %handles = (
        inc_counter    => 'inc',
        inc_counter_2  => [ inc => 2 ],
        dec_counter    => 'dec',
        dec_counter_2  => [ dec => 2 ],
        reset_counter  => 'reset',
        set_counter    => 'set',
        set_counter_42 => [ set => 42 ],
    );

    my $name = 'Foo1';

    sub build_class {
        my %attr = @_;

        my $class = Moose::Meta::Class->create(
            $name++,
            superclasses => ['Moose::Object'],
        );

        $class->add_attribute(
            counter => (
                traits  => ['Counter'],
                is      => 'ro',
                isa     => 'Int',
                default => 0,
                handles => \%handles,
                clearer => '_clear_counter',
                %attr,
            ),
        );

        return ( $class->name, \%handles );
    }
}

{
    run_tests(build_class);
    run_tests( build_class( lazy => 1 ) );
    run_tests( build_class( trigger => sub { } ) );

    # Will force the inlining code to check the entire hashref when it is modified.
    subtype 'MyInt', as 'Int', where { 1 };

    run_tests( build_class( isa => 'MyInt' ) );

    coerce 'MyInt', from 'Int', via { $_ };

    run_tests( build_class( isa => 'MyInt', coerce => 1 ) );
}

sub run_tests {
    my ( $class, $handles ) = @_;

    can_ok( $class, $_ ) for sort keys %{$handles};

    with_immutable {
        my $obj = $class->new();

        is( $obj->counter, 0, '... got the default value' );

        $obj->inc_counter;
        is( $obj->counter, 1, '... got the incremented value' );

        $obj->inc_counter;
        is( $obj->counter, 2, '... got the incremented value (again)' );

        throws_ok { $obj->inc_counter( 1, 2 ) }
        qr/Cannot call inc with more than 1 argument/,
            'inc throws an error when two arguments are passed';

        $obj->dec_counter;
        is( $obj->counter, 1, '... got the decremented value' );

        throws_ok { $obj->dec_counter( 1, 2 ) }
        qr/Cannot call dec with more than 1 argument/,
            'dec throws an error when two arguments are passed';

        $obj->reset_counter;
        is( $obj->counter, 0, '... got the original value' );

        throws_ok { $obj->reset_counter(2) }
        qr/Cannot call reset with any arguments/,
            'reset throws an error when an argument is passed';

        $obj->set_counter(5);
        is( $obj->counter, 5, '... set the value' );

        throws_ok { $obj->set_counter( 1, 2 ) }
        qr/Cannot call set with more than 1 argument/,
            'set throws an error when two arguments are passed';

        $obj->inc_counter(2);
        is( $obj->counter, 7, '... increment by arg' );

        $obj->dec_counter(5);
        is( $obj->counter, 2, '... decrement by arg' );

        $obj->inc_counter_2;
        is( $obj->counter, 4, '... curried increment' );

        $obj->dec_counter_2;
        is( $obj->counter, 2, '... curried deccrement' );

        $obj->set_counter_42;
        is( $obj->counter, 42, '... curried set' );

        if ( $class->meta->get_attribute('counter')->is_lazy ) {
            my $obj = $class->new;

            $obj->inc_counter;
            is( $obj->counter, 1, 'inc increments - with lazy default' );

            $obj->_clear_counter;

            $obj->dec_counter;
            is( $obj->counter, -1, 'dec decrements - with lazy default' );
        }
    }
    $class;
}

done_testing;