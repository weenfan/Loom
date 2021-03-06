package sloop_client;
use strict;
use archive;
use context;
use dttm;
use file;
use html;
use http;
use loom_config;
use notify;
use page;
use page_archive_api;
use page_archive_tutorial;
use page_data;
use page_edit;
use page_folder;
use page_grid_api;
use page_grid_tutorial;
use page_help;
use page_test;
use page_tool;
use page_trade;
use page_view;
use page_wallet;
use random;
use sloop_io;
use sloop_top;
use trans;

# LATER 20100325 Do a local install of all the prerequisite Perl modules.

# LATER 031810 make the entire server completely self-configuring upon
# installation.

# LATER 20110313 Even though Perl closes abandoned file handles automatically,
# let's put in code to close them explicitly, and include a counter of open
# files which must be zero at key places during the program run.

# LATER minimize coupling on these

my $g_transaction_in_progress;

# The transactional API is:
#
#    /trans/begin
#    /trans/commit
#    /trans/cancel
#
# This returns results in KV format.
#
# You can also do transactions interactively, in HTML, by using "trans_web"
# instead of "trans".

sub page_trans_respond
	{
	my @path = http::split_path(http::path());
	my $format = shift @path;

	die if $format ne "trans" && $format ne "trans_web";

	my $action = shift @path;
	$action = "" if !defined $action;

	my $api = context::new();
	context::put($api,"action",$action);

	if ($action eq "begin")
		{
		context::put($api,"status",$g_transaction_in_progress ? "fail" : "success");
		$g_transaction_in_progress = 1;
		}
	elsif ($action eq "commit")
		{
		my $ok = trans::commit();
		context::put($api,"status", $ok ? "success" : "fail");
		$g_transaction_in_progress = 0;
		}
	elsif ($action eq "cancel")
		{
		context::put($api,"status","success");
		trans::cancel();
		$g_transaction_in_progress = 0;
		}
	else
		{
		context::put($api,"status","fail");
		context::put($api,"error_action","unknown");
		}

	if ($format eq "trans")
		{
		# Return result in KV format.
		my $response_code = "200 OK";
		my $headers = "Content-Type: text/plain\n";
		my $text = context::write_kv($api);
		page::format_HTTP_response($response_code,$headers,$text);
		}
	elsif ($format eq "trans_web")
		{
		# Return result in HTML format.

		my $action = context::get($api,"action");
		my $status = context::get($api,"status");

		if ($action eq "begin")
			{
			page::set_title("Transaction");

			page::emit(<<EOM
<h1> Transaction in Progress </h1>
EOM
);
			page::emit(<<EOM
<p>
You have started a new transaction.
EOM
) if $status eq "success";
			page::emit(<<EOM
<p>
You already have a transaction in progress.
EOM
) if $status eq "fail";
			page::emit(<<EOM
<p>
Now you can now go off and do any series of operations you like.  Use the link
below if you'd like to start fresh.  Or, if you already have a window or tab
open, you can go there and do the operations.

<p style='margin-left:20px'>
<a href="/" target=_new> Visit Home page in a new window. </a>
<p>
When you're done, come back to this window and either commit or cancel the
transaction.
<p style='margin-left:20px; margin-top:30px;'>
<a href="/trans_web/commit"> Commit the transaction (save all changes). </a>
<p style='margin-left:20px; margin-top:30px;'>
<a href="/trans_web/cancel"> Cancel the transaction (discard all changes). </a>
EOM
);
			}
		elsif ($action eq "commit")
			{
			if ($status eq "success")
			{
			page::emit(<<EOM
<h1> Transaction Committed </h1>
<p>
The transaction was committed successfully.
EOM
);
			}
			else
			{
			page::emit(<<EOM
<h1> Transaction Failed </h1>
<p>
It was not possible to commit the transaction because some other process made
some changes while the transaction was in progress.  Perhaps someone else is
changing this same data from another web browser.
EOM
);
			}

			}
		elsif ($action eq "cancel")
			{
			page::emit(<<EOM
<h1> Transaction Canceled </h1>
<p>
The transaction has been canceled.
EOM
);
			}

		if ($action eq "commit" || $action eq "cancel")
			{
			page::emit(<<EOM
<p style='margin-left:20px'>
<a href="/trans_web/begin"> Start a new transaction. </a>
<p style='margin-left:20px'>
<a href="/"> Return to Home page. </a>
EOM
);
			}
		}

	return;
	}

