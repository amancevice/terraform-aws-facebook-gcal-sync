import json
import logging
import os
import sys

import boto3
import facebook
from google.oauth2 import service_account
from googleapiclient import discovery

import fest


class SuppressFilter(logging.Filter):
    """
    Suppress Log Records from registered logger

    Taken from ``aws_lambda_powertools.logging.filters.SuppressFilter``
    """
    def __init__(self, logger):
        self.logger = logger

    def filter(self, record):
        logger = record.name
        return False if self.logger in logger else True


class LambdaLoggerAdapter(logging.LoggerAdapter):
    """
    Lambda logger adapter
    """
    LOG_LEVEL = os.getenv('LOG_LEVEL') or 'INFO'
    LOG_FORMAT = os.getenv('LOG_FORMAT') \
        or '%(levelname)s %(reqid)s %(message)s'

    def __init__(self, name, level=None, format_string=None):
        # Get logger, formatter
        logger = logging.getLogger(name)
        formatter = logging.Formatter(format_string or self.LOG_FORMAT)

        # Set formatter for this logerr's handler(s)
        for handler in logger.handlers:  # pragma: no cover
            handler.setFormatter(formatter)
        else:
            handler = logging.StreamHandler(sys.stdout)
            handler.setFormatter(formatter)
            logger.addHandler(handler)

        # Suppress AWS logging for this logger
        for handler in logging.root.handlers:
            handler.addFilter(SuppressFilter(name))

        # Initialize adapter with null RequestId
        super().__init__(logger, dict(reqid='-'))

        # Set log level
        self.setLevel(level or self.LOG_LEVEL)

    def addContext(self, context=None):
        """
        Add runtime context to logger
        """
        try:
            reqid = f'RequestId: {context.aws_request_id}'
            self.extra.update(reqid=reqid)
        except AttributeError:  # pragma: no cover
            pass

    def setup(self, event, context):
        self.addContext(context)
        self.info('EVENT %s', json.dumps(event))


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


logger = LambdaLoggerAdapter('facebook-gcal-sync')

FACEBOOK_SECRET = os.environ['FACEBOOK_SECRET']
GOOGLE_SECRET = os.environ['GOOGLE_SECRET']

FACEBOOK_PAGE_ID = os.getenv('FACEBOOK_PAGE_ID')
GOOGLE_CALENDAR_ID = os.getenv('GOOGLE_CALENDAR_ID')

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


def handler(event, context=None):
    logger.setup(event, context)

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
