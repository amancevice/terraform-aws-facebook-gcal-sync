# Facebook to Google Calendar Sync

Synchronize facebook page events with Google Calendar.

## Usage

It is expected that you have created two AWS SecretsManager secrets.

One should contain your facebook Graph API access token as a string (not JSON).

The other should contain you Googlle Service Account credentials JSON.

```terraform
module facebook_gcal_sync {
  source                = "amancevice/facebook-gcal-sync/aws"
  facebook_page_id      = "<facebook-page-id>"
  facebook_secret       = "<facebook-access-token-secret>"
  google_calendar_id    = "<google-calendar-id>"
  google_secret         = "<google-service-acct-secret>"
  event_rule_is_enabled = true
}
```
