package Apache2::Warn;

our $VERSION = '0.01';

use 5.010;
use strict;
use warnings;
no warnings 'once';
use Carp;

require XSLoader;
XSLoader::load('Apache2::Warn', $VERSION);

sub Apache2::Warn::SWCB::DESTROY {
	my $self = shift;
	$SIG{__WARN__} = $self;
}

sub import {
	no strict 'refs';
	my $me = shift;
	my $caller = caller();
	while (@_) {
		local $_ = shift;
		if (/^:all$/) {
			@_ = qw(warn :apr :sig :global);
			redo;
		}
		elsif (/^:sig$/) {
			$SIG{__WARN__} = \&Apache2::Warn::warn;
		}
		elsif (/^:supersig$/) {
			# not works as expected yet
			my $cb = sub {
				goto &Apache2::Warn::warn;
			};
			bless $cb, 'Apache2::Warn::SWCB';
			$SIG{__WARN__} = $cb;
		}
		elsif (/^:global$/) {
			*CORE::GLOBAL::warn = \&Apache2::Warn::warn;
		}
		elsif (/^:apr$/) {
			require Apache2::Log;
			Apache2::Log->import();
			no warnings 'redefine';
			*Apache2::RequestRec::warn = \&Apache2::Warn::rwarn;
			*Apache2::RequestRec::log_error = \&Apache2::Warn::rwarn;
		}
		elsif ( defined &{ $me . '::' . $_ } ) {
			*{ $caller.'::'.$_ } = \&{ $me . '::' . $_ };
		}
		else {
			croak "$_ is not exported by $me";
		}
	}
}


1;
__END__
=head1 NAME

Apache2::Warn - Write raw warns to VHost's error_log

=head1 SYNOPSIS

    use Apache2::Warn;
    # ...
    sub handler {
        my ($x,$r) = @_;
        Apache2::Warn::rwarn($r, "your raw warning");
        Apache2::Warn::warn("your raw warning");
    }
    
    # or
    
    use Apache2::Warn 'warn';
    # ...
    sub handler {
        my ($x,$r) = @_;
        warn("your raw warning");
    }

    # or
    
    use Apache2::Warn ':apr';
    # ...
    sub handler {
        my ($x,$r) = @_;
        $r->warn("your raw warning");
    }
    
    # or
    
    use Apache2::Warn ':global'; # set CORE::GLOBAL::
    # ...
    sub handler {
        my ($x,$r) = @_;
        warn("your raw warning");
    }
  
    # or
    
    use Apache2::Warn ':sig'; # set $SIG{__WARN__};
    # ...
    sub handler {
        my ($x,$r) = @_;
        warn("your raw warning");
    }

    # or all at once
    
    use Apache2::Warn ':all'; # same as warn :apr :sig :global
    # ...
    sub handler {
        my ($x,$r) = @_;
        warn("your raw warning");
    }

=head1 DESCRIPTION

Since apache 2 common perl's warn write message to apache error_log, not to vhost's error_log.
And if you use L<Apache2::Log> you got something appended to your message (like date or client ip).
If you want to write raw logs, without any argument, this is for you

=head2 EXPORT

None by default.

=head1 AUTHOR

Mons Anderson E<lt>mons@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013 by Mons Anderson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