sub showing_maintenance_page
	{
	return 0 if !notify::in_maintenance_mode();

	http::put("error_system","maintenance");

	my $system_name = loom_config::get("system_name");

	my $page = <<EOM;
Content-Type: text/html

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML><HEAD>
<TITLE>503 Service Unavailable</TITLE>
</HEAD><BODY>
<H1>Service Unavailable</H1>
$system_name is currently down for maintenance.
</BODY></HTML>
EOM

	page::ok($page);
	return 1;
	}

sub interpret_archive_slot
	{
	my $id = shift;

	my $content = archive::get($id);
	my ($header_op,$header_text,$payload) = page::split_content($content);

	my $content_type = context::get($header_op,"Content-Type");
	$content_type = context::get($header_op,"Content-type")
		if $content_type eq "";

	if ($content_type eq "standard-page")
		{
		my $title = context::get($header_op,"Title");
		page::set_title($title);
		page::emit($payload);

		page::top_link(page::highlight_link(html::top_url(), "Home"));

		page::top_link(page::highlight_link(
			http::path(),
			page::get_title(),1));
		}
	elsif ($content_type eq "loom-trade-page")
		{
		page_trade::respond($id,$header_op,$payload);
		}
	else
		{
		page::not_found();
		}
	}

# LATER: Normalize the internal redirect mechanism as well, or make it
# unnecessary.

