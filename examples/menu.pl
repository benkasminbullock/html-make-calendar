#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use HTML::Make::Calendar 'calendar';
binmode STDOUT, ":encoding(utf8)";
my @food = split '', '🍇🍈🍉🍊🍋🍌🍍🥭🍎🍏🍐🍑🍒🍓🥝🍅🥝🍅🥒🥬🥦🧄🧅🍄🥜🌰';
my $cal = calendar (cdata => \@food, dayc => \&add_food);
print $cal->text ();
exit;

sub add_food
{
    my ($food, $date, $element) = @_;
    my $today = $food->[int (rand (@$food))];
    $element->push ('span', text => "$date->{dom} $today");
}
