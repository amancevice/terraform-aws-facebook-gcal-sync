import json
import os

import boto3
import facebook
import lambo
from google.oauth2 import service_account
from googleapiclient import discovery

import fest


def secret(client, **params):
    """
    Helper to get SecretsManager secret.
    """
    logger.info(f"GET SECRET '{json.dumps(params)}'")
    return client.get_secret_value(**params)['SecretString']


def json_secret(client, **params):
    """
    Helper to get JSON SecretsManager secret.
    """
    return json.loads(secret(client, **params))


FACEBOOK_SECRET = os.environ['FACEBOOK_SECRET']
GOOGLE_SECRET = os.environ['GOOGLE_SECRET']

FACEBOOK_PAGE_ID = os.getenv('FACEBOOK_PAGE_ID')
GOOGLE_CALENDAR_ID = os.getenv('GOOGLE_CALENDAR_ID')

# Init Logger
logger = lambo.getLogger('facebook-gcal-sync')

# Get facebook/Google secrets
SECRETSMANAGER = boto3.client('secretsmanager')
FACEBOOK_PAGE_TOKEN = secret(SECRETSMANAGER, SecretId=FACEBOOK_SECRET)
GOOGLE_SERVICE_ACCOUNT = json_secret(SECRETSMANAGER, SecretId=GOOGLE_SECRET)
GOOGLE_CREDENTIALS = service_account.Credentials.from_service_account_info(
    GOOGLE_SERVICE_ACCOUNT
)

# Get facebook/Google clients
GRAPHAPI = facebook.GraphAPI(FACEBOOK_PAGE_TOKEN)
CALENDARAPI = discovery.build(
    'calendar', 'v3',
    cache_discovery=False,
    credentials=GOOGLE_CREDENTIALS,
)


@logger.attach
def handler(event, context=None):
    # Get args from event
    dryrun = event.get('dryrun') or False
    page_id = event.get('pageId') or FACEBOOK_PAGE_ID
    cal_id = event.get('calendarId') or GOOGLE_CALENDAR_ID

    # Initialize facebook page & Google Calendar
    page = fest.FacebookPage(GRAPHAPI, page_id)
    gcal = fest.GoogleCalendar(CALENDARAPI, cal_id)
    page.logger = gcal.logger = logger

    # Sync
    sync = gcal.sync(page, time_filter='upcoming').execute(dryrun=dryrun)

    # Helper to get event time
    def event_time(time):
        try:
            return time['dateTime']
        except KeyError:
            return time['date']

    # Return referces to modified objects
    resp = {
        k: [
            {
                'google_id': x.get('id'),
                'location': x.get('location'),
                'summary': x.get('summary'),
                'htmlLink': x.get('htmlLink'),
                'start': event_time(x.get('start')),
                'end': event_time(x.get('end')),
            }
            for facebook_id, x in v.items()
        ]
        for k, v in sync.responses.items()
    }
    return resp


if __name__ == '__main__':
    event = handler({'dryrun': True})
