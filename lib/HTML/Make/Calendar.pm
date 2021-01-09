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
our $VERSION = '0.01';

use HTML::Make;
use Date::Calc ':all';

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
	carp "Unknown option '$k'";
	delete $options{$k};
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
    for my $row (1..$rows) {
	my $tr = $tbody->push ('tr');
	for my $dow (1..7) {
	    my $td = $tr->push ('td');
	    my $cell = shift @cells;
	    my $dom = $cell->{dom};
	    if (defined $dom) {
		$td->add_text ($dom);
	    }
	}
    }
    return $table->text ();
}

1;
