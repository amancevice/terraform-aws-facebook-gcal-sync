import json
import logging
import os

import boto3
import facebook
from google.oauth2 import service_account
from googleapiclient import discovery

import fest

FACEBOOK_SECRET = os.environ['FACEBOOK_SECRET']
GOOGLE_SECRET = os.environ['GOOGLE_SECRET']

FACEBOOK_PAGE_ID = os.getenv('FACEBOOK_PAGE_ID')
GOOGLE_CALENDAR_ID = os.getenv('GOOGLE_CALENDAR_ID')

# Get facebook/Google secrets
SECRETSMANAGER = boto3.client('secretsmanager')
FACEBOOK_PAGE_TOKEN = \
    SECRETSMANAGER.get_secret_value(SecretId=FACEBOOK_SECRET)['SecretString']
GOOGLE_SERVICE_ACCOUNT = json.loads(
    SECRETSMANAGER.get_secret_value(SecretId=GOOGLE_SECRET)['SecretString']
)
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

# Configure logging
logging.basicConfig(format='%(name)s - %(levelname)s - %(message)s')


def handler(event, *_):
    # Get args from event
    event = event or {}
    dryrun = event.get('dryrun') or False
    page_id = event.get('pageId') or FACEBOOK_PAGE_ID
    cal_id = event.get('calendarId') or GOOGLE_CALENDAR_ID

    # Initialize facebook page & Google Calendar
    page = fest.FacebookPage(GRAPHAPI, page_id)
    gcal = fest.GoogleCalendar(CALENDARAPI, cal_id)
    page.logger.setLevel('INFO')
    gcal.logger.setLevel('INFO')

    # Sync
    sync = gcal.sync(page, time_filter='upcoming').execute(dryrun=dryrun)

    # Return referces to modified objects
    resp = {
        k: [
            {
                'google_id': x.get('id'),
                'summary': x.get('summary'),
                'htmlLink': x.get('htmlLink'),
                'start': x.get('start', {}).get('dateTime'),
                'end': x.get('end', {}).get('dateTime'),
            }
            for facebook_id, x in v.items()
        ]
        for k, v in sync.responses.items()
    }
    return resp


if __name__ == '__main__':
    sync = handler({'dryrun': True})
