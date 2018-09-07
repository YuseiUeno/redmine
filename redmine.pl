#!/usr/bin/perl
use strict;
use warnings;
use utf8;

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

sub user_url {
    open (FILE, 'user_url.txt') or die "$!";
    my @urls = <FILE>;
    chomp(@urls);
    close(FILE);

    return $urls[0] || '';
}

sub get_issues {
    my $today = localtime(Time::Piece->strptime(localtime->ymd, "%Y-%m-%d"));

    my $uri = URI->new(user_url);
    $uri->query_param("key", api_key);
    $uri->query_param("v[start_date][]", $today->strftime("%Y-%m-%d"));
    $uri->query_param("v[due_date][]", ($today - ONE_DAY * $today->_wday)->strftime("%Y-%m-%d"));
    $uri->query_param("limit", 1000);

    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    my $res = $ua->get($uri->as_string);

    return decode_json(encode('utf-8', $res->content))->{issues};
}


my $issues = {};

for my $row (@{get_issues()}) {
    push @{$issues->{$row->{assigned_to}->{name}}}, $row;
}

print "Finish\n\n";

for my $user (keys %$issues) {
    my $finish = [ grep { $_->{status}->{name} =~ 'Finish' } @{$issues->{$user}} ];
    next if !@$finish;

    print "- @" . $user . "\n";
    print "    - " . "[#[$_->{id}](https://redmine.fout.jp/issues/$_->{id}) : $_->{subject}\n" for @$finish;
}

print "\nProgress\n\n";

for my $user (keys %$issues) {
    my $progress = [ grep { $_->{status}->{name} =~ 'Progress' } @{$issues->{$user}} ];
    next if !@$progress;

    print "- @" . $user . "\n";
    print "    - " . "#[$_->{id}](https://redmine.fout.jp/issues/$_->{id}) : $_->{subject}\n" for @$progress;
}
print "\n";
