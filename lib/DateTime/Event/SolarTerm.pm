# Please see file "LICENSE" for license information on code from
# "Calendrical Calculations".
 
package DateTime::Event::SolarTerm;
use strict;
use vars qw($VERSION @ISA %EXPORT_TAGS);
BEGIN {
    $VERSION = '0.03';
    @ISA     = qw(Exporter);

    # This code here will auto-generate the symbols from the given list.
    # The list should have Chunfen/Shunbun (longitude = 0)
    my @term_names = (
        # chinese        japanese     english
        [ 'CHUNFEN',     'SHUNBUN'   ],
        [ 'QINGMING',    'SEIMEI'    ],
        [ 'GUYU',        'KOKUU'     ],
        [ 'LIXIA',       'RIKKA'     ],
        [ 'XIAOMAN',     'SHOMAN'    ],
        [ 'MANGZHONG',   'BOHSHU'    ],
        [ 'XIAZHO',      'GESHI',     'SUMMER_SOLSTICE' ],
        [ 'XIAOSHU',     'SHOUSHO'   ],
        [ 'DASHU',       'TAISHO'    ],
        [ 'LIQIU',       'RISSHU'    ],
        [ 'CHUSHU',      'SHOSHO'    ], # argh, ambiguous with SHOUSHO
        [ 'BAILU',       'HAKURO'    ],
        [ 'QIUFEN',      'SHUUBUN'   ], # argh, ambiguous with SHUNBUN
        [ 'HANLU',       'KANRO'     ],
        [ 'SHUANGJIANG', 'SOHKOH'    ],
        [ 'LIDONG',      'RITTOH'    ],
        [ 'XIAOXUE',     'SHOHSETSU' ],
        [ 'DAXUE',       'TAISETSU'  ],
        [ 'DONGZHI',     'TOHJI',     'WINTER_SOLSTICE' ],
        [ 'XIAOHAN',     'SHOHKAN'   ],
        [ 'DAHAN',       'TAIKAN'    ],
        [ 'LICHUN',      'RISSHUN'   ],
        [ 'YUSHUI',      'USUI'      ],
        [ 'JINGZE',      'KEICHITSU' ],
    );

    $EXPORT_TAGS{chinese} = [];
    $EXPORT_TAGS{japanese} = [];

    foreach my $idx (0..23) {
        my $terms = $term_names[$idx];
        my $longitude = $idx * 15;
        constant->import($terms->[0], $longitude);
        constant->import($terms->[1], $longitude);
        push @{$EXPORT_TAGS{chinese}}, $terms->[0];
        push @{$EXPORT_TAGS{japanese}}, $terms->[1];
        if (defined $terms->[2]) {
            constant->import($terms->[2], $longitude);
            push @{$EXPORT_TAGS{english}}, $terms->[2];
        }

    }

    Exporter::export_ok_tags('chinese');
    Exporter::export_ok_tags('japanese');
    Exporter::export_ok_tags('english');
}

use DateTime;
use DateTime::Set;
use DateTime::Util::Calc qw(mod amod bf_downgrade min truncate_to_midday);
use DateTime::Util::Astro::Sun qw(
    solar_longitude solar_longitude_before solar_longitude_after
    estimate_prior_solar_longitude);
use Params::Validate();
use POSIX();

my %BasicValidate = ( datetime => { isa => 'DateTime' } );
my %ValidateWithLongitude = (
    %BasicValidate,
    longitude => {
        callbacks => {
            'is between 0 and 359' => sub { $_[0] >= 0 && $_[0] < 360 }
        }
    }
);

sub _new {
    my $class = shift;
    return bless {}, $class;
}

sub major_term
{
	my $class = shift;
    my $self  = $class->_new();
    return DateTime::Set->from_recurrence(
        next     => sub { $self->major_term_after(datetime => $_[0]) },
        previous => sub { $self->major_term_before(datetime => $_[0]) }
    );
}

sub minor_term
{
	my $class = shift;
    my $self  = $class->_new();
    return DateTime::Set->from_recurrence(
        next     => sub { $self->minor_term_after(datetime => $_[0]) },
        previous => sub { $self->minor_term_before(datetime => $_[0]) }
    );
}

sub next_term_at
{
	my $self = shift;
    my %args = Params::Validate::validate(@_, \%ValidateWithLongitude);
    my $rv = solar_longitude_after(
        $args{datetime}, bf_downgrade($args{longitude}));

	$rv->set_time_zone($args{datetime}->time_zone);
    return truncate_to_midday($rv);
}

