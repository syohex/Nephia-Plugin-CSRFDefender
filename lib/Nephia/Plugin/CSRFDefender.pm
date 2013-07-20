package Nephia::Plugin::CSRFDefender;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";
our @EXPORT = qw/get_csrf_defender_token validate_csrf/;

our $ERROR_HTML = <<'...';
<!doctype html>
<html>
  <head>
    <title>403 Forbidden</title>
  </head>
  <body>
    <h1>403 Forbidden</h1>
    <p>
      Session validation failed.
    </p>
  </body>
</html>
...

sub get_csrf_defender_token {
    my $self = shift;
    my $app  = context('app');

    if ( my $token = $app->session->get('csrf_token') ) {
        $token;
    } else {
        $token = generate_token();
        $app->session->set('csrf_token' => $token);
        $token;
    }
}

sub validate_csrf {
    my $req = context('req');
    my $app = context('app');

    if ( $req->env->{REQUEST_METHOD} eq 'POST' ) {
        my $r_token = $req->param('csrf_token');
        my $session_token = $app->session->get('csrf_token');
        if ( !$r_token || !$session_token || ( $r_token ne $session_token ) ) {
            return 0;
        }
    }
    return 1;
}

sub generate_token {
    my @chars = ('A'..'Z', 'a'..'z', 0..9);
    my $ret;
    for (1..32) {
        $ret .= $chars[int rand @chars];
    }
    return $ret;
}

sub before_action {
    my ($env, $path_param, @chain_of_actions) = @_;
    my $opt = plugin_config();

    unless ($opt->{no_validate_hook}) {
        if (! validate_csrf()) {
            return [
                403,
                [
                    'Content-Type'   => 'text/html',
                    'Content-Length' => length($ERROR_HTML)
                ],
                [ $ERROR_HTML ],
            ];
        }
    }

    my $next = shift @chain_of_actions;
    $next->($env, $path_param, @chain_of_actions);
}

sub process_content {
    my $content = shift;
    my $opt = plugin_config();

    my $form_regexp = $opt->{post_only} ? qr{<form\s*.*?\s*method=['"]?post['"]?\s*.*?>}is : qr{<form\s*.*?>}is;

    if (defined $content) {
        $content =~ s!($form_regexp)!qq{$1\n<input type="hidden" name="csrf_token" value="}.get_csrf_defender_token().qq{" />}!ge;
    }

    return $content;
}

1;
__END__

=encoding utf8

=head1 NAME

Nephia::Plugin::CSRFDefender - CSRF Defender Plugin for Nephia

=head1 SYNOPSIS

    package MyApp.pm;
    use strict;
    use warnings;
    use Nephia plugins => [
        'PlackSession',
        'CSRFDefender'
    ];

=head1 DESCRIPTION

Nephia::Plugin::CSRFDefender denies CSRF request.

=head1 METHODS

=over 4

=item get_csrf_defender_token()

Get a CSRF defender token.

=item validate_csrf()

Validate CSRF token manually.

=back

=head1 SEE ALSO

L<Nephia>

L<Amon2::Plugin::Web::CSRFDefender>

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut
