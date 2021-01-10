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
our $VERSION = '0.00_02';

use Date::Calc ':all';
use HTML::Make;

# Default HTML elements and classes.

# To do: Put this in a configuration file.

my %html = (
    calendar => {
	element => 'table',
	class => '',
	desc => 'the calendar itself',
    },
    week => {
	element => 'tr',
	class => 'cal-week',
	desc => 'a week',
    },
    day => {
	element => 'td',
	class => 'cal-day',
	desc => 'a day',
    },
    dow => {
	element => 'th',
	class => 'cal-dow',
	desc => 'the day of the week (Monday, Tuesday, etc.)',
    },
);

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

sub calendar
{
    my (%options) = @_;
    # To do: Reduce repetitiveness.
    my $verbose;
    if ($options{verbose}) {
	$verbose = 1;
	delete $options{verbose};
    }
    my ($year, $month, undef) = Today ();
    if ($options{year}) {
	$year = $options{year};
	delete $options{year};
    }
    if ($options{month}) {
	$month = $options{month};
	delete $options{month};
    }
    my $dayc;
    if ($options{dayc}) {
	$dayc = $options{dayc};
	delete $options{dayc};
    }
    my $cdata;
    if ($options{cdata}) {
	$cdata = $options{cdata};
	delete $options{cdata};
    }
    # To do: Allow the user to use their own HTML tags.

    for my $k (sort keys %options) {
	if ($options{$k}) {
	    carp "Unknown option '$k'";
	    delete $options{$k};
	}
    }
    my $dim = Days_in_Month ($year, $month);
    if ($verbose) {
	# To do: Add a messaging routine with caller line numbers
	# rather than just use print.
	print "There are $dim days in month $month of $year.\n";
    }
    my @dow;
    # The number of weeks
    my $weeks = 1;
    my $prev = 0;
    for my $day (1..$dim) {
	my $dow = Day_of_Week ($year, $month, $day);
	$dow[$day] = $dow;
	if ($dow == 1 || $dow < $prev) {
	    $weeks++;
	}
	$prev = $dow;
    }
    # The number of empty cells we need at the start of the month.
    my $fill_start = $dow[1] - 1;
    my $fill_end = 7 - $dow[-1];
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
	push @cells, {dom => $_, dow => $dow[$_]};
    }
    for (1..$fill_end) {
	push @cells, {};
    }
    my $calendar = HTML::Make->new ($html{calendar});
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
    for my $dow (1..7) {
	# To do: Allow the user to use their own weekdays (possibly
	# allow them to use the language specifier of Date::Calc).
	my $wdt = substr (Day_of_Week_to_Text ($dow), 0, 2);
	my $dow_el = add_el ($wdr, $html{dow});
	$dow_el->add_text ($wdt);
    }
    # wom = week of month
    for my $wom (1..$weeks) {
	my $week = add_el ($tbody, $html{week});
	# dow = day of week
	for my $dow (1..7) {
	    my $day = add_el ($week, $html{day});
	    my $cell = shift @cells;
	    # dom = day of month
	    my $dom = $cell->{dom};
	    if (defined $dom) {
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
	    # To do: allow a callback on the packing cells
	}
    }
    return $calendar;
}

1;
