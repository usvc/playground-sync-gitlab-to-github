# Synchronising a repository from GitLab to GitHub

# Why

## 💚 GitLab

- Allows for subgroup paths
- It's open source
- Awesome pipeline

## 💚 GitHub

- Enables organic discovery
- Binary attachment to releases

- - -

# TL;DR Reference

## Flow

1. Push to GitLab without tags
2. GitLab CI runs on untagged commit
3. Incremented semver version added to Git tags
4. Pipeline pushes tagged commit back to GitLab repo
5. GitLab CI runs on tagged commit
6. Pipeline pushes tagged commit to GitHub repo
7. GitHub repo recognises tagged commit as a release
8. Travis CI receives tagged build request
9. Pipeline deploys binaries to release

## Setup

### Local Machine

- [ ] Private/public key pair generated
- [ ] Base64-encoded private key generated

### On GitHub

- [ ] Personal access token created
- [ ] Deploy key (public key) registered for repository with Write Access

### At Travis CI

- [ ] Personal access token registered in environment variables as `GITHUB_OAUTH_TOKEN`.

### On GitLab

- [ ] Deploy key (public key) registered for repository.

### At GitLab CI

- [ ] Deploy key (base64-encoded private key) registered in environment variables as `DEPLOY_KEY`.
- [ ] GitHub repository clone URL registered in environment variables as `GITHUB_REPO_URL`.

### In Code

- [ ] Add job to [push back to GitLab on untagged commits](#pushing-back-to-gitlab-in-gitlab-ciyml)
- [ ] Add job to [push to GitHub on tagged commits](#deploying-to-github-in-gitlab-ciyml)
- [ ] Add deploy stage in Travis to [attach binaries to tagged commits](#deploying-binaries-from-travis)

- - -

# Setup Overview

For the below steps, `/repo/path` should be substituted with the actual path to your repository. Note that this may be different on GitHub than on GitLab.

## Generate deploy keys

- On your local machine, run `ssh-keygen -t rsa -b 4096 -f ./.ssh/id_rsa -N ""` to generate a private/public key pair.
  - The private key will be at `./.ssh/id_rsa`
  - The public key will be at `./.ssh/id_rsa.pub` 
- Run `cat ./.ssh/id_rsa | base64 -w 0 > ./.ssh/id_rsa.b64`
  - This is the base64-encoded private key

## GitLab

### Register public key as a deploy key for repository

Go to https://gitlab.com/repo/path/-/settings/repository and add a new Deploy Key (ensure **Write acess allowed** is enabled). Paste in the contents of the public key at `./.ssh/id_rsa.pub`

### Inject private key as an environment variable

Go to https://gitlab.com/repo/path/-/settings/ci_cd and register environment variable `DEPLOY_KEY` with the value set to the contents of the base64-encoded private key at `./.ssh/id_rsa.b64`.

### Inject GitHub repository URL as an environment variable

Go to https://gitlab.com/repo/path/-/settings/ci_cd and register environment variable `GITHUB_REPO_URL` with the value set to the SSH clone URL of your GitHub repository.

## GitHub

### Register public key as a deploy key for repository

Go to https://github.com/repo/path/settings/keys and add a new deploy key (ensure **Write Access** is enabled). Paste in the contents of the public key at `./.ssh/id_rsa.pub`

## Travis

Go to https://travis-ci.org and enable pipelines for your repository.

### Generate GitHub personal access token

Go to [https://github.com/settings/tokens/new](https://github.com/settings/tokens/new) and create a new personal access token with the **`public_repo`** permission enabled.

### Inject personal access token into pipeline

Go to https://travis-ci.org/repo/path/settings ad register environment variable `GITHUB_OAUTH_TOKEN` with the value set to the personal access token.

# Execution Overview

## Loading private key into execution sandbox

Add the following into the `before_script` of the job that you'd like to push to GitLab/GitHub:

```sh
mkdir -p ~/.ssh;
printf -- "${DEPLOY_KEY}" | base64 -d > ~/.ssh/id_rsa;
chmod 600 -R ~/.ssh/id_rsa;
```

For GitHub, append the following to the `before_script`:

```sh
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts;
```

For GitLab, append the following to the `before_script`:

```sh
ssh-keyscan -t rsa gitlab.com >> ~/.ssh/known_hosts;
```

## Pushing back to GitLab in .gitlab-ci.yml

For versioning purposes, you might want to push a tag back to GitLab. You can do this using a job that looks like:

```yaml
bump:
  only: ["master"]
  stage: release
  image: usvc/semver:gitlab-latest
  before_script:
    - mkdir -p ~/.ssh
    - 'printf -- "${DEPLOY_KEY}" | base64 -d > ~/.ssh/id_rsa'
    - chmod 600 -R ~/.ssh/id_rsa
    - ssh-keyscan -t rsa gitlab.com >> ~/.ssh/known_hosts
  script:
    - git remote set-url origin "${CI_REPOSITORY_URL}"
    - git checkout master
    - semver bump --git --apply
    - git push origin master --verbose --tags
  after_script:
    - rm -rf ~/.ssh/*
```

## Deploying to GitHub in .gitlab-ci.yml

To push changes in your repository to GitHub, you could use the following minimal job:

```yaml
to github:
  only: ["tags"]
  stage: publish
  before_script:
    - mkdir -p ~/.ssh
    - 'printf -- "${DEPLOY_KEY}" | base64 -d > ~/.ssh/id_rsa'
    - chmod 600 -R ~/.ssh/id_rsa
    - ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
  script:
    - git config --global user.email "usvc.semver@usvc.dev"
    - git config --global user.name "usvc_publisher"
    - git remote set-url --add --push origin ${GITHUB_REPO_URL}
    - git checkout master
    - git push -u origin master --tags --force
  after_script:
    - rm -rf ~/.ssh/*
```

## Deploying binaries from Travis

In your Travis script, add a root level property named `deploy`:

```yaml
# ...
deploy:
  provider: releases
  api_key: ${GITHUB_OAUTH_TOKEN}
  file_glob: true
  file: ./bin/*
  skip_cleanup: true
  on:
    branch: master
    tags: true
# ...
```

The above script will attach all files in the `./bin` directory to the release. Note that the above will only run for Travis runs on a tagged commit.

## For Docker images

The `./.gitlab-ci.yml` in this repository includes a step to publish to a Docker registry only if the following three environment variables are defined:

| Key | Description |
| ---: | :--- |
| `DOCKER_REGISTRY_URL` | Hostname of the Docker registry (eg. `"docker.io"`) |
| `DOCKER_REGISTRY_USER` | Username to login to the Docker registry (eg. `"username"`) |
| `DOCKER_REGISTRY_PASSWORD` | Password for the user specified above (eg. `"password"`) |

Add them in from https://gitlab.com/repo/path/-/settings/ci_cd.

# Why not...

## Just use GitLab's mirroring?

It's easier to set up, but this means that developers need to push to GitHub. Using GitLab as the primary source and GitHub as the mirror allows us to have a on-premise single source of truth, yet make public work that's done on on-premise.

# License

This work is licensed [under the MIT license](./LICENSE). Do what you will with it(:
