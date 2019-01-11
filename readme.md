# XSLTug

A Meta-transformer. Supports running libraries of XSLT transformation pipelines using localized, home-made command line syntaxes.

# Who is it for (XSLT developers)

If you don't need to run XSLT pipelines, you have no need for this tool.

If you do run such pipelines, using XProc, Ant or anything you have developed yourself, you probably don't need this tool, which provides similar functionality, but which is "peculiar". 

If you deploy XSLT pipelines using shell scripts such as `bash` or Windows "batch syntax", you might consider using XSLTug in whole or in part. (If you use `make`, I salute you.)

If you deploy such pipelines to be used by team as "appliances", you might be particularly interested.

Also note that while you might not need XSLTug if you have any of the technologies or capabilities described above (or others, such as IDEs or online services), it might nonetheless work well inside or alongside them.

# Why this approach?

## XSLT pipelines as black boxes

While it is useful to be able to write XSLT, it is also useful to be able to run it even if you don't trust yourself to write it.

## Extensibility / Learnability

While lightweight, this is meant to be very flexible and extensible. Also, because it will be set down and taken up at inconsistent intervals, it must be learnable and traceable, to both users and developers.

For users, this goal is to be achieved by presenting very simple interfaces, factoring out as many system complexities as possible to achieve process results without respect to means. The complexities must not be hidden from developers, however; instead, interfaces must be presented to enable developers to manage these complexities for the user by means of smart design.

## Security

Everything is encapsulated in a single runtime call. While XSLTug may write files to the system (as designed), it won't create temporary artifacts or system scat, and it doesn't depend on network or server.

## Limitations

Without support (for example) for EXSLT, we can't quite provide full services over the directory structure.

This means that some kinds of batch processing aren't readily provided for. Expect things to work best one-to-one or one-to-many.

Otherwise, the only limitations are in what can be done with XSLT given the available computing power. This being said, no warranty can be offered or implied for any application of this code or code that it invokes.

## Dependencies

One of the requirements is to be lightweight (and secure) so the only dependency is Saxon.

However, XSLTug could also be adjusted to work with any XSLT 3.0 processor that supports the XPath 3.1 function library. Please make inquiries if you have a processor other than Saxon, and you wish to road-test this useful meta-application.

## Fun

Schematron is fun because you get to write your own error messages. The fun of XSLTug is in designing a capable command syntax to accomplish chores without fuss -- and subsequently watching it disappear to do its job unnoticed.

# To use:

1. Acquire Saxon (any version since 9.9)
1. Set up your environment, \*nix or Windows
1. Use the command syntax given to invoke XSLT transformations and pipelines
1. Extend the command syntax with your own mapping configurations (in XML) to support your own processes

## Acquire Saxon

Saxon is the industry-leading XSLT 3.0 processor.

With Java installed, you can use Saxon with a path to its `jar` file.

Or on Windows you can also run Saxon under .NET (see their docs)


## Environment

Edit the scripts to replace the developer's paths with your own. Ensure the scripts in the distribution (`.sh` or `.bat` as appropriate) have permissions to run (`chmod 755 tug.sh` or equivalent).

(TBD)

## Command syntax
 
In bash, `./tug.sh` or just (if aliased) `tug`

An analogous Windows command (`tug.bat`) is also under development.

The following examples assume an alias. Expand `tug` to `./tug.sh` as needed.

`tug help` gives basic help, including the configured command tree, including other commands it is set up to recognize (including...)

`tug test` invokes a simple pipeline to test whether pipelining transformations works properly

`tug mockup foo bar baz` writes a command tree suitable for inclusion in a configuration - use this to get started on making your own syntax (in this case showing the tree for `foo bar baz`).

So for example you might type `tug mockup makemyfile file.html from file.xml` to see what a configuration for that particular tree will look like. XSLTug is extended by annotating this representation with the instruction set for applicable transformations and processes.

`tug inspect {file.xml}` reports information about an XML file resource

It uses the `xml-analysis.xsl` stylesheet, which has just been started (at time of writing), so it doesn't give much in the way of results.

## Extending

Extending XSLTug is meant to be easy: build a command tree representing the syntax to be supported, in which the expected operations are described and binding points are provided for any properties to be declared dynamically (such as file names and parameter values). (Currently the configuration is kept in the main XSLT but it could be moved out of line.)

Given such a configuration, the XSLTug transformation can match the commands a user gives at runtime to corresponding instructions in back.

However, this feature set is also under development. To build your own configuration you will need expert assistance, until some non-obvious constraints, features and limitations are documented. If you wish to do this please ask the proprietor for guidance.

# Architecture

The main stylesheet is fired in an initial mode, `go`, with a single string parameter, which is parsed and processed into an XML data element  `$processtree`.

The main execution works by processing a configuration tree, represented as an XML document. (As variable `$go`, it is given as a literal in the XSLT, but it could also be provided from out of line.) This tree represents a complete map of everything this instance of XSLTug is able to do, its library of transformations. Within the map are declarations for all the information needed (such as names of inputs or processes or parameter values) to run the desired transformations and transformation sequences.

Given this map, `$processtree` is then referenced as a pointer or pathway to the location where the appropriate pipeline is specified. In the configuration tree the pipeline takes the form of a model (representation) of transformation processes including designators (binding points) for input and output (result) file names, parameter values and runtime configurations such as serialization settings. By locating the analogous data items in the process tree, the configuration for any process can accept bindings or settings from any `$processtree` actually given.

Outputs may be reported directly to the console (in plain text or markdown) or written out to files, as indicated by application semantics (as pipeline production artifacts).

Replacing the configuration tree replaces the entire functionality of the toolkit.
