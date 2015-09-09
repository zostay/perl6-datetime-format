use v6;

unit module DateTime::Format;

## Default list of Month names.
## Add more by loading DateTime::Format::Lang::* modules.
our $month-names = {
    en => <
        January
        February
        March
        April
        May
        June
        July
        August
        September
        October
        November
        December
    >
};

## Default list of Day names.
## Add more by loading DateTime::Format::Lang::* modules.
## ISO 8601 says that Monday is the first day of the week,
## which I think is wrong, but who am I to argue with ISO.
our $day-names = {
    en => <
        Monday
        Tuesday
        Wednesday
        Thursday
        Friday
        Saturday
        Sunday
    >
};

## The default language, change with set-datetime-format-lang().
our $datetime-format-lang = 'en';

## strftime, is exported by default.
multi sub strftime (
  Str $format is copy, 
  DateTime $dt=DateTime.now, 
  Str :$lang=$datetime-format-lang,
  Bool :$subseconds,
) is export {
    my %substitutions =
        # Standard substitutions for yyyy mm dd hh mm ss output.
        'Y' => { $dt.year.fmt(  '%04d') },
        'm' => { $dt.month.fmt( '%02d') },
        'd' => { $dt.day.fmt(   '%02d') },
        'H' => { $dt.hour.fmt(  '%02d') },
        'M' => { $dt.minute.fmt('%02d') },
        'S' => { $dt.whole-second.fmt('%02d') },
        # Special substitutions (Posix-only subset of DateTime or libc)
        'a' => { day-name($dt.day-of-week, $lang).substr(0,3) },
        'A' => { day-name($dt.day-of-week, $lang) },
        'b' => { month-name($dt.month, $lang).substr(0,3) },
        'B' => { month-name($dt.month, $lang) },
        'C' => { ($dt.year/100).fmt('%02d') },
        'e' => { $dt.day.fmt('%2d') },
        'F' => { $dt.year.fmt('%04d') ~ '-' ~ $dt.month.fmt(
                  '%02d') ~ '-' ~ $dt.day.fmt('%02d') },
        'I' => { (($dt.hour+23)%12+1).fmt('%02d') },
        'k' => { $dt.hour.fmt('%2d') },
        'l' => { (($dt.hour+23)%12+1).fmt('%2d') },
        'n' => { "\n" },
        'N' => { (($dt.second % 1)*1000000000).fmt('%09d') },
        'p' => { ($dt.hour < 12) ?? 'AM' !! 'PM' },
        'P' => { ($dt.hour < 12) ?? 'am' !! 'pm' },
        'r' => { (($dt.hour+23)%12+1).fmt('%02d') ~ ':' ~
                  $dt.minute.fmt('%02d') ~ ':' ~ $dt.whole-second.fmt('%02d')
                  ~ (($dt.hour < 12) ?? 'am' !! 'pm') },
        'R' => { $dt.hour.fmt('%02d') ~ ':' ~ $dt.minute.fmt('%02d') },
        's' => { $dt.posix.fmt('%d') },
        't' => { "\t" },
        'T' => { $dt.hour.fmt('%02d') ~ ':' ~ $dt.minute.fmt('%02d') ~ ':' ~ $dt.whole-second.fmt('%02d') },
        'u' => { ~ $dt.day-of-week.fmt('%d') },
        'w' => { ~ (($dt.day-of-week+6) % 7).fmt('%d') },
        'x' => { $dt.year.fmt('%04d') ~ '-' ~ $dt.month.fmt('%02d') ~ '-' ~ $dt.day.fmt('%2d') },
        'X' => { $dt.hour.fmt('%02d') ~ ':' ~ $dt.minute.fmt('%02d') ~ ':' ~ $dt.whole-second.fmt('%02d') },
        'y' => { ($dt.year % 100).fmt('%02d') },
        '%' => { '%' },
        '3N' => { (($dt.second % 1)*1000).fmt('%03d') },
        '6N' => { (($dt.second % 1)*1000000).fmt('%06d') },
        '9N' => { (($dt.second % 1)*1000000000).fmt('%09d') },
        'z' => {
            my $o = $dt.offset;
            $o
            ?? sprintf '%s%02d%02d',
               $o < 0 ?? '-' !! '+',
               ($o.abs / 60 / 60).floor,
               ($o.abs / 60 % 60).floor
            !! 'Z' 
        }
    ; ## End of %substitutions

    $format .= subst( /'%'(\dN|\w|'%')/, -> $/ { (%substitutions{~$0}
            // die "Unknown format letter '$0'").() }, :global );
    return ~$format;
}

## Parse a string and return a DateTime, uses the same format strings
## as strftime().
sub strptime (
    Str $string, 
    Str $format, 
    Str :$lang=$datetime-format-lang,
    DateTime :$now=DateTime.now) is export {

    # TODO Some of these values are overly broad in what they match and result
    # in obtuse and difficult to follow parse errors.
    my %parsers =
        # Standard
        'Y' => regex { $<year>   = [ <[0..9]> ** 1..4 ] },
        'm' => regex { $<month>  = [ <[0..9]> ** 1..2 ] },
        'd' => regex { $<day>    = [ <[0..9]> ** 1..2 ] },
        'H' => regex { $<hour>   = [ <[0..9]> ** 1..2 ] },
        'M' => regex { $<minute> = [ <[0..9]> ** 1..2 ] },
        'S' => regex { $<second> = [ <[0..9]> ** 1..2 ] },
        # Special
        'a' => regex { $<day-of-week-abbr> = [ @($day-names{ $lang }.map({ .substr(0,3) })) ] },
        'A' => regex { $<day-of-week-name> = [ @($day-names{ $lang }) ] },
        'b' => regex { $<month-abbr>       = [ @($month-names{ $lang }.map({ .substr(0, 3) })) ] },
        'B' => regex { $<month-name>       = [ @($month-names{ $lang }) ] },
        'C' => regex { $<century>          = [ <[0..9]> ** 1..2 ] },
        'e' => regex { $<day>              = [ <[0..9]> ** 1..2 ] },
        'I' => regex { $<hour-ambig>       = [ <[0..9]> ** 1..2 ] },
        'k' => regex { $<hour>             = [ <[0..9]> ** 1..2 ] },
        'l' => regex { $<hour-ambig>       = [ <[0..9]> ** 1..2 ] },
        'n' => regex { "\n" },
        'N' => regex { $<nanosecond>       = [ <[0..9]> ** 1..9 ] },
        'p' => regex { $<meridiem>         = [ 'AM' | 'PM' | 'am' | 'pm' ] },
        'P' => regex { $<meridiem>         = [ 'AM' | 'PM' | 'am' | 'pm' ] },
        's' => regex { $<epoch>            = [ <[0..9]>+ ] },
        't' => regex { "\t" },
        'u' => regex { $<day-of-week>      = [ <[0..9]> ] },
        'w' => regex { $<day-of-week-alt>  = [ <[0..9]> ] },
        'y' => regex { $<year>             = [ <[0..9]> ** 1..4 ] },
        '%' => regex { '%' },
        '3N'=> regex { $<millisecond>      = [ <[0..9]> ** 1..3 ] },
        '6N'=> regex { $<microsecond>      = [ <[0..9]> ** 1..6 ] },
        '9N'=> regex { $<nanosecond>       = [ <[0..9]> ** 1..9 ] },
        'z' => regex { $<tz>               = [ 'Z' | <[ + - ]> <[0..9]> ** 4 ] },
    ;

    %parsers = %parsers,
        # Aggregates
        'F' => regex { $(%parsers<Y>) '-' $(%parsers<m>) '-' $(%parsers<d>) },
        'r' => regex { $(%parsers<I>) ':' $(%parsers<M>) ':' $(%parsers<S>) $(%parsers<p>) },
        'R' => regex { $(%parsers<H>) ':' $(%parsers<M>) },
        'T' => regex { $(%parsers<H>) ':' $(%parsers<M>) ':' $(%parsers<S>) },
        'x' => regex { $(%parsers<Y>) '-' $(%parsers<m>) '-' $(%parsers<d>) },
        'X' => regex { $(%parsers<H>) ':' $(%parsers<M>) ':' $(%parsers<S>) },
    ;

    # This grammar builds a regex from the format string
    my grammar Strptime {
        token TOP {
            <term>+ { make $<term>.reduce(-> $a, $b { 
                my Regex:D $rxa = $a.made if $a.^can('made');
                my Regex:D $rxb = $b.made;
                note "# rx/{$rxa.perl}{$rxb.perl}/";
                rx{$rxa$rxb} 
            }) }
        }

        token term {
            || <spec> { make $<spec>.made }
            || <char> { make rx{$<char>} }
        }

        token spec { 
            '%' ( \dN | \w | '%' ) 
            { make %parsers{$0} // rx{ "%$0" } }
        }
        token char { . }
    }

    my $ast = Strptime.parse($format);
    die "unable to parse format: $format" unless $ast;
    my $rx = $ast.made;

    die "unable to parse date string" unless $string ~~ rx{^$rx};

    my %name-months = $month-names{$lang}.kv, 
                      $month-names{$lang}.map({ .substr(0,3) }).kv;
    my %name-days   = $day-names{$lang}.kv,
                      $day-names{$lang}.map({ .substr(0,3) }).kv;

    my $timezone = $<tz> eq 'Z' ?? 0 !! Int($<tz>) // 0;

    return DateTime.new(Int($<epoch>), :$timezone) if $<epoch>;

    my $now = DateTime.now(:$timezone);

    my $year   = Int(($<century> // floor($<year>/100)) * 100 + $<year>%100 // $now.year);
    my $month  = Int($<month> // %name-months{$<month-name> // $<month-abbr>} // $now.month);
    my $day    = Int($<day> // $now.day);
    my $hour   = Int($<hour> // ($<hour-ambig> + 12 * ?($<meridiem> ~~ m:i/am/)));
    my $minute = Int($<minute> // $now.minute);
    my $second = Int(
        $<second> + ($<nanosecond>  / 1000000000
                  // $<microsecond> / 1000000
                  // $<millesecond> / 1000)
        // $now.second
    );

    DateTime.new(
        :$year, :$month, :$day,
        :$hour, :$minute, :$second,
        :$timezone,
    );
}

## Returns the language-specific day name.
sub day-name ($i, $lang) is export(:ALL) {
    # ISO 8601 says Monday is the first day of the week.
    $day-names{$lang.lc}[$i - 1];
}

## Returns the language-specific month name name.
sub month-name ($i, $lang) is export(:ALL) {
    $month-names{$lang.lc}[$i - 1];
}

## Add month names.
sub add-datetime-format-month-names ($lang, @defs) is export(:ALL) {
    $month-names{$lang.lc} = @defs;
}

## Add day names.
sub add-datetime-format-day-names ($lang, @defs) is export(:ALL) {
    $day-names{$lang.lc} = @defs;
}

## Set the default language.
sub set-datetime-format-lang ($lang) is export {
    $datetime-format-lang = $lang.lc;
}

