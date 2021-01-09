use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/HTML/Make/Calendar.pm';
my $pod = 'lib/HTML/Make/Calendar.pod';
my $github = 'github.com/benkasminbullock/html-make-calendar';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'HTML::Make::Calendar',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
    META_MERGE => {
	'meta-spec' => {
	    version => 2,
	},
        resources => {
            repository => {
		type => 'git',
		url => "git://$github.git",
		web => $repo,
	    },
            bugtracker => {
		web => "$repo/issues",
	    },
#	    homepage => 'http://',
        },
    },
    MIN_PERL_VERSION => '5.006001',
);
