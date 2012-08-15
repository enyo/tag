# Tag Version 2.0.4-dev

A simple script based on node.js (without dependencies) to help correctly upgrade versions and tag them with git.

The ideas are:

- I want to have at least one file that contains the actual version so it can be displayed and distributed easily.
- Commits that represent development should always end with `-dev` (eg: `2.0.1-dev`). This way I always know when a program / library is in development.
- There should always be **only one** commit that has the version `X.Y.Z`. When somebody uses a JS file of mine, or views a documentation where the version number is printed at the bottom, and the version is `X.Y.Z` (without `-dev`), s/he *knows* that this is the one and only `X.Y.Z` release, not some development phase that came after this release.
- It is possible to configure this script so it updates multiple version occurences in multiple files. The version occurence can be the default `X.Y.Z(-dev)` pattern, or a complex regular expression. It's stored in the `.tagconfig.json` file.



This helps me achieve [semantic versioning](http://semver.org/), and implementend the [successful branching model](http://nvie.com/posts/a-successful-git-branching-model/).


## Installation

    npm install -g versiontag

## Usage

Use the help to view a list of available commands:

    tag -h


The first time you run `tag` you probably want to add new files `tag` should replace the versions in.
Do this by running `tag --add`

The generated `.tagconfig.json` file looks approximately like this:

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

As soon as the config is created, add the `.tagconfig.json` to your repository and commit it (this way you have a clean commit).

The next time you start the script you will see the detected version, and the proposed next versions.

## Renaming only

Sometimes you only want to rename your version without actually tagging the whole thing.

To do so, call `tag` with the `r` (`--rename`) option:

    tag -r

### Manual versioning

When you **don't** want to upgrade version `1.2.3-dev` to `1.2.3`, or version `1.2.3` to `1.2.4`, you can specify the next version manually with the `-t` (`--tag`) option:

    tag -t 2.0.0

After commiting this version, the script automatically increases the version, and appends `-dev`. If you also want to control this, you can also use the `-d` (`--dev`) option:

    tag -t 2.0.0 -d 3.0.0-dev

(I strongly recommend it being a `-dev` version)

## Output

When calling `tag`, a typical output looks like this:

![Output](http://i.imgur.com/sKOwL.png)


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
