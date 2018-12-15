# Facebook to Google Calendar Sync

Synchronize facebook page events with Google Calendar.

## Usage

It is expected that you have created two AWS SecretsManager secrets.

One should contain your facebook Graph API access token as a string (not JSON).

The other should contain you Google Service Account credentials JSON.

```terraform
module facebook_gcal_sync {
  source                = "amancevice/facebook-gcal-sync/aws"
  facebook_page_id      = "<facebook-page-id>"
  facebook_secret       = "<facebook-access-token-secret>"
  google_calendar_id    = "<google-calendar-id>"
  google_secret         = "<google-service-acct-secret>"
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