sub major_term_after
{
	my $self = shift;
    my %args = Params::Validate::validate(@_, \%BasicValidate);
    my $dt   = $args{datetime};

# local $DateTime::Util::Calc::NoBigFloat = 1;
    my $midnight = $dt->clone->truncate(to => 'day');
    my $l  = mod(30 * POSIX::ceil(solar_longitude($midnight) / 30), 360);

    return $self->next_term_at(datetime => $dt, longitude => $l);
}

sub minor_term_after
{
	my $self = shift;
    my %args = Params::Validate::validate(@_, \%BasicValidate);
    my $dt   = $args{datetime};

# local $DateTime::Util::Calc::NoBigFloat = 1;
    my $midnight = $dt->clone->truncate(to => 'day');
    my $l        = mod(30 * POSIX::ceil((solar_longitude($midnight) - 15) / 30) + 15, 360);

    return $self->next_term_at(datetime => $dt, longitude => $l);
}

sub prev_term_at
{
	my $self = shift;
    my %args = Params::Validate::validate(@_, \%ValidateWithLongitude);

    my $rv = estimate_prior_solar_longitude(
        $args{datetime}, bf_downgrade($args{longitude}));
	$rv->set_time_zone($args{datetime}->time_zone);
    return truncate_to_midday($rv);
}

sub major_term_before
{
    my $self = shift;
    my %args = Params::Validate::validate(@_, \%BasicValidate);
    my $dt   = $args{datetime};

    my $midnight = $dt->clone->truncate(to => 'day');
    my $l_current = solar_longitude($midnight) ;
    my $l = mod(30 * POSIX::floor($l_current / 30), 360);

    return $self->prev_term_at(datetime => $dt, longitude => $l);
}

sub minor_term_before
{
    my $self = shift;
    my %args = Params::Validate::validate(@_, \%BasicValidate);
    my $dt   = $args{datetime};

    my $midnight = $dt->clone->truncate(to => 'day');
    my $l        = mod(30 * POSIX::floor((solar_longitude($midnight) - 15) / 30) + 15, 360);

    return $self->prev_term_at(datetime => $dt, longitude => $l);
}

# [1] p.245 (current_major_term)
sub last_major_term_index
{
    my $self = shift;
    my %args = Params::Validate::validate(@_, \%BasicValidate);

    my $l = solar_longitude($args{datetime});
    amod((2 + POSIX::floor(bf_downgrade($l) / 30)), 12);
}

# [1] p.245 (current_minor_term)
sub last_minor_term_index
{
    my $self = shift;
    my %args = Params::Validate::validate(@_, \%BasicValidate);

    my $l = solar_longitude($args{datetime});
    amod((3 + POSIX::floor((bf_downgrade($l) - 15) / 30)), 12);
}

# [1] p.250
sub no_major_term_on
{
    my $self = shift;
    my %args = Params::Validate::validate(@_, \%BasicValidate);

    my $next_new_moon = DateTime::Event::Lunar->new_moon_after(
        datetime => $args{datetime});

    return
        $self->last_major_term_index(datetime => $args{datetime}) ==
        $self->last_major_term_index(datetime => $next_new_moon);
}

BEGIN
{
    if (eval { require Memoize } && !$@) {
        Memoize::memoize('no_major_term_on', NORMALIZER => sub {
            shift;
            my %args = Params::Validate::validate(@_, \%BasicValidate);

            ($args{datetime}->utc_rd_values)[0]
        });
    }
}

1;

__END__

=head1 NAME

DateTime::Event::SolarTerm - DateTime Extension to Calculate Solar Terms

=head1 SYNOPSIS

  use DateTime::Event::SolarTerm;
  my $major_term = DateTime::Event::SolarTerm->major_term();

  my $dt0  = DateTime->new(...);
  my $next_major_term = $major_term->next($dt0);
  my $prev_major_term = $major_term->previous($dt0);

  my $dt1  = DateTime->new(...);
  my $dt2  = DateTime->new(...);
  my $span = DateTime::Span->new(start => $dt1, end => $dt2);

  my $set  = $major_term->intersection($span);
  my $iter = $set->iterator();

  while (my $dt = $iter->next) {
    print $dt->datetime, "\n";
  }

  my $minor_term = DateTime::Event::SolarTerm->minor_term();

  my $dt0  = DateTime->new(...);
  my $next_minor_term = $minor_term->next($dt0);
  my $prev_minor_term = $minor_term->previous($dt0);

  my $dt1  = DateTime->new(...);
  my $dt2  = DateTime->new(...);
  my $span = DateTime::Span->new(start => $dt1, end => $dt2);

  my $set  = $minor_term->intersection($span);
  my $iter = $set->iterator();

  while (my $dt = $iter->next) {
    print $dt->datetime, "\n";
  }

  # if you just want to calculate a single major/minor term event
  my $dt = DateTime::Event::Lunar->major_term_after(datetime => $dt0);
  my $dt = DateTime::Event::Lunar->major_term_before(datetime => $dt0);
  my $dt = DateTime::Event::Lunar->minor_term_after(datetime => $dt0);
  my $dt = DateTime::Event::Lunar->minor_term_before(datetime => $dt0);

  my $index = DateTime::Event::SolarTerm->last_major_term_index(datetime => $dt);
  my $index = DateTime::Event::SolarTerm->last_minor_term_index(datetime => $dt);
  my $boolean = DateTime::Event::SolarTerm->no_major_term_on(datetime => $dt);

  # to get the next specific solar term
  use DateTime::Event::SolarTerm qw(DONGZHI);
  my $next = DateTime::Event::SolarTerm->next_term_at(
    datetime  => $dt,
    longitude => DONGZHI
  );
    
  my $prev = DateTime::Event::SolarTerm->prev_term_at(
    datetime  => $dt,
    longitude => DONGZHI
  );

