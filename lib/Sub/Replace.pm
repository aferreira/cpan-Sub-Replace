
package Sub::Replace;

# ABSTRACT: Replace subroutines in packages with controlled effects

use 5.010001;

our @EXPORT_OK = qw(sub_replace);

use Carp ();
use Sub::Delete 1.00002 ();

sub sub_replace {
    @_ = %{ $_[0] } if @_ == 1 && ref $_[0] eq 'HASH';
    goto &_sub_replace;
}

sub _sub_replace {
    Carp::croak "Odd number of elements in sub_replace" if @_ % 2;

    my $caller = caller;

    my %old;
    while ( my ( $name, $sub ) = splice @_, 0, 2 ) {

        ( my $stashname, $name )
          = $name =~ /(.*::)((?:(?!::).)*)\z/s
          ? ( $1, $2 )
          : ( $caller . "::", $name );

        my $fullname = "${stashname}${name}";

        my $old = $old{$fullname} = \&{$fullname};
        Sub::Delete::delete_sub $fullname if defined $old;
        *{$fullname} = $sub if defined $sub;
    }

    return \%old;
}

1;

=encoding utf8

=head1 SYNOPSIS

    use Sub::Replace;

    sub one { say 'One' }

    one(); # One

    BEGIN { Sub::Replace::sub_replace('one', sub { say 'Uno' }); }

    one(); # Uno

    BEGIN { Sub::Replace::sub_replace('one', sub { say 'Eins' }); }

    one(); # Eins

=head1 DESCRIPTION

In Perl, replacing a subroutine in a symbol table is as easy as doing:

    *TargetPackage::target_sub = sub { ... };

However that may cause a lot of trouble for compiled code
with mentions to C<\&target_sub>. For example,

    sub one { say 'One' }
    one();
    BEGIN { *one = sub { say 'Uno' }; }
    one();
    BEGIN { *one = sub { say 'Eins' }; }
    one();

will not output

    One
    Uno
    Eins

but

    Eins
    Eins
    Eins

This module provides a C<sub_replace> function to address that.

=head1 FUNCTIONS

L<Sub::Replace> implements the following functions, which are exportable.

=head2 sub_replace

    $old = Sub::Replace::sub_replace($name, $code);
    $old = Sub::Replace::sub_replace($name1, $code1, $name2, $code2);
    $old = Sub::Replace::sub_replace(\%subs);

The sub name may be fully qualified (eg. C<'TargetPackage::target_sub'>) or not
(like C<'target_sub'>). In the latter case, the caller package will be used.

The return is a hash ref which maps the fully qualified names into
the previously installed subroutines (or C<undef> if none were there).
This is suitable to undo a previous C<sub_replace>  by calling

    Sub::Replace::sub_replace($old);

=head1 CAVEATS

The same as mentioned in L<Sub::Delete/"LIMITATIONS">, namely:
you may be surprised by taking references to globs in between
calls to C<sub_replace>.

=head1 SEE ALSO

L<Sub::Delete>

=cut
