package span;
use strict;

sub quote
	{
	my $in = \shift;
	my $pos = \shift;

	die if !defined $$pos;
	my $npos = $$pos;
	my $len = length($$in);
	my $out = "";

	while (1)
		{
		my $span = $len - $npos;
		$span = 0 if $span < 0;
		$span = 255 if $span > 255;

		$out .= chr($span);
		return $out if $span <= 0;

		$out .= substr($$in, $npos, $span);
		$npos += $span;
		}
	}

sub unquote
	{
	my $in = \shift;
	my $pos = \shift;

	die if !defined $$pos;
	my $npos = $$pos;
	my $len = length($$in);
	my $out = "";

	while (1)
		{
		last if $$pos >= $len;  # should not happen if well-formed
		my $span = ord(substr($$in,$npos,1));
		$npos += ($span + 1);
		last if $span == 0;
		$out .= substr($$in, $npos - $span, $span);
		}

	return $out;
	}

return 1;