sub loom_dispatch
	{
	page::clear();

	return if showing_maintenance_page();

	# LATER 1205 Adapt to mobile devices by looking at the User-Agent header.
	# For example when coming from iPhone we see something like this:
	#
	#   Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_1 like Mac OS X; en-us)
	#   AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8B117
	#   Safari/6531.22.7
	#
	# But when coming from an ordinary browser we might see:
	#
	#   Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.12)
	#   Gecko/20101027
	#   Ubuntu/10.04 (lucid)
	#   Firefox/3.6.12
	#{
	#my $user_agent = http::header("User-Agent");
	#print STDERR "user_agent=$user_agent\n";
	#}

	# Internally resolve any defined paths.

	my $resolved = 0;
	my $counter = 0;

	my $path = http::path();

	while (!$resolved)
	{
	$resolved = 1;
	$counter++;

	last if $counter > 16;  # impose max 16 redirects

	my @path = http::split_path($path);
	my $function = shift @path;

	if (!defined $function)
		{
		}
	elsif ($function eq "view")
		{
		# We allow paths like these:
		#
		#   /view/$hash
		#   /view/$hash.tar.gz
		#   /view/$hash/lib.tar.gz
		#
		# The suffix is useful for telling the browser what type of document
		# this is and a suggested name for saving it.

		my $hash = shift @path;

		if (!defined $hash)
			{
			page::not_found();
			return;
			}

		if ($hash =~ /^([^.]*)\.(.*)$/)
			{
			my $prefix = $1;
			my $suffix = $2;  # ignore suffix

			$hash = $prefix;
			}

		http::put("function",$function);
		http::put("hash",$hash);
		}
	elsif ($function eq "cache")
		{
		# Allow cache control with a path like this:
		#    /cache/3600/$path
		#
		# Note that we use urls like /cache/7200/data/style.css

		my $time = shift @path;
		if (!defined $time || $time !~ /^\d{1,8}$/)
			{
			page::not_found();
			return;
			}

		page::set_cache_time($time);

		$path = join("/",@path);
		$resolved = 0;
		}
	elsif ($function eq "data")
		{
		my $name = shift @path;

		if (!defined $name)
			{
			page::not_found();
			return;
			}

		http::put("function",$function);
		http::put("name",$name);
		}
	else
		{
		# LATER this is the only case where you can get infinite loops.
		# All we have to do is reduce the alias to a form which is
		# resolved *outside* of this loop, down below.  That is, the
		# alias is just a single mapping operation.
		#
		# We currently use this for favicon.ico and nav_logo.

		my $alias = loom_config::get("alias/$function");

		if ($alias ne "")
			{
			$path = $alias;
			$resolved = 0;
			}
		else
			{
			# If we don't find an alias for this leg of the path, just put it
			# in the "function" key and drop into the normal processing below.
			#
			# LATER: we could implement full positional notation for all
			# functions, besides just the few we've done.

			http::put("function",$function);
			}
		}
	}

	my $name = http::get("function");

	if ($name eq "folder" || $name eq "contact" || $name eq "asset"
		|| $name eq "")
		{
		page_folder::respond();
		}
	elsif ($name eq "grid")
		{
		page_grid_api::respond();
		}
	elsif ($name eq "archive")
		{
		page_archive_api::respond();
		}
	elsif ($name eq "trans" || $name eq "trans_web")
		{
		page_trans_respond();
		}
	elsif ($name eq "view")
		{
		page_view::respond();
		}
	elsif ($name eq "edit" || $name eq "upload")
		{
		page_edit::respond();
		}
	elsif ($name eq "data")
		{
		page_data::respond();
		}
	elsif ($name eq "folder_tools")
		{
		page_tool::respond();
		}
	elsif ($name eq "archive_tutorial")
		{
		page_archive_tutorial::respond();
		}
	elsif ($name eq "grid_tutorial")
		{
		page_grid_tutorial::respond();
		}
	elsif ($name eq "test")
		{
		page_test::respond();
		}
	elsif ($name eq "random")
		{
		my $id = random::hex();

		my $api = context::new();
		context::put($api,"function",$name);
		context::put($api,"value",$id);

		my $response_code = "200 OK";
		my $headers = "Content-Type: text/plain\n";
		my $result = context::write_kv($api);

		page::format_HTTP_response($response_code,$headers,$result);
		}
	elsif ($name eq "hash")
		{
		my $api = context::new();
		context::put($api,"function",$name);

		my $input = http::get("input");

		my $hash = sha256::bin($input);
		my $id = substr($hash,0,16) ^ substr($hash,16,16);
		$id = unpack("H*",$id);

		context::put($api,"input",$input);
		context::put($api,"sha256_hash",unpack("H*",$hash));
		context::put($api,"folded_hash",$id);

		my $response_code = "200 OK";
		my $headers = "Content-Type: text/plain\n";
		my $result = context::write_kv($api);

		page::format_HTTP_response($response_code,$headers,$result);
		}
	elsif ($name eq "object")
		{
		my @path = http::split_path($path);
		shift @path;
		my $id = shift @path;
		interpret_archive_slot($id);
		}
	elsif ($name eq "jpg")
		{
		my @path = http::split_path($path);
		shift @path;
		my $file = shift @path;
		my $result = file::get_by_name(sloop_top::dir(),"data/".$file);
		my $response_code = "200 OK";
		my $headers = "Content-Type: image/jpg\n";
		page::format_HTTP_response($response_code,$headers,$result);
		}
	elsif ($name eq "png")
		{
		my @path = http::split_path($path);
		shift @path;
		my $file = shift @path;
		my $result = file::get_by_name(sloop_top::dir(),"data/".$file);
		my $response_code = "200 OK";
		my $headers = "Content-Type: image/png\n";
		page::format_HTTP_response($response_code,$headers,$result);
		}
	else
		{
		my $id = loom_config::get("link/$name");
		if ($id eq "")
			{
			page::not_found();
			}
		else
			{
			interpret_archive_slot($id);
			}
		}

	return;
	}

