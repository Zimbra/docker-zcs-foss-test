### Introduction


This project will let you deploy a non-HA, multi-node, Zimbra install into a Docker Swarm and execute a series of tests against the container.

### Prerequisites

You must have an available Docker swarm into which you can deploy.  At the most basic, you can easily setup a temporary Docker swarm in your local engine as follows:

	docker swarm init

This will give you a single-node swarm and it will work fine.

    $ docker node ls
    ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS
    rwn37e476d9tdtwate60o00o9 *   moby                Ready               Active              Leader


**Note:**

Just added placement constraints so you can control which nodes in your swarm that we are allowed to deploy this stack to.  The constraint is that the node(s) have a label `zimbra=true`.  The reason for this is that when you are deploying into a test swarm in EC2, you may have certain nodes (like the `manager`) with fewer system resources than the `worker` nodes.

In that case you could just specify a constraint like this: `node.role == worker`.  That would work fine in the above-mentioned hypothetical situation.  But if you are testing in a local (single-node) swarm as described above, the `node.role` constraint would not be satisfied, because in a single-node swarm, the node has the `manager` role.

One easy solution that works in both deployment environments is via the use of labels.  So, before you deploy, just update the node (or nodes) upon which you wish to deploy the stack to as follows:

	docker node update --label-add zimbra=true <node-id>

So do that first, either to your _only_ node in the case of your simple, local swarm setup.  Or apply the label to the nodes in your larger swarm as applicable.

The notes that follow assume you have an available swarm (with node labels assigned) and that your shell is configured to talk to it.

### Setup

1. Clone this repo. Then `cd` into the repo directory.
2. Check out the `feature/multi-node` branch.
3. Initialize the submodule: `git submodule update --init --recursive`
4. Create an environment (`.env`) file: `cp zcs-foss/DOT-env .env`
5. [optional] Register a _secret_ in your swarm (see _Secret_ below). If you don't, please comment out these lines in the `docker-compose.yml` file, as follows:

        #    secrets:
        #      - dot-s3curl

6. That's it.

### Deploying the Stack

Assuming you have satisfied the _Prerequisites_ and completed the _Setup_:

	docker stack deploy -c docker-compose.yml <stack-name>

Example:

	docker stack deploy -c docker-compose.yml zcs

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
    --genesis-plan <plan>     If specified, run this plan instead of the default plan (smokeoss.txt)
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

If you don't have an id/key that will work, just comment out the lines in the `docker-compose.yml` file as described above in step 5 of _Setup_.
