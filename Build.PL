use strict;
use Module::Build;

my $build = Module::Build->new(
	module_name => 'DateTime::Event::SolarTerm',
	dist_name => 'DateTime-Event-SolarTerm',
	license => 'perl',
	requires => {
		'DateTime' => 0,
		'DateTime::Set' => 0,
		'DateTime::Util::Calc' => 0,
		'DateTime::Util::Astro::Sun' => 0,
		'Params::Validate' => 0,
	},
	sign => 1,
	create_readme => 1,
    create_makefile_pl => 'passthrough'
);
$build->create_build_script;
