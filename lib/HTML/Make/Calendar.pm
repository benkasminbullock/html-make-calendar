package HTML::Make::Calendar;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/calendar/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.00_04';

use Date::Calc ':all';
use HTML::Make;
use Table::Readable 'read_table';

# Default HTML elements and classes.

my @dowclass = (undef, "mon", "tue", "wed", "thu", "fri", "sat", "sun");

# Read the configuration file.

my $html_file = __FILE__;
$html_file =~ s!\.pm!/html.txt!;
my @html = read_table ($html_file);
my %html;
for (@html) {
    $html{$_->{item}} = $_
}

# Add an HTML element defined by $thing to $parent.

sub add_el
{
    my ($parent, $thing) = @_;
    my $class = $thing->{class};
    my $type = $thing->{element};
    my $element;
    if ($class) {
	# HTML::Make should have a class pusher since it is so common
	# http://mikan/bugs/bug/2108
	$element = $parent->push ($type, attr => {class => $class});
    }
    else {
	# Allow non-class elements if the user doesn't want a class.
	$element = $parent->push ($type);
    }
    return $element;
}

sub option
{
    my ($ref, $options, $what) = @_;
    if ($options->{$what}) {
	$$ref = $options->{$what};
	delete $options->{$what};
    }
}

sub calendar
{
    my (%options) = @_;
    option (\my $verbose, \%options, 'verbose');
    my ($year, $month, undef) = Today ();
    option (\$year, \%options, 'year');
    option (\$month, \%options, 'month');
    option (\my $dayc, \%options, 'dayc');
    option (\my $cdata, \%options, 'cdata');
    my $html_week = $html{week}{element};
    option (\$html_week, \%options, 'html_week');
    my $first = 1;
    option (\$first, \%options, 'first');
    if ($first != 1) {
	if (int ($first) != $first || $first < 1 || $first > 7) {
	    carp "Use a number between 1 (Monday) and 7 (Sunday) for first";
	    $first = 1;
	}
    }
    # To do: Allow the user to use their own HTML tags.

    for my $k (sort keys %options) {
	if ($options{$k}) {
	    carp "Unknown option '$k'";
	    delete $options{$k};
	}
    }
    # Map from columns of the calendar to days of the week, e.g. 1 ->
    # 7 if Sunday is the first day of the week.
    my %col2dow;
    for (1..7) {
	my $col2dow = $_ + $first - 1;
	if ($col2dow > 7) {
	    $col2dow -= 7;
	}
	$col2dow{$_} = $col2dow;
    }
    my %dow2col = reverse %col2dow;
    my $dim = Days_in_Month ($year, $month);
    if ($verbose) {
	# To do: Add a messaging routine with caller line numbers
	# rather than just use print.
	print "There are $dim days in month $month of $year.\n";
    }
    my @col;
    # The number of weeks
    my $weeks = 1;
    my $prev = 0;
    for my $day (1..$dim) {
	my $dow = Day_of_Week ($year, $month, $day);
	my $col = $dow2col{$dow};
	$col[$day] = $col;
	if ($col < $prev) {
	    $weeks++;
	}
	$prev = $col;
    }
    # The number of empty cells we need at the start of the month.
    my $fill_start = $col[1] - 1;
    my $fill_end = 7 - $col[-1];
    if ($verbose) {
	print "Start $fill_start, end $fill_end, weeks $weeks\n";
    }
    my @cells;
    # To do: Allow the user to colour or otherwise alter empty cells,
    # for example with a callback or with a user-defined class.
    for (1..$fill_start) {
	push @cells, {};
    }
    for (1..$dim) {
	my $col = $col[$_];
	push @cells, {dom => $_, col => $col, dow => $col2dow{$col}};
    }
    for (1..$fill_end) {
	push @cells, {};
    }
    my $calendar = HTML::Make->new ($html{calendar}{element});
    # As far as I know, <table><tbody> is the correct HTML, although
    # nobody really does this.

    # To do: inspect the type of $html{calendar} and don't add the
    # <tbody> unless it is a <table> element.
    my $tbody = $calendar->push ('tbody');
    # To do: These should be overridden if the caller doesn't want to
    # use table, tr, td to construct the calendar.
    my $titler = $tbody->push ('tr');
    my $titleh = $titler->push ('th', attr => {colspan => 7});
    # To do: Allow the caller to override this.
    my $my = Month_to_Text ($month) . " $year";
    $titleh->add_text ($my);
    # To do: Allow the user to override this.
    my $wdr = $tbody->push ('tr');
    for my $col (1..7) {
	# To do: Allow the user to use their own weekdays (possibly
	# allow them to use the language specifier of Date::Calc).
	my $dow = $col2dow{$col};
	my $wdt = substr (Day_of_Week_to_Text ($dow), 0, 2);
	my $dow_el = add_el ($wdr, $html{dow});
	$dow_el->add_text ($wdt);
    }
    # wom = week of month
    for my $wom (1..$weeks) {
	my $week = add_el ($tbody, $html{week});
	for my $col (1..7) {
	    # dow = day of week
	    my $dow = $col2dow{$col};
	    my $day = add_el ($week, $html{day});
	    my $cell = shift @cells;
	    # dom = day of month
	    my $dom = $cell->{dom};
	    if (defined $dom) {
		$day->add_class ('cal-' . $dowclass[$dow]);
		if ($dayc) {
		    &{$dayc} ($cdata,
			  {
			      year => $year,
			      month => $month,
			      dom => $dom,
			      dow => $dow,
			      wom => $wom,
			  }, 
			  $day);
		}
		else {
		    $day->push ('span', text => $dom,
				attr => {class => 'cal-dom'});
		}
	    }
	    else {
		$day->add_class ('cal-noday');
	    }
	    # To do: allow a callback on the packing cells
	}
    }
    return $calendar;
}

1;
