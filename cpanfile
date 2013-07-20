requires 'perl', '5.008001';
requires 'Nephia', '0.32';
requires 'Nephia::Plugin::PlackSession';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
    requires 'Test::WWW::Mechanize::PSGI';
    requires 'Plack::Test';
    requires 'Plack::Builder';
};
