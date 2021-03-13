import json
import logging
import os

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
    Lambda logger adapter.
    """
    def __init__(self, name, level=None, format_string=None):
        # Get logger, formatter
        logger = logging.getLogger(name)

        # Set log level
        logger.setLevel(level or LOG_LEVEL)

        # Set handler if necessary
        if not logger.handlers:  # and not logger.parent.handlers:
            formatter = logging.Formatter(format_string or LOG_FORMAT)
            handler = logging.StreamHandler()
            handler.setFormatter(formatter)
            logger.addHandler(handler)

        # Suppress AWS logging for this logger
        for handler in logging.root.handlers:
            logFilter = SuppressFilter(name)
            handler.addFilter(logFilter)

        # Initialize adapter with null RequestId
        super().__init__(logger, dict(awsRequestId='-'))

    def attach(self, handler):
        """
        Decorate Lambda handler to attach logger to AWS request.

        :Example:

        >>> logger = lambo.getLogger(__name__)
        >>>
        >>> @logger.attach
        ... def handler(event, context):
        ...     logger.info('Hello, world!')
        ...     return {'ok': True}
        ...
        >>> handler({'fizz': 'buzz'})
        >>> # => INFO RequestId: {awsRequestId} EVENT {"fizz": "buzz"}
        >>> # => INFO RequestId: {awsRequestId} Hello, world!
        >>> # => INFO RequestId: {awsRequestId} RETURN {"ok": True}
        """
        def wrapper(event=None, context=None):
            try:
                self.addContext(context)
                self.info('EVENT %s', json.dumps(event, default=str))
                result = handler(event, context)
                self.info('RETURN %s', json.dumps(result, default=str))
                return result
            finally:
                self.dropContext()
        return wrapper

    def addContext(self, context=None):
        """
        Add runtime context to logger.
        """
        try:
            awsRequestId = f'RequestId: {context.aws_request_id}'
        except AttributeError:
            awsRequestId = '-'
        self.extra.update(awsRequestId=awsRequestId)
        return self

    def dropContext(self):
        """
        Drop runtime context from logger.
        """
        self.extra.update(awsRequestId='-')
        return self


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


LOG_LEVEL = os.getenv('LAMBO_LOG_LEVEL') or logging.INFO
LOG_FORMAT = os.getenv('LAMBO_LOG_FORMAT') \
    or '%(levelname)s %(awsRequestId)s %(message)s'

FACEBOOK_SECRET = os.environ['FACEBOOK_SECRET']
GOOGLE_SECRET = os.environ['GOOGLE_SECRET']

FACEBOOK_PAGE_ID = os.getenv('FACEBOOK_PAGE_ID')
GOOGLE_CALENDAR_ID = os.getenv('GOOGLE_CALENDAR_ID')

# Init Logger
logger = LambdaLoggerAdapter('facebook-gcal-sync')

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
