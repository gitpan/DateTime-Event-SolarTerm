#!perl
use strict;
use inc::Module::Install;

name("DateTime-Event-SolarTerm");
all_from("lib/DateTime/Event/SolarTerm.pm");
license("perl");

requires 'DateTime';
requires 'DateTime::Set';
requires 'DateTime::Util::Calc' => '0.12';
requires 'DateTime::Util::Astro::Sun' => '0.11';
requires 'Params::Validate';

auto_install;
WriteAll;
