# az-linux-demo
Deploying to Azure with Terraform, Azure CLI and Azure Resource Manager

![Terraform Workflow](https://github.com/sjohner/az-linux-demo/workflows/Deploy%20Terraform%20sample%20to%20Azure/badge.svg)

# Building the Github Actions workflow for Terraform
Sample Github Actions workflow for Terraform deployments

## Create Github secrets
To deploy resources to your Azure subsription, you will need a Service Principal for authenticating to Azure. Check out [Terraform documentation](https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html) for more information on how to authenticate via a Service Principal with a client secret 

Make sure you are able to deploy your Terraform configuration using the newly created Service Principal.

If you followed the Terraform docs carefully, you will now have four environment variables configured on your local machine:

* ARM_CLIENT_ID
* ARM_CLIENT_SECRET
* ARM_SUBSCRIPTION_ID
* ARM_TENANT_ID

When deploying your Terraform config with Github Actions you will need the same variables. However dont want to expose your secrets by passing them as variables or storing them in your config. Therefor store them as Github secrets to avoid exposing your access keys or service principal credentials.

In Github, we can specify Secrets by going to Settings -> Secrets

![Github Secrets](https://github.com/sjohner/az-linux-demo/blob/master/images/github_secrets.png)

You can afterwards use those secrets to set environment variables in your Github Actions workflows like this

```
ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

```

## Store Terrform State in Azure
Since having a local state doesn't work well in a team or collaborative environment, you want to make sure that you are storing your Terraform state in an Azure storage account. Check out [this tutorial](https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage) for more information about storing your Terraform state file in Azure and [Terraform documentation](https://www.terraform.io/docs/backends/types/azurerm.html) for details about how to configure the azurerm backend 

## Create your workflow
Github Actions brings us a way to automate, customize, and execute our development workflows right in the repository. More information about Github Actions can be found in the [Github documentation](https://help.github.com/en/actions)
To continuously deploy code with GitHub Actions, you need to create a workflow. All workflows are defined in YAML.
Creating a new workflow is easy. Make sure your Terraform code is stored in a Github repository and click on the _Actions_ button. Create your own YAML file by clicking the _Set up a workflow yourself_ button in the upper right corner of the screen.

![Github Secrets](https://github.com/sjohner/az-linux-demo/blob/master/images/create_workflow.png)

An example workflow may look like this:
```
name: Deploy sample blog project to Azure
on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]
jobs:
  build:
    name: 'Build'
    runs-on: ubuntu-latest
    steps:
      - name: 'Checkout'
        uses: actions/checkout@master
      - name: 'Terraform Init'
        uses: hashicorp/terraform-github-actions@master
        with:
          tf_actions_version: 0.12.24
          tf_actions_subcommand: 'init'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - name: 'Terraform Plan'
        uses: hashicorp/terraform-github-actions@master
        with:
          tf_actions_version: 0.12.24
          tf_actions_subcommand: 'plan'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          
````

The above example will trigger the worflow on push and pull requests to the master branch.
```
push:
    branches: [ master ]
  pull_request:
    branches: [ master ]
    
```

The workflow contains a _build_ job has three steps:
* Check out code
* Terraform Init
* Terraform Plan

For the _init_ and _plan_ steps corresponding environment variables are defined which contain all necessary information to authenticate to Azure via a Service Principal

Check out the full code sample here

