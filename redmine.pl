#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use feature qw/say/;

use URI;
use URI::QueryParam;
use LWP::UserAgent;
use JSON;
use Encode;
use Time::Piece;
use Time::Seconds;


sub api_key {
    open (FILE, 'api_key.txt') or die "$!";
    my @keys = <FILE>;
    chomp(@keys);
    close(FILE);

    return $keys[0] || '';
}

sub get_issues {
    my $today = localtime(Time::Piece->strptime(localtime->ymd, "%Y-%m-%d"));

    my $uri = URI->new('https://redmine.fout.jp/projects/fout-dev/issues.json?utf8=✓&set_filter=1&sort=assigned_to%2Cpriority%3Adesc%2Cdue_date&f%5B%5D=category_id&op%5Bcategory_id%5D=%3D&v%5Bcategory_id%5D%5B%5D=11&v%5Bcategory_id%5D%5B%5D=17&v%5Bcategory_id%5D%5B%5D=12&f%5B%5D=tracker_id&op%5Btracker_id%5D=%3D&v%5Btracker_id%5D%5B%5D=6&v%5Btracker_id%5D%5B%5D=5&v%5Btracker_id%5D%5B%5D=2&v%5Btracker_id%5D%5B%5D=7&v%5Btracker_id%5D%5B%5D=3&v%5Btracker_id%5D%5B%5D=1&v%5Btracker_id%5D%5B%5D=8&v%5Btracker_id%5D%5B%5D=9&v%5Btracker_id%5D%5B%5D=10&v%5Btracker_id%5D%5B%5D=14&v%5Btracker_id%5D%5B%5D=13&v%5Btracker_id%5D%5B%5D=15&v%5Btracker_id%5D%5B%5D=28&f%5B%5D=start_date&op%5Bstart_date%5D=%3C%3D&v%5Bstart_date%5D%5B%5D=2018-09-03&f%5B%5D=due_date&op%5Bdue_date%5D=%3E%3D&v%5Bdue_date%5D%5B%5D=2018-08-20&f%5B%5D=&c%5B%5D=priority&c%5B%5D=tracker&c%5B%5D=due_date&c%5B%5D=subject&c%5B%5D=done_ratio&c%5B%5D=assigned_to&group_by=status&t%5B%5D=');
    $uri->query_param("key", api_key);
    $uri->query_param("v[start_date][]", $today->strftime("%Y-%m-%d"));
    $uri->query_param("v[due_date][]", ($today - ONE_DAY * $today->_wday)->strftime("%Y-%m-%d"));
    $uri->query_param("limit", 1000);

    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    my $res = $ua->get($uri->as_string);

    return decode_json(encode('utf-8', $res->content))->{issues};
}


my $issues = get_issues();

say "#### Finish\n";
say "- " . "[#$_->{id}](https://redmine.fout.jp/issues/$_->{id}) : $_->{subject}" for grep { $_->{status}->{name} =~ 'Finish' } @$issues;
print "\n";

say "#### Progress\n";
say "- " . "[#$_->{id}](https://redmine.fout.jp/issues/$_->{id}) : $_->{subject}" for grep { $_->{status}->{name} =~ 'Progress' } @$issues;
print "\n";
