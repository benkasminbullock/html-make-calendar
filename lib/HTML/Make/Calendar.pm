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
our $VERSION = '0.00_01';

use Date::Calc ':all';
use HTML::Make;

sub calendar
{
    my (%options) = @_;
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
    for my $k (sort keys %options) {
	if ($options{$k}) {
	    carp "Unknown option '$k'";
	    delete $options{$k};
	}
    }
    my $dim = Days_in_Month ($year, $month);
    if ($verbose) {
	print "There are $dim days in month $month of $year.\n";
    }
    my @dow;
    # The number of rows (weeks)
    my $rows = 1;
    my $prev = 0;
    for my $day (1..$dim) {
	my $dow = Day_of_Week ($year, $month, $day);
	$dow[$day] = $dow;
	if ($dow == 1 || $dow < $prev) {
	    $rows++;
	}
	$prev = $dow;
    }
    # The number of empty cells we need at the start of the month.
    my $fill_start = $dow[1] - 1;
    my $fill_end = 7 - $dow[-1];
    if ($verbose) {
	print "Start $fill_start, end $fill_end, rows $rows\n";
    }
    my @cells;
    for (1..$fill_start) {
	push @cells, {};
    }
    for (1..$dim) {
	push @cells, {dom => $_, dow => $dow[$_]};
    }
    for (1..$fill_end) {
	push @cells, {};
    }
    my $table = HTML::Make->new ('table');
    # This is the correct HTML, although nobody really does this.
    my $tbody = $table->push ('tbody');

    my $titler = $tbody->push ('tr');
    my $titleh = $titler->push ('th', attr => {colspan => 7});
    my $my = Month_to_Text ($month) . " $year";
    $titleh->add_text ($my);

    my $wdr = $tbody->push ('tr');
    for my $wd (1..7) {
	my $wdt = substr (Day_of_Week_to_Text ($wd), 0, 2);
	$wdr->push ('th', text => $wdt);
    }

    for my $row (1..$rows) {
	my $tr = $tbody->push ('tr', attr => {class => 'cal-row'});
	for my $dow (1..7) {
	    my $td = $tr->push ('td', attr => {class => 'cal-day'});
	    my $cell = shift @cells;
	    my $dom = $cell->{dom};
	    if (defined $dom) {
		$td->push ('span', text => $dom,
			   attr => {class => 'cal-dom'});
	    }
	}
    }
    my %r;
    $r{table} = $table;
    $r{html} = $table->text ();
    return \%r;
}

1;
