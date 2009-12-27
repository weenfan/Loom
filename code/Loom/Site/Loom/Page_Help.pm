package Loom::Site::Loom::Page_Help;
use strict;
use URI::Escape;

# LATER get rid of this module, integrating the text into the appropriate
# modules.

sub new
	{
	my $class = shift;
	my $site = shift;
	my $topic = shift;

	my $s = bless({},$class);
	$s->{site} = $site;
	$s->{topic} = $topic;
	return $s;
	}

sub respond
	{
	my $s = shift;

	my $site = $s->{site};
	$site->set_title("Advanced");

	my $topic = $s->{topic};

	if ($topic eq "index")
		{
		$s->page_help_index;
		return;
		}

	if ($topic eq "grid" || $topic eq "grid_tutorial")
		{
		$s->page_help_grid_tutorial;
		return;
		}

	if ($topic eq "archive" || $topic eq "archive_tutorial")
		{
		$s->page_help_archive_tutorial;
		return;
		}

	$site->{body} .= <<EOM;
<p>
No help is available on this topic.
EOM

	return;
	}

sub page_help_index
	{
	my $s = shift;

	my $site = $s->{site};

	$site->set_title("Advanced");

	push @{$site->{top_links}},
		$site->highlight_link(
			$site->url,
			"Home");

	my $op = $site->{op};
	my $topic = $op->get("topic");

	if ($topic eq "contact_info" || $topic eq "pgp")
		{
		push @{$site->{top_links}},
			$site->highlight_link(
				$site->url(help => 1, topic => "contact_info"),
				"Contact", $topic eq "contact_info");

		push @{$site->{top_links}}, "" if $topic eq "contact_info";

		push @{$site->{top_links}},
			$site->highlight_link(
				$site->url(help => 1, topic => "pgp"),
				"PGP", $topic eq "pgp");
		}
	else
		{
		push @{$site->{top_links}},
			$site->highlight_link(
				$site->url(help => 1),
				"Advanced", 1);

		my $link_grid_api = $site->highlight_link(
			$site->url(function => "grid_tutorial", help => 1),
			"Grid");

		my $link_archive_api = $site->highlight_link(
			$site->url(function => "archive_tutorial", help => 1),
			"Archive");

		my $link_cms = $site->highlight_link(
			$site->url(function => "edit"),
			"CMS");

		my $link_tools = $site->highlight_link(
			$site->url(function => "folder_tools"),
			"Tools");

		push @{$site->{top_links}}, "";
		push @{$site->{top_links}}, $link_grid_api;
		push @{$site->{top_links}}, $link_archive_api;
		push @{$site->{top_links}}, $link_cms;
		push @{$site->{top_links}}, $link_tools;
		}

	if ($topic eq "contact_info")
		{
		my $dsp_email = $s->get_email_support;

		$site->{body} .= <<EOM;
<h1>Contact Information</h1>
<p>
If you have any questions please send an email to $dsp_email.
EOM
		my $pgp_key = $site->archive_get(
			$site->{config}->get("support_pgp_key"));
		if (defined $pgp_key)
		{
		my $url = $site->url(help => 1, topic => "pgp");
		$site->{body} .= <<EOM;
We encourage you to send us an <a href="$url">encrypted email</a>
using PGP.
EOM
		}

		return;
		}

	if ($topic eq "pgp")
		{
		my $pgp_key = $site->archive_get(
			$site->{config}->get("support_pgp_key"));
		return if !defined $pgp_key;

		my $dsp_email = $s->get_email_support;

		$site->{body} .= <<EOM;
<h1>How to send us an encrypted email</h1>
<p>
Please end an email to $dsp_email encrypted to this PGP key:
<pre class=tiny_mono>
$pgp_key
</pre>
EOM
		return;
		}

	if ($topic eq "get_usage_tokens")
		{
		my $conf = $site->{config};
		my $loc = $conf->get("exchanger_page");
		my $page = $site->archive_get($loc);

		$site->{body} .= $page if defined $page;

		return;
		}

	my $link_grid_api = $site->highlight_link(
		$site->url(function => "grid_tutorial", help => 1),
		"Grid");

	my $link_archive_api = $site->highlight_link(
		$site->url(function => "archive_tutorial", help => 1),
		"Archive");

	my $link_cms = $site->highlight_link(
		$site->url(function => "edit"),
		"Content Management System");

	my $link_tools = $site->highlight_link(
		$site->url(function => "folder_tools"),
		"Tools");

	$site->{body} .= <<EOM;
<h1> Application Programming Interface (API) </h1>
<p>
The entire Loom system is built upon a very solid Application Programmer
Interface (API).  There are two primary APIs:
<ul>
<li> $link_grid_api
<li> $link_archive_api
</ul>

Those links also include a "Tutorial" which gives you
the chance to try out the API interactively.

<h1> Content Management System (CMS) </h1>
<p>
The $link_cms is a very basic system for managing documents in the
Loom Archive.  You can create, delete, edit, and upload data here, paying in
usage tokens.

<h1> Tools </h1>
We also have some $link_tools which do some computations with IDs and
passphrases.

EOM

	return;
	}

