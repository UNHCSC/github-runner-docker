# github-runner-docker
A cloneable template with minimal setup steps to get Github runners working with Docker

## Configuration

Set these environment variables in `docker-compose.yaml`:

- `REPOSITORY_URL`: full GitHub repository URL, for example `https://github.com/octo-org/octo-repo`
- `RUNNER_TOKEN`: a GitHub token that can call the self-hosted runner registration API

`RUNNER_TOKEN` is not the short-lived registration token shown in the GitHub UI. This container fetches fresh runner registration and removal tokens through the GitHub REST API, so use one of these instead:

- a classic PAT with the `repo` scope
- a fine-grained token with repository `Administration` permission set to `write`

The entrypoint derives the `owner/repo` slug from `REPOSITORY_URL` for the API call and passes the full repository URL to `config.sh`.
