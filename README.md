# mindmeister2md.rb

A [Ruby] script for converting [MindMeister][mindmeister] maps to [Markdown][md].

## Overview

The script has two main functions,

* list all your maps 
* output a map as markdown

When run with no arguments, the script prints a menu of maps available for you to select:

	   Available MindMeister Maps
	   ---
	    1: Software                      ( 2011-10-31 04:13:58 ) [ 117882387 ]
	    2: Internet Layer Protocols      ( 2011-10-27 18:10:26 ) [ 120233062 ]
	    3: Network Layer                 ( 2011-10-27 16:41:09 ) [ 119115816 ]
	    4: HTML                          ( 2011-10-24 17:59:28 ) [ 117882606 ]
	    5: Newbie                        ( 2011-10-24 03:53:40 ) [ 119564927 ]
	    6: Ethernet                      ( 2011-10-24 03:53:00 ) [ 116616227 ]
	    7: My First iPad Map             ( 2011-10-21 14:19:07 ) [ 119100256 ]
	    8: My First iPhone Map           ( 2011-10-21 14:17:30 ) [ 119262965 ]
	    9: Threads                       ( 2011-10-20 15:14:29 ) [ 116945908 ]
	   10: Computer Hardware             ( 2011-10-12 19:24:19 ) [ 117875898 ]
	   11: ACM Programming Tips          ( 2011-10-11 04:03:21 ) [ 117550509 ]
	   12: Interprocess Communication    ( 2011-10-04 02:54:56 ) [ 116511362 ]
	   Selection: 

Optionally you can pass either the name of a map (case insensitive) or the map id (given in square brackets in the menu) as argument(s). Both of these would return the "My First iPad Map",

	   ./mindmeister2md.rb my first ipad map
	   ./mindmeister2md.rb 119100256

By default the script outputs the markdown to the screen. There is an optional command-line argument (`-o`) which will write the markdown to a file.

For the UNIX geeks: Only the generate markdown is sent to standard output (`STDOUT`).  So the markdown can easily be piped to other commands,

		./mindmeister2md.rb my first ipad map | wc -l

## Configuration

Each user needs to have a [MindMeister *api key* and *secret*][mmapi] in order to use this script. There is a configuration file in the home directory named `.mindmeister2md` created automatically by the script the first time it is run.

By default the configuration file looks similar to this:

	   --- 
	   indent: 4
	   list_level: 2
	   api_key: 
	   secret: 
	   list_bullet: *

You get both `api_key` and `secret` from the [MindMeister api request page][mmapi]. The other two options you can set are:

`list_level`
: The level in the map where lists should begin. At a `list_level` of 2, the first two levels of the map tree structure are represented as markdown headings, rather than as lists. A `list_level` of 0 will mean that the map will be exported as a single giant list.

`list_bullet`
: The character to use as the leading bullet in lists. Default is *, but "-" is commonly used in Markdown as well.

`indent`
: specifies the number of spaces that represent a single indent in the list.


## Command Line Options

Most of the configuration file can also be changed at run-time using optional command line arguments. There is also an option to simply print the maps without actually printing any of them out as well as output to a file.

 Usage: mindmeister2md.rb [options] <map id | map name>

`-l, --list` 
: List available maps and exit.

`-i, --indent <indent>` 
: Set number of spaces for each indent level. Like temporarily setting `indent` in the configuration file.

`-b, --bullet "<indent>"` 
: Select the character to use as the list bullet. Like temporarily setting `list_bullet` in the configuration file.

`-s, --listlevel <list_level>` 
: Set the level at which lists should start. Like temporarily setting `list_level` in the configuration file.

`-o, --output FILE` 
: Write output to FILE.

`-h, --help` 
: Print command-line argument help.

[mmapi]: https://www.mindmeister.com/api/
[mindmeister]: http://www.mindmeister.com/
[md]: http://daringfireball.net/projects/markdown/
[ruby]: http://www.ruby-lang.org/en/