sub get_email_support
	{
	my $s = shift;

	my $site = $s->{site};

	my $conf = $site->{config};
	my $email_support = $conf->get("email_support");

	my @email_links = ();

	for my $email (split(" ",$email_support))
		{
		push @email_links, qq{<a href="mailto:$email">$email</a>};
		}

	my $result = join(" or ",@email_links);
	return $result;
	}

sub page_help_archive_tutorial
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<h1>Archive</h1>

<p>
The Archive function provides a general purpose data storage facility paid
with usage tokens.  You can Look at an archive entry by its hash, which lets
you read the content but not change it.  You can also Touch an entry directly
by its location, which lets you change the content with the Write operation.
Writing new content costs 1 usage token per 16 bytes of <em>encrypted</em>
data added to the database, or yields a 1 token refund per 16 bytes reduced.
(There can be a few bytes of overhead added in the encryption process.)

<p>
Before you can write an entry, you must first Buy its location for 1 usage
token.  This helps prevent accidentally writing to an incorrect location.
You may then write arbitrary content into the purchased location.  Later, if
you want to Sell the location back to receive a 1 token refund, you must first
clear it out by writing null content into it.

<p>
All content is encrypted in the database using a key derived from the archive
location.

EOM

	{
	my $loc = "c80481226973dfec6dc06c8dfe8a5b1c";
	my $usage = "29013fc66a653f6765151dd352675d0f";

	my $test_str = "first/line\nsecond/line\n";
	my $q_test_str = uri_escape($test_str);

	my $this_url = $site->{config}->get("this_url");

	$site->{body} .= <<EOM;
<h1>Example API Call</h1>
<p>
Here is a url which writes the string "abc" into archive location $loc,
paying for the storage from usage location $usage.  Note that in order
for this to work, you must have already bought the archive location.

<pre class=mono style='margin-left:20px'>
$this_url?function=archive&action=write
	&usage=$usage
	&loc=$loc
	&content=abc
</pre>

<p>
(The url is broken up across lines for clarity.  In practice you would keep
the entire url on a single line.)

<p>
You may use content with multiple lines or arbitrary binary characters.  All
you have to do is "uri_escape" the content to convert it into a form suitable
for use in a url.  (For you perl programmers, see the URI::Escape module.)
For example, this multi-line string:

<pre style='margin-left:20px'>
$test_str
</pre>

<p>
would be encoded by uri_escape as:

<pre style='margin-left:20px'>
$q_test_str
</pre>

<p>
For better support of very large content, there will soon be an API call which
is compatible with the HTTP "file upload" protocol.  But for now, the simple
"write" operation should suffice just fine for most purposes (even with large
content).
EOM

	$site->{body} .= <<EOM;
<h1>Archive Operations</h1>
<p>
Here we describe the API (application programming interface) for the Archive.
The operations are Buy, Sell, Touch, Look, and Write.

EOM

	$s->help_archive_buy_chapter;
	$s->help_archive_sell_chapter;
	$s->help_archive_touch_chapter;
	$s->help_archive_look_chapter;
	$s->help_archive_write_chapter;

	}

	}

sub help_archive_buy_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Buy</h1>
</div>