sub transaction_too_large
	{
	my $page = <<EOM;
Content-Type: text/html

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
<head> <title>413 Transaction Too Large</title> </head>
<body>
<h1>Transaction Too Large</h1>
Your request was too large for the server to store in memory safely.
</body>
</html>
EOM

	page::HTTP("413 Request Entity Too Large", $page);
	trans::cancel();
	$g_transaction_in_progress = 0;
	sloop_io::disconnect();
	return;
	}

sub transaction_conflict
	{
	my $page = <<EOM;
Content-Type: text/html

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
<head> <title>409 Transaction Conflict</title> </head>
<body>
<h1>Transaction Conflict</h1>
Your request was trying to modify data while too many other processes were also
modifying that same data.  We had to give up, but you can try again later.
</body>
</html>
EOM

	page::HTTP("409 Conflict", $page);
	trans::cancel();
	$g_transaction_in_progress = 0;
	sloop_io::disconnect();
	return;
	}

# This routine handles the entire interaction with a single client process from
# start to finish.
#
# The database provides simple "get" and "put" routines only.  This allows the
# core logic of the system to behave as if it has exclusive control of a simple
# key-value data store, with no other processes changing values "under its
# feet" so to speak.
#
# We can maintain that illusion because, after the core logic is complete, we
# commit the database changes with the robust "parallel update" routine
# (file::update).  If the commit succeeds, it means that all the values we
# originally read from the file system remained untouched by other processes
# while we were deciding what changes to make, and all of our changes were
# successfully written with proper locking to ensure data integrity and avoid
# deadlock.
#
# If the commit fails, it means that at least one value changed under our feet
# while we were deciding what changes to make.  In that case we loop around and
# run the original query over again as if nothing had happened.  We keep doing
# this until the commit finally succeeds, which the laws of probability
# guarantee will happen eventually, even in a very busy system with several
# processes trying to update the same things.  See the "test_file" program
# for a very thorough stress test of this principle.

sub respond
	{
	# Initialize the transaction.

	my $dir = file::child(sloop_top::dir(),"data/app");
	file::restrict($dir);

	trans::start($dir);

	# Flag which tracks if this client process is doing an ACID transaction.
	# (Atomicity, Consistency, Isolation, Durability)

	$g_transaction_in_progress = 0;

	# This loop reads successive HTTP messages from the client and sends
	# responses, possibly altering the DB in the process.

	while (1)
		{
		# First clear the HTTP input buffer so it will read more bytes from
		# the client.

		http::clear();

		# This next inner loop reads the HTTP message, dispatches, and tries to
		# commit any DB changes.  If the commit succeeds it exits the loop.
		# If the commit fails it loops back again and replays the request,
		# reading the same message bytes we read the first time.

		my $max_commit_failure = 1000;
		my $count_commit_failure = 0;

		while (1)
			{
			return if !http::read_message();

			loom_dispatch();  # This handles the message.

			if ($g_transaction_in_progress)
				{
				# See if current transaction size exceeds maximum.
				my $max_size = 2097152; # 2^21 bytes (2 MiB)

				my $cur_size = trans::size();
				if ($cur_size > $max_size)
					{
					transaction_too_large();
					}

				last;
				}
			elsif (trans::commit())
				{
				last;
				}
			else
				{
				# Commit failed because some data changed under our feet.
				# Loop back around and handle the same message again.
				# We impose a limit on number of failures.  It could
				# be that we failed because too many files were open, or
				# some other error besides read inconsistency.

				$count_commit_failure++;

				#print "$$ ($count_commit_failure/$max_commit_failure) "
				#	."commit failed let's retry\n";

				if ($count_commit_failure >= $max_commit_failure)
					{
					transaction_conflict();
					last;
					}
				}
			}

		# Now that we have successfully read a message from the client, handled
		# the message, and committed any database changes, let's send our
		# response to the client.

		page::send_response();

		#sloop_io::disconnect(); # for testing

		return if sloop_io::exiting();
		}

	return;
	}

return 1;