=head1 DESCRIPTION

A lunar calendar has months based on the lunar cycle, which is approximately
29.5 days. This cycle does not match the cycle of the Sun, which is
approximately 365 days. 

You can use leap months to better align the cycle as in the Chinese calendar,
but that still means that months could be off by possibly one lunar month.
This was unacceptable for agricultural purposes which is linked deeply
with the season, which in turn is linked with the solar cycle.

This is where solar terms are used. Regardless of what lunar month it is,
you can tell the season using the solar terms.

Solar terms are still used in some parts of Asia, especially China, where
major holidays must be calculated based on these solar terms.

=head1 FUNCTIONS

  *** WARNING WARNING WARNING ****

  The return value of these functions are subject to change!
  They currently return a simple DateTime object, but we may somehow
  come up with a way to return more data with it, such as the solar
  term's name

  *** WARNING WARNING WARNING ***

=head2 DateTime::Event::SolarTerm-E<gt>major_term()

=head2 DateTime::Event::SolarTerm-E<gt>minor_term()

Returns the I<starting> date of the next or previous major/minor solar term.
This recurrence set makes no attempt to classify just what solar term
is beginning on that date. (This may change in the future)

Because solar terms depend on the location/timezone, you should make
sure to pass a DateTime object with locale and/or timezone set to
where you are basing your calculations on. If the given time zone
does not specify one (i.e. it is a "floating" time zone), then UTC is
assumed.

=head2 DateTime::Event::SolarTerm-E<gt>next_term_at(%args)

Returns a DateTime object representing the next solar term date at
the specified longitude. For example, to get the next winter solstice,
you can say

  use DateTime::Event::SolarTerm qw(WINTER_SOLSTICE);
  my $winter_solstice = DateTime::Event::SolarTerm->next_term_at(
    datetime  => $dt0,
    longitude => WINTER_SOLSTICE
  );

This is the functiont that is internally used by major_term()-E<gt>next() and
minor_term-E<gt>next()

=head2 DateTime::Event::SolarTerm-E<gt>prev_term_at(%args)

Returns a DateTime object representing the previous solar term date at
the specified longitude. For example, to get the previous winter solstice,
you can say

  use DateTime::Event::SolarTerm qw(WINTER_SOLSTICE);
  my $winter_solstice = DateTime::Event::SolarTerm->previous_term_at(
    datetime  => $dt0,
    longitude => WINTER_SOLSTICE
  );

This is the functiont that is internally used by major_term()-E<gt>previous()
and minor_term-E<gt>previous()

=head2 DateTime::Event::SolarTerm-E<gt>last_major_term_index(%args)

Returns the current/previous major term index. Note that even if the date
falls on a minor term, returns the closest previous major term from the date
given by the datetime argument.

(This method has been renamed from current_major_term to better suit the
behavior)

=head2 DateTime::Event::SolarTerm-E<gt>last_minor_term_index(%args)

Returns the current/previous minor term index. Note that even if the date
falls on a minor term, returns the closest previous minor term from the date
given by the datetime argument.

(This method has been renamed from current_minor_term to better suit the
behavior)

=head2 DateTime::Event::SolarTerm-E<gt>no_major_term_on(%args)

Returns true if there is a major term in the lunar month of the specified date.

=head1 AUTHOR

Daisuke Maki E<lt>daisuke@cpan.orgE<gt>

=head1 REFERENCES

  [1] Edward M. Reingold, Nachum Dershowitz
      "Calendrical Calculations (Millenium Edition)", 2nd ed.
       Cambridge University Press, Cambridge, UK 2002

=head1 SEE ALSO

L<DateTime>
L<DateTime::Set>
L<DateTime::Span>
L<DateTime::Event::Lunar>

=cut