<p>
Buy a location in the archive.  This costs 1 usage token.  The location must
currently be vacant (not bought) in order to buy it.  The input is:
EOM
	{
	my $rows =
	[
	["function","archive",""],
	["action","buy","Name of operation"],
	["loc","<b>id</b>","Location to buy"],
	["usage","<b>id</b>","Location of usage tokens"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the Buy operation succeeds, you will see the following keys in the
result:
EOM

	{
	my $rows =
	[
	["status","success","Everything went well."],
	["cost","<b>qty</b>","Cost of operation"],
	["usage_balance","<b>qty</b>","New usage balance"],
	["hash","<b>hash</b>","Hash of location"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the operation fails, the status will be <em>fail</em>, and the
reason for the failure will be indicated with any keys below which
apply:
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error_loc","not_valid_id", "loc is not a valid id"],
	["error_loc","occupied", "loc is already occupied (bought)"],
	["content","<b>string</b>", "existing content at loc if occupied"],
	["error_usage","not_valid_id", "usage is not a valid id"],
	["error_usage","insufficent",
		"usage location did not have at least one usage token"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	}

sub help_archive_sell_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Sell</h1>
</div>

<p>
Sell a location in the archive.  This refunds 1 usage token.  The content
at the location must currently be empty (null) in order to sell the location.
The input is:
EOM
	{
	my $rows =
	[
	["function","archive",""],
	["action","sell","Name of operation"],
	["loc","<b>id</b>","Location to sell"],
	["usage","<b>id</b>","Location of usage tokens"],
	];


	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the Sell operation succeeds, you will see the following keys in the
result:
EOM

	{
	my $rows =
	[
	["status","success","Everything went well."],
	["cost","<b>qty</b>","Cost of operation (-1 meaning refund)"],
	["usage_balance","<b>qty</b>","New usage balance"],
	["hash","<b>hash</b>","Hash of location"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the operation fails, the status will be <em>fail</em>, and the
reason for the failure will be indicated with any keys below which
apply:
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error_loc","not_valid_id", "loc is not a valid id"],
	["error_loc","vacant", "loc is already vacant (sold)"],
	["error_loc","not_empty", "loc has non-empty content"],
	["content","<b>string</b>", "existing content at loc (if non-empty)"],
	["error_usage","not_valid_id", "usage is not a valid id"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	}

sub help_archive_touch_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Touch</h1>
</div>

<p>
Touch a location in the archive.  The input is:
EOM
	{
	my $rows =
	[
	["function","archive",""],
	["action","touch","Name of operation"],
	["loc","<b>id</b>","Location to touch"],
	];


	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the Touch operation succeeds, you will see the following keys in the
result:
EOM

	{
	my $rows =
	[
	["status","success","Everything went well."],
	["content","<b>string</b>","Content at archive location"],
	["hash","<b>hash</b>","Hash of location"],
	["content_hash","<b>hash</b>","Hash of content"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the operation fails, the status will be <em>fail</em>, and the
reason for the failure will be indicated with any keys below which
apply:
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error_loc","not_valid_id", "loc is not a valid id"],
	["error_loc","vacant", "loc is vacant (sold)"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	}

sub help_archive_look_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Look</h1>
</div>

<p>
Look at a location in the archive by its hash.  The input is:
EOM
	{
	my $rows =
	[
	["function","archive",""],
	["action","look","Name of operation"],
	["hash","<b>hash</b>","Hash of location to examine"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the Look operation succeeds, you will see the following keys in the
result:
EOM

	{
	my $rows =
	[
	["status","success","Everything went well."],
	["content","<b>string</b>","Content at hash of location"],
	["content_hash","<b>hash</b>","Hash of content"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the operation fails, the status will be <em>fail</em>, and the
reason for the failure will be indicated with any keys below which
apply:
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error_hash","not_valid_id", "hash is not a valid hash"],
	["error_loc","vacant", "loc is vacant (sold)"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	}

sub help_archive_write_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Write</h1>
</div>

<p>
Write content into the archive.  The system first encrypts the content using
a key derived from the location.  This may impose an overhead of a few bytes.
It then compares the new encrypted length with the length of any existing
content at this location, and determines how many bytes would be added or
subtracted <em>on net</em> if it were to write out the new content.  It then
charges 1 usage token per 16 bytes added, or refunds 1 usage token per 16 bytes
subtracted.
<p>
The input is:
EOM
	{
	my $rows =
	[
	["function","archive",""],
	["action","write","Name of operation"],
	["loc","<b>id</b>","Location to write"],
	["content","<b>id</b>","Content to write into that location"],
	["usage","<b>id</b>","Location of usage tokens"],
	["guard","<b>hash</b>",
		"Optional SHA256 hash of previous content to guard against "
		."overlapping writes"
		],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the Write operation succeeds, you will see the following keys in the
result:
EOM

	{
	my $rows =
	[
	["status","success","Everything went well."],
	["cost","<b>qty</b>","Cost of operation"],
	["usage_balance","<b>qty</b>","New usage balance"],
	["hash","<b>hash</b>","Hash of location"],
	["content_hash","<b>hash</b>","Hash of content"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table

<p>
<b>NOTE:</b> the "content" key supplied in the input is <em>not</em> echoed
back in the result, because that would just be a waste of time and bandwidth.
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the operation fails, the status will be <em>fail</em>, and the
reason for the failure will be indicated with any keys below which
apply:
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error_loc","not_valid_id", "loc is not a valid id"],
	["error_loc","vacant", "loc is vacant (sold)"],
	["error_usage","not_valid_id", "usage is not a valid id"],
	["error_usage","insufficent",
		"usage location is vacant or did not have enough usage tokens "
		."to cover the cost"
		],
	["error_guard","not_valid_hash",
		"guard was specified and is not a valid hash"],
	["error_guard","changed",
		"The hash of the previous content did not match the specified"
		." guard, so the new content was not written.  Essentially this "
		."means that the content changed \"under our feet\" since the "
		."last time we looked at it, so we don't clobber those changes."
		],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	}

# LATER emphasize that a "location" is really a column in the grid,
# and that a "cell" is a specific intersection of type and location.
# So you're buying and selling cells really.

sub page_help_grid_tutorial
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<h1>Grid</h1>
<p>
The Grid function is the core operation in the entire Loom system.  The
primary function of the Grid is to regulate usage of various limited
resources.  One of those limited resources is the disk space used by the
Grid itself!  Consequently you must pay one usage token to buy a grid
location.  If you sell a grid location back to the system, you receive a
refund of one usage token.
<p>
The Grid administrator possesses the issuing location for usage tokens,
and can thus regulate the supply of those tokens based on supply and
demand for Grid resources.

<h1>Grid Terminology</h1>

<p>
An <em>id</em> is a 128-bit number expressed as a hexadecimal string,
All hexadecimal strings must use lower-case letters 'a'-'f', not the
upper-case letters 'A'-'F'.
Example:
<p class=mono style='margin-left:20px'>
3a4511c895fc71fdfea08f3f3f8c7a97
</p>

<p>
A <em>hash</em> is a 256-bit number expressed as a hexadecimal string.
Example:
<p class=mono style='margin-left:20px'>
6486b8158425d380642a444f5b2047fd97e452f7c92eaa8d8a7d2c53516d4a69
</p>

<p>
A <em>quantity</em> is a signed integer value with 128 bits of precision,
expressed in decimal notation.  The largest positive value is:
<p class=mono style='margin-left:20px'>
170141183460469231731687303715884105727
</p>

<p>
The smallest negative value is:
<p class=mono style='margin-left:20px'>
-170141183460469231731687303715884105728
</p>

<p>
A <em>type</em> is an id which represents a distinct "asset type."
These asset types may be created at will for various purposes.  There
is one special-purpose asset type which represents usage tokens, the
zero type:

<p class=mono style='margin-left:20px'>
00000000000000000000000000000000
</p>

<p>
A <em>location</em> is an id which represents a distinct "place"
<em>within</em> a given asset type, where units of that asset type
may be stored.

<p>
You may think of the <em>grid</em> as a whole as a giant 2-dimensional
array.  The rows and columns of this array are numbered from 0 to 2^128-1.
Inside each cell of this array is a signed 128-bit integer quantity
(a 2's-complement number).

<div style='margin-left:20px'>
<h2>The Grid</h2>

<table border=1 cellpadding=2 style='border-collapse:collapse'>
<colgroup>
<col width=80>
<col width=80>
<col width=80>
<col width=80>
<col width=80>
</colgroup>

<tr>
<td class=mono align=center>
Row/Col
</td>
<td class=mono align=center> 0 </td>
<td class=mono align=center> 1 </td>
<td class=mono align=center> ... </td>
<td class=mono align=center> 2^128-1 </td>

</tr>

<tr>
<td class=mono align=center> 0 </td>
<td class=mono align=center> </td>
<td class=mono align=center> </td>
<td class=mono align=center> </td>
</tr>
<tr>
<td class=mono align=center> 1 </td>
<td class=mono align=center> </td>
<td class=mono align=center> </td>
<td class=mono align=center> </td>
</tr>
<tr>
<td class=mono align=center> ... </td>
<td class=mono align=center> </td>
<td class=mono align=center> </td>
<td class=mono align=center> </td>
</tr>
<tr>
<td class=mono align=center> 2^128-1 </td>
<td class=mono align=center> </td>
<td class=mono align=center> </td>
<td class=mono align=center> </td>
</tr>
</table>

</div>

<p>
Within each row (asset type) there is always exactly one location with a
negative value.  Initially there is a -1 at location 0 of every row.
The negative location within a row is known as the <em>issuer location</em>
for that row.  The issuer location is the only place from which new units
of the asset type can be created.  Within every other location in a row,
the value is either 0 or positive.

<p>
The grid operations maintain <b>conservation of value</b>.
The sum of the values within each row is always precisely -1.

<p>
To "create" a new asset type, you simply choose a row at random and move
the issuer location from its original place at location 0 to some other
random location you choose.  Now you control that asset type entirely,
since you are the only entity which knows the issuer location for that
type.  You can issue units at will (at most 2^128-1 of them) and move
them anywhere you like.

<p>
The grid therefore acts somewhat like a giant spreadsheet, albeit with
some very restricted arithmetic properties.  The grid is nothing more
than a very solid and well-defined counting mechanism.

<p>
The beauty of the grid concept is that it allows us to build a web site
starting from nothing but an empty grid, and then construct all sorts
of content management applications from there, where the usage of limited
resources such as disk space is strictly regulated and throttled by the
numbers in the grid.  For example, if we decided to provide a feature to
upload pictures for safekeeping, the web site could charge a certain number
of usage tokens per kilobyte of data uploaded.

<p>
If you don't do things this way, with some form of economic regulation,
then a web site can become a giant "tragedy of the commons" with no sensible
limits on usage.  The traditional way most sites deal with this is to
create a revenue model based on advertising.  Perhaps the Loom method is a
refreshing way for users to avoid all the ads, and providers to have a
new revenue model.
EOM

	{
	my $type = "0f8fccf7c65e42d422c37ea222e700d5";
	my $qty  = 42500;
	my $orig = "c80481226973dfec6dc06c8dfe8a5b1c";
	my $dest = "29013fc66a653f6765151dd352675d0f";

	my $this_url = $site->{config}->get("this_url");

	$site->{body} .= <<EOM;
<h1>Example API Call</h1>
<p>
Here is a url which executes a "Move" operation, moving 42500 units
of type $type from the origin location
$orig to the destination location $dest.

<pre class=mono style='margin-left:20px'>
$this_url?function=grid&action=move
	&type=$type
	&qty=$qty
	&orig=$orig
	&dest=$dest
</pre>

<p>
(The url is broken up across lines for clarity.  In practice you would keep
the entire url on a single line.)
<p>
When the API receives this GET operation from the internet, it translates the
information into an internal key-value structure for easy access.  It then
executes the operation, which has the effect of filling out additional keys
and values in the key-value structure.  Then it sends the results back to the
caller as a plain-text document, with the resulting key-value structure
expressed in our simple standard "KV" format.
<p>
For example, after the url above is translated and executed, the API will
send the result back to the caller like this:
<pre class=mono style='margin-left:20px'>
Content-type: text/plain

(
:function
=grid
:action
=move
:type
=$type
:qty
=$qty
:orig
=$orig
:dest
=$dest
:status
=success
:value_orig
=0
:value_dest
=42500
)
</pre>
EOM
	}

	$site->{body} .= <<EOM;
<h1>Grid Operations</h1>
<p>
Here we describe the API (application programming interface) for the Grid.
The operations are Buy, Sell, Issuer, Touch, Look, and Move.

EOM

	$s->help_grid_buy_chapter;
	$s->help_grid_sell_chapter;
	$s->help_grid_issuer_chapter;
	$s->help_grid_touch_chapter;
	$s->help_grid_look_chapter;
	$s->help_grid_move_chapter;
	$s->help_grid_scan_chapter;
	}

sub help_grid_buy_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Buy</h1>
</div>

<p>
Buy a location in the grid.  This costs one usage token.
The input is:
EOM
	{
	my $rows =
	[
	["function","grid",""],
	["action","buy","Name of operation"],
	["type","<b>id</b>","Asset type"],
	["loc","<b>id</b>","Location to buy"],
	["usage","<b>id</b>","Location of usage tokens (where 1 is charged)"],
	];


	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the Buy operation succeeds, you will see the following keys in the
result:
EOM

	{
	my $rows =
	[
	["status","success","Everything went well."],
	["value","<b>qty</b>",
		"The value at the new location.  This will typically be 0,"
		." unless you are buying the location 0 for a brand new type, "
		." in which case it will be -1."
		],
	["usage_balance","<b>qty</b>", "New usage balance"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the operation fails, the status will be <em>fail</em>, and the
reason for the failure will be indicated with any keys below which
apply:
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error_type","not_valid_id", "type is not a valid id"],
	["error_loc","not_valid_id", "loc is not a valid id"],
	["error_usage","not_valid_id", "usage is not a valid id"],
	["error_loc","occupied", "loc is already occupied (bought)"],
	["error_usage","insufficent",
		"usage location did not have at least one usage token"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	}

sub help_grid_sell_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Sell</h1>
</div>

<p>
Sell a location in the grid.  This refunds one usage token.
The input is:
EOM
	{
	my $rows =
	[
	["function","grid",""],
	["action","sell","Name of operation"],
	["type","<b>id</b>","Asset type"],
	["loc","<b>id</b>","Location to sell"],
	["usage","<b>id</b>","Location of usage tokens (where 1 is refunded)"],
	];


	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the Sell operation succeeds, you will see the following keys in the
result:
EOM

	{
	my $rows =
	[
	["status","success","Everything went well."],
	["value","<b>qty</b>",
		"The value at the location.  You can only sell a location that"
		." is <em>empty</em>: either a 0 value in a non-zero location,"
		." or a -1 value in a zero location.  These are the values which"
		." can be safely deleted from the database without losing any"
		." information."
		],
	["usage_balance","<b>qty</b>", "New usage balance"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the operation fails, the status will be <em>fail</em>, and the
reason for the failure will be indicated with any keys below which
apply:
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error_type","not_valid_id", "type is not a valid id"],
	["error_loc","not_valid_id", "loc is not a valid id"],
	["error_usage","not_valid_id", "usage is not a valid id"],
	["error_loc","vacant", "loc is already vacant (sold)"],
	["error_loc","non_empty", "loc is not empty"],
	["error_loc","cannot_refund",
	"Cannot sell a usage token location and receive the refund in same place."],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	}

sub help_grid_issuer_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Issuer</h1>
</div>

<p>
Change the issuer location for an asset type.
The input is:
EOM
	{
	my $rows =
	[
	["function","grid",""],
	["action","issuer","Name of operation"],
	["type","<b>id</b>","Asset type"],
	["orig","<b>id</b>","Current issuer location"],
	["dest","<b>id</b>","New issuer location"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the Issuer operation succeeds, you will see the following keys in the
result:
EOM

	{
	my $rows =
	[
	["status","success","Everything went well."],
	["value_orig","<b>qty</b>","Value of original location (after the change)"],
	["value_dest","<b>qty</b>","Value of destination location"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the operation fails, the status will be <em>fail</em>, and the
reason for the failure will be indicated with any keys below which
apply:
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error_type","not_valid_id", "type is not a valid id"],
	["error_orig","not_valid_id", "orig is not a valid id"],
	["error_dest","not_valid_id", "dest is not a valid id"],
	["error_qty","insufficient", "insufficient value at orig/dest "
		."(or other error listed below)"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM

	$site->{body} .= <<EOM;
<p>
The operation must obey the following rules (otherwise you'll see
error_qty = insufficient):
<ul>
<li> orig and dest are distinct (i.e. locations are not identical)
<li> orig and dest exist (i.e. the locations have been previously bought).
<li> orig value is negative (i.e. the issuer location).
<li> dest value is zero (so you aren't clobbering an existing value).
</ul>
EOM
	}

	}

sub help_grid_touch_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Touch</h1>
</div>

<p>
Examine a location directly, seeing the value stored there.

<p>
(Note that there is another operation called "Look" which examines a location
<em>indirectly</em> using a hash, e.g. for audit purposes.  See below.)

<p>
The input for the Touch operation is:
EOM
	{
	my $rows =
	[
	["function","grid",""],
	["action","touch","Name of operation"],
	["type","<b>id</b>","Asset type"],
	["loc","<b>id</b>","Location"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the Touch operation succeeds, you will see the following keys in the
result:
EOM

	{
	my $rows =
	[
	["status","success","Everything went well."],
	["value","<b>qty</b>","Value at location"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the operation fails, the status will be <em>fail</em>, and the
reason for the failure will be indicated with any keys below which
apply:
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error_type","not_valid_id", "type is not a valid id"],
	["error_loc","not_valid_id", "loc is not a valid id"],
	["error_loc","vacant", "loc is vacant (not yet bought)"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	}

sub help_grid_look_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Look</h1>
</div>

<p>
Examine a location indirectly, seeing the value stored there.

<p>
The Look operation examines a location <em>indirectly</em> using a hash.
Using the hash, one may <em>view</em> the contents of a location without
the ability to change them.

<p>
For example, you could safely divulge the hash of a location to another party
for audit purposes.  This would give the auditor the ability to monitor the
location, but not to change it in any way.  If all you have is the
hash of a location, then you can Look but you can't Touch.

<p>
The input for the Look operation is:
EOM
	{
	my $rows =
	[
	["function","grid",""],
	["action","look","Name of operation"],
	["type","<b>id</b>","Asset type"],
	["hash","<b>hash</b>","Hash of location to examine"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the Look operation succeeds, you will see the following keys in the
result:
EOM

	{
	my $rows =
	[
	["status","success","Everything went well."],
	["value","<b>qty</b>","Value at location"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the operation fails, the status will be <em>fail</em>, and the
reason for the failure will be indicated with any keys below which
apply:
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error_type","not_valid_id", "type is not a valid id"],
	["error_hash","not_valid_hash", "hash is not a valid hash"],
	["error_loc","vacant", "location is vacant (not yet bought)"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	}

sub help_grid_move_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Move</h1>
</div>

<p>
Move units of a given type from one location to another.

<p>
The input for the Move operation is:
EOM
	{
	my $rows =
	[
	["function","grid",""],
	["action","move","Name of operation"],
	["type","<b>id</b>","Asset type"],
	["qty","<b>qty</b>","Number of units to move"],
	["orig","<b>id</b>","Origin location (subtract qty from here)"],
	["dest","<b>id</b>","Destination location (add qty to here)"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
<p>
The quantity is normally positive, but a negative or zero value is also
allowed.
<p>
The Loom system first tries subtracting the qty from the origin and adding
it to the destination.  If the sign (+/-) of both the origin and destination
remain <em>unchanged</em>, then the operation succeeds and the database is
updated.  Otherwise, if either sign changes, the operation fails and the
database is unaffected.
<p>
In short, if both locations were positive or zero <em>before</em> the
move, then they must remain so <em>after</em> the move.
<p>
Now consider the case where one of the locations is negative.  That location
is the privileged issuer location for the asset type, and in this case the
move operation is either creating or destroying units of the asset type.
<p>
If the issuer location becomes <em>more</em> negative, units are being created
at the other location.  If the issuer location becomes <em>less</em> negative,
units are being destroyed at the other location.  The same rule applies here
as well:  if a location is negative before the move, it must remain negative
after the move as well.
<p>
This simple rule, called <b>sign preservation</b>, enforces the principle
of conservation of value within the Loom grid.  Note also that this rule
ensures that there can be only one issuer location (negative value) for
a given type.  This rule also prevents the negative value from moving
elsewhere during a move.  If you wish to move the issuer location, you
must use the Issuer operation (see above).
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the Move operation succeeds, you will see the following keys in the
result:
EOM

	{
	my $rows =
	[
	["status","success","Everything went well."],
	["value_orig","<b>qty</b>","New value at origin"],
	["value_dest","<b>qty</b>","New value at destination"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	$site->{body} .= <<EOM;
<p>
If the operation fails, the status will be <em>fail</em>, and the
reason for the failure will be indicated with any keys below which
apply:
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error_type","not_valid_id", "type is not a valid id"],
	["error_orig","not_valid_id", "orig is not a valid id"],
	["error_dest","not_valid_id", "dest is not a valid id"],
	["error_qty","not_valid_int", "qty is not a valid integer value"],
	["error_qty","insufficient", "insufficient value at orig/dest "
		."(or other error listed below)"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table

<p>
Note that if the orig or destination is vacant (not bought), then the
corresponding value_orig or value_dest will have a null value in the result.
(Because null values are not actually stored, the value will simply be
<em>missing</em>.)
<p>
The operation must obey the following rules (otherwise you'll see
error_qty = insufficient):
<ul>
<li> orig and dest are distinct (i.e. locations are not identical)
<li> orig and dest exist (i.e. the locations have been previously bought).
<li> the signs (+/-) of both location values remain unchanged in the move.
</ul>
EOM
	}

	}

sub help_grid_scan_chapter
	{
	my $s = shift;

	my $site = $s->{site};

	$site->{body} .= <<EOM;
<div class=color_heading>
<h1>Scan</h1>
</div>

<p>
Scan an entire set of locations and types in one operation.

<p>
The input for the Scan operation is:
EOM
	{
	my $rows =
	[
	["function","grid",""],
	["action","scan","Name of operation"],
	["locs","list of <b>id</b> or <b>hash</b>","Space-separated list of locations and/or hashes"],
	["types","list of <b>id</b>","Space-separated list of types"],
	["zeroes","<b>flag</b>", "Option to force the scan to return 0-values"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
<p>
The Scan operation combines all the specified locs and types together, forming
all possible pairs, and returns the value associated with each pair.  It uses
Touch for locations and Look for hashes.
<p>
Normally Scan does not return any 0 values it finds, but you can force it to
do so by setting the "zeroes" flag to "1".  Otherwise you can simply omit that
flag altogether.
EOM
	}

	$site->{body} .= <<EOM;
<p>
For each location <b>L</b> in the locs list, the output will contain this
entry:
EOM

	{
	my $rows =
	[
	["loc/<b>L</b>","list of <b>qty:id</b>","Space-separated list of value:type pairs"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table

<p>
Note that if a location <b>L</b> is <em>completely empty</em> for all specified
types, the "loc/<b>L</b>" entry will also be empty, i.e. the null string.
Because the output does not list entries which have null values, you will
not see an entry at all for any completely empty location.
<h3>Example (specified in "KV" key-value format):</h3>
<pre class=mono style='margin-left:20px'>
(
:function
=grid
:action
=scan
:locs
=cf432b0acbaa7065a852cdda9e68f4c2 7ec5db6c103d6c0ebf2110abbd01e9ab 06d384fafd07b729f2990ffdb2786e68
:types
=e420516d14dd97358c44a2be37e6a403 8610c5a529e57981f189189cd9e3158d
)
</pre>
<p>
When you submit that request to the API, it will come back to you looking
something like this:
<pre class=mono style='margin-left:20px'>
(
:function
=grid
:action
=scan
:locs
=cf432b0acbaa7065a852cdda9e68f4c2 7ec5db6c103d6c0ebf2110abbd01e9ab 06d384fafd07b729f2990ffdb2786e68
:types
=e420516d14dd97358c44a2be37e6a403 8610c5a529e57981f189189cd9e3158d
:loc/cf432b0acbaa7065a852cdda9e68f4c2
=99804428:8610c5a529e57981f189189cd9e3158d
:loc/06d384fafd07b729f2990ffdb2786e68
=14556348000:e420516d14dd97358c44a2be37e6a403 39450540000:8610c5a529e57981f189189cd9e3158d
)
</pre>
<p>
From this result we can determine that:
<ul>
<li> Location 1 has 99804428 units of type 2.
<li> Location 2 is completely empty, with no units of either type 1 or 2.
<li> Location 3 has 14556348000 units of type 1, and 39450540000 units of type 2.
</ul>
EOM
	}

	$site->{body} .= <<EOM;
<p>
<h2>NOTE:</h2>
The Scan operation will scan at most 2048 pairs.  This is a <b>hard limit</b>
which cannot be circumvented.  If you specify a list of locations and types
which combine to form more than 2048 pairs, Scan will return the results only
for the first 2048 pairs, and set error flags in the output as follows:
<p>
EOM

	{
	my $rows =
	[
	["status","fail","Something went wrong."],
	["error","excessive", "tried to scan too many pairs"],
	["error_max","2048", "maximum allowed scan size"],
	];

	my $table = $s->help_context_table($rows);
	$site->{body} .= <<EOM;

$table
EOM
	}

	}

# Note that this routine deliberately does not quote the keys and values.

sub help_context_table
	{
	my $s = shift;
	my $rows = shift;

	my $table = "";

	$table .= <<EOM;
<div style='margin-left:20px'>
<table border=1 style='border-collapse:collapse'>
<colgroup>
<col width=120>
<col width=100>
<col width=500>
</colgroup>
<tr>
<th align=left>Key</th>
<th align=left>Value</th>
<th align=left>Description</th>
</tr>
EOM

	for my $entry (@$rows)
		{
		my ($key,$val,$desc) = @$entry;

		$table .= <<EOM;
<tr>
<td>$key</td>
<td>$val</td>
<td>$desc</td>
</tr>
EOM
		}

	$table .= <<EOM;
</table>
</div>
EOM

	return $table;
	}

return 1;

__END__

# Copyright 2007 Patrick Chkoreff
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions
# and limitations under the License.
