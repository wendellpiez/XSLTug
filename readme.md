# XSLTug

A command-line shell for orchestrating XSLT transformation pipelines.

# Who is it for (XSLT developers)

If you don't need to run XSLT pipelines, you have no need for this tool.

If you do run such pipelines, using XProc, Ant or anything you have developed yourself, you probably don't need this tool, which provides similar functionality, but which is "peculiar". 

If you deploy XSLT pipelines using shell scripts such as `bash` or Windows "batch syntax", you might consider using XSLTug in whole or in part. (If you use `make`, I salute you.)

If you deploy such pipelines to be used by team as "appliances", you might be particularly interested.

# Why this approach?

## XSLT pipelines as black boxes

While it is useful to be able to write XSLT, it is also useful to be able to run it even if you don't trust yourself to write it.

## Extensibility / Learnability

While lightweight, this is meant to be very flexible and extensible. Also, because it will be set down and taken up at inconsistent intervals, it must be learnable and traceable.

## Security

Everything is encapsulated in a single runtime call. While XSLTug may write files to the system (as designed), it won't create artifacts and doesn't depend on network or server.

## Limitations

Without support (for example) for EXSLT, we can't quite provide full services over the directory structure.

This means that some kinds of batch processing aren't readily provided for. Expect things to work best one-to-one or one-to-many.

# To use:

1. Acquire Saxon (any version since 9.9)
1. Set up your environment, \*nix or Windows
1. Use the command syntax given to invoke XSLT transformations and pipelines
1. Extend the command syntax with your own mapping configurations (in XML)

### Acquire Saxon

Saxon is the industry-leading XSLT 3.0 processor.

With Java installed, you can use Saxon with a path to its `jar` file.

Or on Windows you can also run Saxon under .NET (see their docs)


### Environment

Edit the scripts to replace the developer's paths with your own.

### Command syntax
 
`./tug.sh` or just (if aliased) `tug`

`tug -help` gives basic help, including the configured command tree
`tug test` invoked a simple pipeline to test whether pipelining transformations works properly

