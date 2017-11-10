### Introduction

Provides the following testing services against a ZCS (single or multi-node) cluster:

* SOAP-Harness SanityTest suite
* Genesis test suite

### Prerequisites

You must have an available Docker swarm into which you can deploy.  At the most basic, you can easily setup a temporary Docker swarm in your local engine as follows:

	docker swarm init

This will give you a single-node swarm and it will work fine.

    $ docker node ls
    ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS
    rwn37e476d9tdtwate60o00o9 *   moby                Ready               Active              Leader

### Setup

1. Clone this repo. Then `cd` into the repo directory.
2. Initialize/update the submodule: `git submodule update --init --recursive`
3. Create an environment (`.env`) file: `cp zcs-foss/DOT-env .env`
4. [optional] Register a _secret_ in your swarm (see _Secret_ below). If you don't, please comment out these lines in the `docker-compose.yml` file, as follows:

        #    secrets:
        #      - dot-s3curl

### Deploying the Stack

Assuming you have satisfied the _Prerequisites_ and completed the _Setup_:

	docker stack deploy -c docker-compose-single.yml <stack-name>

or:

	docker stack deploy -c docker-compose-multi.yml <stack-name>

Example:

	docker stack deploy -c docker-compose-multi.yml zcs

### Controlling what happens when you deploy the stack

Look at this excerpt from the `docker-compose.yml` file for the `test` service:

    entrypoint:
      - /zimbra/init
      - --shutdown
      - "no"

By default all this will do is initialize the `test` service, update the configuration for the _SOAP Harness_ and _Genesis_ tests and then _not_ shutdown (exit).  At that point feel free to connect to the test container and manually execute all of the tests that you like.  What are your options?


    /zimbra/init --help

    /zimbra/init [ARGS]

	where ARGS may be any of the following:
	--run-soap yes|no         (default=no) run soap-harness tests
	--run-genesis yes|no      (default=no) run genesis tests
	--upload-logs yes|no      (default=no) archive and upload test log files
	--soap <test>             If specified, run this test instead of the default (SanityTest/)
							  The value specified will be prefixed by this:
							  /opt/qa/soapvalidator/data/soapvalidator/
	--genesis-case <testcase> If specified, run this testcase instead of the default plan.
							  --genesis-case supercedes --genesis-plan
							  The value specified will be prefixed by this:
							  data/
	--genesis-plan <plan>     If specified, run this plan instead of the default plan (HA/UATmultinodefoss.txt)
							  The value specified will be prefixed by this:
							  conf/genesis/
	--shutdown yes|no         (default=yes) If yes, allow this script to end when it has finished working.
							  Since this script is the normal entrypoint, if you want it to just sleep
							  instead of exiting, pass in a value of "no" for this and your test container
							  will stay running so you can log in and run more tests.
	-h|--help                 Print help message and exit

	
So if you wanted to connect to the `test` container and manually run all of the _SOAP Harness_ tests that are available, then execute the following after you are on the `test` service container:

	/zimbra/init --run-soap yes

By the way, it is perfectly safe to use the default `--shutdown` option of `yes`.  All that it means is that the script is allowed to exit.

You can, of course, update the `docker-compose.yml` file to have the `test` service run whatever you want.


### Secret

Currently if you run `/zimbra/init` on the test container with `--upload-logs yes` it is set to upload to a particular bucket and path. From the `docker-compose.yml file`:

    # The default value of S3_PATH is:
    #   S3_PATH: docker.zimbra.com/tests/zcs-foss-multi
    # See comments in configs/init-test for more details.
    environment:
      S3_PATH: docker.zimbra.com/tests/zcs-foss-multi

And the further notes in `config/init-test`:

    # This is the default path that the tests results will be uploaded to in S3.
    # The final component of the pathname will be auto-generated with a date/time stamp
    # Here is an example of what the entire upload URL (used by s3curl) might look like:
    #   https://s3.amazonaws.com/docker.zimbra.com/tests/zcs-foss-multi/20171008T200524+0000.tar.gz
    # So this is:
    #   https://s3.amazonaws.com/<s3-path>/<generated-archive-name>
    # Note: The upload function will replace the `+` in the name with `%2b` so that the end
    #       result is correct.
    # You can override the default path by specifying an environment variable
    # `S3_PATH`.  It should not contain any leading or trailing slashes.  The part before the first `/`
    # should be the name of the bucket.
    S3_PATH_DEFAULT="docker.zimbra.com/tests/zcs-foss-multi"


If you do not have a suitable bucket in S3 and creds to access it, this is the format of the secret file:

    %awsSecretAccessKeys = (
        test => {
            id => '<aws-access-key-id>',
            key => '<aws-secret-access-key>',
        },
    );

[s3curl](https://github.com/rtdp/s3curl) is used to upload the test logs if desired.


Install the secret into the swarm before deploying the stack as follows:

	docker secret create dot-s3curl <path-to-secret-file>

If you don't have an id/key that will work, just comment out the lines in the `docker-compose.yml` file as described above in step 4 of _Setup_.

### Adapting to work with other Zimbra Installations

The SOAP and Genesis test frameworks have a specific set of setup prerequisites.  They are documented [here](https://github.com/Zimbra/docker-zcs-foss-test/wiki/ZCS-Test-Prerequisites).  The two reference configurations (for single and multi-node Zimbra installs) have been pre-configured to meet the requirements for SOAP and Genesis.

To adapt this test Image to work with other Zimbra installs, you must make sure that the new Zimbra install has had the required configuration updates applied.




