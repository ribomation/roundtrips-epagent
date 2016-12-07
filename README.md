# roundtrips-epagent
This is a custom CA APM (f. Wily Introscope) EPAgent intended to read and 
aggregate Apache HTTPd log files.

_N.B. If you are not using CA APM, you can stop reading now._

# Requirements

* Make
* Tar
* Perl
* Prove (part of Perl and required for the unit tests)
* Java JRE

# Build

Clone GitHub repo

    mkdir -p path/to/parent/dir && cd $_
    git clone https://github.com/ribomation/roundtrips-epagent.git
    cd roundtrips-epagent

Build the agent distribution archive file

    make build
    ls -lhF build/roundtrips-2.1.tar.gz

Optionally run the unit tests

    make test

# Installation

Copy the archive file to the destination host and directory.
Then unpack the file direct within the target directory.

    tar xf roundtrips-2.1.tar.gz

# Configuration

Update the `parameters.conf` file with host/port to the APM server.

    apm.host=apm-host
    apm.port=5001
    heap.size=32m

Update the `agents.csv` file with one line per agent.

    #NAME   DIR                           PATTERN
    ABC    /path/to/abc/apache/logs       abc.website.se-80
    XYZ    /path/to/xyz/apache/logs       xyz.website.se-80

A line starting with `#` marks a comment line. The first column is the
agent name. The second column is the log directory of HTTPd. The third
column is logfile name pattern according to the name pattern  below.

    ^access-{{PATTERN}}\\.\\d+$

That means the filename prefix is `access-` and its suffix is numeric timestamp. With other
words; the pattern is placed between a dash (`-`) and a dot (`.`).

# Launch

Start the agent(s) by running the shell script

    ./start-agents.sh

There will be a new directory created named `./run/` that contains agent profile,
log file and pid file, for each agent.

Stop the agents by running the shell script

    ./stop-agents.sh

The `./run/*.pid` files will be removed.

# Contribution

Fork the repo, make some changes and file a pull request. Ensure that your changes
are covered by unit tests.

