make-rbz utility
================

Make RBZ files for Sketchup

(c) 2012 Daniel Bowring, released under GPL.


Requirements
------------

* Ruby 1.8 (with *rubyzip2*) **or** Ruby 1.9 (with *rubyzip*)
* Ruby gems


Usage
-----

```
$ make-rbz.rb -h
Usage : ruby make-rbz.rb [OPTIONS]
    -v, --[no-]verbose               Run Verbosely
    -t, --[no-]strict                Run in strict mode
    -f, --[no-]force                 Force file overwrites
    -o, --outname=NAME               Set Output File Name
    -p, --outpath=PATH               Set Output File Path
    -s, --source=PATH                Set Source Directory Path
    -r, --read-stdin                 Set File name from STDIN
    -i, --ignore=PATTERNS            Ignore files matching glob pattern
```

* `-v`, `--[no]-verbose`
    * Run in verbose mode
    * default `OFF`
    * This will print the name of every file added to the RBZ to STDOUT
* `-t`, `--[no-]strict`
    * Run in strict mode
    * default `ON`
    * Catches common errors
        * Setting filename multiple times
        * Having a directory in the filename
* `-f`, `--[no-]force`
    * Force overwriting the RBZ file if it already exists
    * default `OFF`
* `-o`, `--outname`
    * Set the filename of the RBZ file
    * `.rbz` will be automatically added if excluded
    * defaults to the name of the active directory
* `-p`, `--outpath`
    * Set the output directory for the RBZ file
    * Defaults to current directory, `.`
* `-s`, `--source`
    * Set the source directory
    * defaults to `src`
    * Contents of this directory will be added to the RBZ file
    * Acts as the root of the RBZ file
        * that is, the directory itself will not be added to the RBZ file,
            but all of its contents will
* `-r`, `--read-stdin`
    * Read the RBZ filename from STDIN
    * Example
        * `git describe | ruby make-rbz.rb -f` may produce `v1.0.0.rbz`
    * `.rbz` will be automatically added if excluded
* `-i`, `--ignore`
    * Add given glob patterns (separated with a `,`) to the ignore list
    * Files matching this pattern will not be added to the RBZ file
    * Example
        * `ruby make-rbz.rb -i '*.exe'` to exclude Windows executables
