# Facebook to Google Calendar Sync

Synchronize facebook page events with Google Calendar.

## Prerequisites

Before beginning you will need to create and configure a [facebook app](https://github.com/amancevice/fest/blob/master/docs/facebook.md#facebook) and use it to acquire a page access token for Graph API.

You will also need to set up a Google [service account](https://github.com/amancevice/fest/blob/master/docs/google.md#google) to acquire a credentials file to authenticate with Google APIs.

It is expected that you use the facebook access token and Google service account credenetials to create AWS SecretsManager secrets using the `facebook-gcal-sync-secrets` module described below.

## Usage

You may create both modules in the same project, but separating them into different projects will enable collaboration on the core application without having to distribute the facebook/Google credentials to each collaborator.

```terraform
module secrets {
  source                  = "amancevice/facebook-gcal-sync-secrets/aws"
  facebook_page_token     = "<your-page-access-token>"
  facebook_secret_name    = "facebook/MyPage"
  google_secret_name      = "google/MySvcAcct"
  google_credentials_file = "<path-to-credentials-JSON-file>"
}

module facebook_gcal_sync {
  source               = "amancevice/facebook-gcal-sync/aws"
  facebook_page_id     = "<facebook-page-id>"
  facebook_secret_name = "${module.secrets.facebook_secret_name}"
  google_calendar_id   = "<google-calendar-id>"
  google_secret_name   = "${module.secrets.google_secret_name}"
}
```

By default, a CloudWatch event rule is created to facilitate invoking the sync function, but no target is created.

If desired, you may enable a CloudWatch event target to invoke the sync function on a schedule:

```terraform
locals {
  event_target_input {
    Comment = "This input is optional."
  }
}

module facebook_gcal_sync {
  source                         = "amancevice/facebook-gcal-sync/aws"
  facebook_page_id               = "<facebook-page-id>"
  facebook_secret                = "<facebook-access-token-secret>"
  google_calendar_id             = "<google-calendar-id>"
  google_secret                  = "<google-service-acct-secret>"
  create_event_target            = true
  event_target_input             = "${jsonencode(local.event_target_input)}"
  event_rule_schedule_expression = "rate(1 hour)"
}
```
