use 5.010000;
use ExtUtils::MakeMaker;
# Requires mod_perl & apache 2
WriteMakefile(
	NAME              => 'Apache2::Warn',
	VERSION_FROM      => 'lib/Apache2/Warn.pm',
	PREREQ_PM         => {
		#mod_perl => 2,
		#Apache2 => 0,
	},
	ABSTRACT_FROM     => 'lib/Apache2/Warn.pm',
	AUTHOR            => 'Mons Anderson <mons@cpan.org>',
	LIBS              => [''],
	DEFINE            => '',
	INC               => '-I. -I/usr/include/httpd -I/usr/include/apr-1',
);
