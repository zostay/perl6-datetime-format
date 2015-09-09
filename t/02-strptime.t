use v6;
use Test;

use lib 'lib';

plan 4;

use DateTime::Format;
use DateTime::Format::Lang::FR;

# partial

# simple
{
    my $g1 = DateTime.new(:year(1582), :month(10), :day(4),
                    :hour(13),   :minute(2), :second(3) );

    my $format = '%Y/%m/%d %H:%M:%S';
    my $input = "1582/10/04 13:02:03";
    is strptime($input, $format), $g1, 'simple strptime'; # test 1
}

# crazy go nuts
{
    my $g1 = DateTime.new(:year(1582), :month(10), :day(4),
                    :hour(13),   :minute(2), :second(3.654321) );

    my $format = '%Y/%m/%d %H:%M:%S %C%e %I=%k%l%t%3N%p %a,%F%%.%n';
    my $input = "1582/10/04 13:02:03 15 4 01=13 1\t654PM Mon,1582-10-04%.\n";
    is strptime($input, $format), $g1, 'crazy go nuts strptime'; # test 1
}

# multilang support
{
    my $g1 = DateTime.new(:year(1), :month(2),  :day(3),
                    :hour(4), :minute(5), :second(6.987654) );

    my $format = '%I %6N %A %b=%B';
    my $input = "04 987654 Saturday Feb=February";
    is strftime($input, $format), $g1, 'english strptime'; # test 2

    $input = "04 987654 samedi fév=février";
    is strftime($input, $format, :lang<fr>), $g1, 'strptime explicit fr lang';

    set-datetime-format-lang('fr');

    is strftime($input, $format), $g1, 'strptime with fr lang as default';
}

