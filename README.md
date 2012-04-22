# TAG

A simple script based on node.js (without dependencies) to help correctly upgrade versions and tag them with git.

The ideas are:

- I want to have at least one file that contains the actual version so it can be displayed and distributed easily.
- Commits that represent development should be at a `X.Y.Z-dev` version. This way I always know when a program / library is in development.
- There should always be **only one** commit that has the version `X.Y.Z`. When somebody uses a JS file of mine, or views a documentation where the version number is printed at the bottom, and the version is `X.Y.Z` (without `-dev`), s/he *knows* that this is the one and only `X.Y.Z` release, not some development phase that came after this release.
- It is possible to configure this script so it updates multiple version occurences in multiple files. The version occurence can be the default `X.Y.Z(-dev)` pattern, or a complex regular expression. It's stored in the .tagconfig file.



This helps me achieve [semantic versioning](http://semver.org/), and implementend the [successful branching model](http://nvie.com/posts/a-successful-git-branching-model/).



## Usage

After installing nodejs simply type `/path/to/tag` in your console when in a git repository.

The first time the script is called it will aid you in creating a `.tagconfig` which looks approximately like this:

    {
      "files": [
        {
          "name": "tag",
          "regexs": [
            "version = '###'"
          ]
        }
      ]
    }

You can add regular expressions to `regexs` so multiple versions can be found, and add additional files.

**WARNING**: When you use a selfmade regular expression, make sure you use groups that don't capture, like this: (?:stuff)

As soon as the config is created, add the `.tagconfig` to your repository and commit it (this way you have a clean commit).

The next time you start the script you will see the detected version, and the proposed next versions.

## Renaming only

Sometimes you only want to rename your version without actually tagging the whole thing. (This happens when you're
working on the version 1.4.3-dev and realize that the next version will actually be 2.0.0. So you should be working
on 2.0.0-dev).
To do so, call `tag` with the `--rename-only` option:

    tag 2.0.0-dev --rename-only

### Manual versioning

When you **don't** want to upgrade version `1.2.3-dev` to `1.2.3`, or version `1.2.3` to `1.2.4`, you can specify the next version manually like this:

    /path/to/tag 2.0.0

After commiting this version, the script automatically increases the version, and appends `-dev`. If you also want to control this, simply add it as a second parameter:

    /path/to/tag 2.0.0 3.0.0-dev

(I strongly recommend it being a `-dev` version)

## Output

When calling `tag`, a typical output looks like this:

    Usage (v1.1.3-dev): tag [nextVersion [nextDevVersion]] --rename-only

    Using config file ./.tagconfig


    Matches:

    File: tag (Regular expression: version = '###')
     - version = '1.1.3-dev'


    ========================================
     Current version:    1.1.3-dev
     Next version:       1.1.3
     Tag name:          v1.1.3
     Next dev version:   1.1.4-dev
    ========================================

    Make sure you're on the right (develop) branch: 
    * develop
      master

    Press enter to continue (Ctrl-c to abort)...


## Step By Step

This is what the script actually does:

1. Changes the version in all configured files to the next version.
2. Commits the change with a commit message like "Upgrading to version 2.1.4".
3. Tags the commit. (Asks you to specify a tag message).
4. Changes the version to the next development version. (The default is the increased next version with `-dev` at the end).
5. Commits the change with a commit message like "Upgrading to version 2.1.5-dev".
6. Optionally merges the tag to master. (Checks out master, merges the develop branch with --no-ff, checks out develop again)
7. Optionally does `git push --all && git push --tags`



## License

(The MIT License)

Copyright (c) 2011-2012 Matias Meno &lt;m@tias.me&gt;

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the 'Software'), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
