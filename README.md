### Introduction

**Note:** This is a work in progress.  Updates coming soon.

This project will let you deploy a reference, single-node, Zimbra install into a Docker Swarm and execute a series of tests against the container.

The notes that follow assume you have an available swarm and that your shell is configured to talk to it.

### Setup


1. Clone this repo.
2. Copy `DOT-env` to `.env` (in the repo directory)
3. You need to publish a secret into your swarm.  See _Secret_ below.
4. Tweak the test(s) that you want to run from the `test` container. Just look at the `docker-compose.yml` file.  Run the `init-test-container` script with `-h` option to see what is available.
5. Deploy the stack: `docker stack deploy -c docker-compose.yml zcs && docker service logs -f zcs_test`

### Secret

The secret should be of the following format:

    %awsSecretAccessKeys = (
        test => {
            id => '<aws-access-key-id>',
            key => '<aws-secret-access-key>',
        },
    );

[s3curl](https://github.com/rtdp/s3curl) is used to upload the test logs if desired.
The key should work with upload folder.  TODO - make this configurable.

Install the secret into the swarm before deploying the stack as follows:

	docker secret create dot-s3curl <path-to-secret-file>
