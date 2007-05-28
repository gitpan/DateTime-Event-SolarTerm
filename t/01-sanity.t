#!perl
use strict;
use Test::More qw(no_plan);
BEGIN
{
    print STDERR "\n*** This test takes a *long* time. Please be patient! ***\n";
    use_ok( "DateTime::Event::SolarTerm");
}
use DateTime::Event::SolarTerm;
use constant MAX_DELTA_MINUTES => 180;
use constant NUM_SAMPLE => 6;

# XXX - make sure to include dates in wide range
my @major_term_dates = 
    map { 
        my %args;
        @args{ qw(year month day hour minute time_zone) } =
            ( @$_, 12, 0, 'Asia/Shanghai' );
        DateTime->new(%args);
    }
    (
        [ 2003,  1, 20 ], # Dahan / Taikan
        [ 2003,  2, 19 ], # Yushui / Usui
        [ 2003,  3, 21 ], # Chunfen / Shunbun
        [ 2003,  4, 20 ], # Guyu / Kokuu
        [ 2003,  5, 21 ], # Xiaman / Shoman
        [ 2003,  6, 22 ], # Xiazhi / Geshi
        [ 2003,  7, 23 ], # Dashu / Taisho
        [ 2003,  8, 23 ], # Chushu / Shosho
        [ 2003,  9, 23 ], # Qiufen / Shubun
        [ 2003, 10, 24 ], # Shuangjiang / Soko
        [ 2003, 11, 23 ], # Xiaoxue / Shosetsu
        [ 2003, 12, 22 ], # Dongzhi / Toji
        [ 2004,  1, 21 ], # Dahan / Taikan
        [ 2004,  2, 19 ], # Yushui / Usui
        [ 2004,  3, 20 ], # Chunfen / Shunbun
        [ 2004,  4, 20 ], # Guyu / Kokuu
        [ 2004,  5, 21 ], # Xiaman / Shoman
        [ 2004,  6, 21 ], # Xiazhi / Geshi
        [ 2004,  7, 22 ], # Dashu / Taisho
        [ 2004,  8, 23 ], # Chushu / Shosho
        [ 2004,  9, 23 ], # Qiufen / Shubun
        [ 2004, 10, 23 ], # Shuangjiang / Soko
        [ 2004, 11, 22 ], # Xiaoxue / Shosetsu
        [ 2004, 12, 21 ], # Dongzhi / Toji
    );


my @minor_term_dates = 
    map { 
        my %args;
        @args{ qw(year month day hour minute time_zone) } =
            ( @$_, 12, 0, 'Asia/Shanghai' );
        DateTime->new(%args);
    }
    (
        [ 2003, 1, 6 ],
        [ 2003, 2, 4 ],
        [ 2004,  1, 6 ], # Xiaohan / Shokan
        [ 2004,  2, 4 ], # Lichun / Risshun
        [ 2004,  3, 5 ], # Jingzhe / Keichitsu
        [ 2004,  4, 4 ], # Qingming / Seimei
        [ 2004,  5, 5 ], # Lixia / Rikka
        [ 2004,  6, 5 ], # Mangzhong / Boshu
        [ 2004,  7, 7 ], # Xiaoshu / Shosho
        [ 2004,  8, 7 ], # Liqiu / Risshu
        [ 2004,  9, 7 ], # Bailu / Hakuro
        [ 2004, 10, 8 ], # Hanlu / Kanro
        [ 2004, 11, 7 ], # Lidong / Ritto
        [ 2004, 12, 7 ], # Dashue / Taisetsu
    );

sub do_major_terms
{
    my $solar_term = DateTime::Event::SolarTerm->major_term();

#     diag("Checking major term");
    foreach my $dt (map { $major_term_dates[rand(@major_term_dates)] } 1..NUM_SAMPLE) {
#        diag("Checking $dt");
        # if $dt is a solar term date, 7 days prior to this date is *definitely*
        # after the last solar term, but before the one expressed by $dt
        my $dt0 = $dt - DateTime::Duration->new(days => 7);

        my $next_solar_term = $solar_term->next($dt0);

        check_deltas($dt, $next_solar_term, "next major solar term from $dt0");
    
        # Same as before, but now we try $dt + 7 days
        my $dt1 = $dt + DateTime::Duration->new(days => 7);
        my $prev_solar_term = $solar_term->previous($dt1);
    
        check_deltas($dt, $prev_solar_term, "prev major solar term from $dt1");
    }
}

sub do_minor_terms
{
#    diag("Checking major term");
    foreach my $dt (map { $minor_term_dates[rand(@minor_term_dates)] } 1..NUM_SAMPLE) {
        # if $dt is a solar term date, 7 days prior to this date is *definitely*
        # after the last solar term, but before the one expressed by $dt
        my $dt0 = $dt - DateTime::Duration->new(days => 7);
    
        my $solar_term = DateTime::Event::SolarTerm->minor_term();
        my $next_solar_term = $solar_term->next($dt0);
    
        check_deltas($dt, $next_solar_term, "next minor term from $dt0");
    
        # Same as before, but now we try $dt + 7 days
        my $dt1 = $dt + DateTime::Duration->new(days => 7);
        my $prev_solar_term = $solar_term->previous($dt1);
    
        check_deltas($dt, $prev_solar_term, "prev minor term from $dt1");
    }
}
    
sub check_deltas
{
    my($expected, $actual, $msg) = @_;

    my $diff = $expected - $actual;
    ok($diff);
    
    # make sure the deltas do not exceed 3 hours
    my %deltas = $diff->deltas;
    ok( $deltas{months} == 0 &&
        $deltas{days} == 0 &&
        abs($deltas{minutes}) < MAX_DELTA_MINUTES, $msg) or
    diag( "Expected solar term date was " . 
        $expected->strftime("%Y/%m/%d %T %Z") . " but instead we got " .
        $actual->strftime("%Y/%m/%d %T %Z") .
        " which is more than allowed delta of " .
        MAX_DELTA_MINUTES . " minutes" );
}

do_major_terms();
do_minor_terms();
