# Facebook to Google Calendar Sync

[![terraform](https://img.shields.io/github/v/tag/amancevice/terraform-aws-facebook-gcal-sync?color=62f&label=version&logo=terraform&style=flat-square)](https://registry.terraform.io/modules/amancevice/facebook-gcal-sync/aws)
[![build](https://img.shields.io/github/workflow/status/amancevice/terraform-aws-facebook-gcal-sync/validate?logo=github&style=flat-square)](https://github.com/amancevice/terraform-aws-facebook-gcal-sync/actions)

Synchronize facebook page events with Google Calendar.

## Prerequisites

Before beginning you will need to create and configure a [facebook app](https://github.com/amancevice/fest/blob/master/docs/facebook.md#facebook) and use it to acquire a page access token for Graph API.

You will also need to set up a Google [service account](https://github.com/amancevice/fest/blob/master/docs/google.md#google) to acquire a credentials file to authenticate with Google APIs.

It is expected that you use the facebook access token and Google service account credenetials to create AWS SecretsManager secrets using the `facebook-gcal-sync-secrets` module described below.

## Usage

You may create both modules in the same project, but separating them into different projects will enable collaboration on the core application without having to distribute the facebook/Google credentials to each collaborator.

```terraform
# WARNING Be extremely cautious when using secret versions in terraform
# NEVER store secrets in plaintext and encrypt your remote state
# I recommend applying the secret versions in a separate workspace with no remote backend.
resource "aws_secretsmanager_secret_version" "facebook" {
  secret_id     = module.facebook_gcal_sync.facebook_secret.id
  secret_string = "my-facebook-app-token"
}

resource "aws_secretsmanager_secret_version" "google" {
  secret_id     = module.facebook_gcal_sync.google_secret.id
  secret_string = file("./path/to/my/svc/acct/creds.json")
}

module facebook_gcal_sync {
  source  = "amancevice/facebook-gcal-sync/aws"
  version = "~> 1.0"

  facebook_page_id     = "<facebook-page-id>"
  facebook_secret_name = "facebook/my-app"
  google_calendar_id   = "<google-calendar-id>"
  google_secret_name   = "google/my-svc-acct"
}
```
