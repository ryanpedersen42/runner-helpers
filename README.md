install scripts and misc.

# Step-by-step for linux / mac scripts

## Setting up your local environment if not already done

1. Generate a [Personal API Token](https://app.circleci.com/settings/user/tokens)
2. Install and configure [the CLI](https://circleci.com/docs/2.0/local-cli/#configuring-the-cli)
3. Create a [CircleCI namespace](https://circleci.com/docs/2.0/runner-installation/#authentication) (each organization can only have one namespace; namespaces can only be created by an owner/admin; each org can only have a single namespace; if there are any orbs already created, they share the same namespace)

## Creating your runner

1. Create your runner resource class `circleci runner resource-class create <your-namespace>/<your-resource-class-name> <your-description>`
2. Get your runner token `circleci runner token create <your-namespace>/<your-resource-class-name> <nickname>`. Note your token as you'll need it to run jobs.

## Installing runner 

1. Provision resource to be used
2. Ensure you have the [prerequisites](https://circleci.com/docs/2.0/runner-installation/#prerequisites) installed 
3. Use the appropriate setup script, and provide your token, you-resource-class-name, and if you'd like to cleanup after each run when prompted.

## Calling runner from CircleCI

1. Reference the resource class as you would any other executor in your config:
```
version: 2.1
workflows:
  testing:
    jobs:
      - runner
jobs:
  runner:
    machine: true
    resource_class: <your-namespace>/<your-resource-class-name>
    steps:
      - run: echo "Hi I'm on Runners!"
```
