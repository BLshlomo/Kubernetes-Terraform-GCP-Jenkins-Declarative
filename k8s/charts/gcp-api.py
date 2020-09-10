from google_auth_oauthlib import flow

# TODO: Uncomment the line below to set the `launch_browser` variable.
launch_browser = False
#
# The `launch_browser` boolean variable indicates if a local server is used
# as the callback URL in the auth flow. A value of `True` is recommended,
# but a local server does not work if accessing the application remotely,
# such as over SSH or from a remote Jupyter notebook.

# appflow = flow.InstalledAppFlow.from_client_secrets_file(
#     "client_secrets.json", scopes=["https://www.googleapis.com/auth/cloud-platform"]
# )

# if launch_browser:
#     appflow.run_local_server()
# else:
#     appflow.run_console()

#credentials = appflow.credentials


"""
BEFORE RUNNING:
---------------
1. If not already done, enable the Google Cloud DNS API
   and check the quota for your project at
   https://console.developers.google.com/apis/api/dns
2. This sample uses Application Default Credentials for authentication.
   If not already done, install the gcloud CLI from
   https://cloud.google.com/sdk and run
   `gcloud beta auth application-default login`.
   For more information, see
   https://developers.google.com/identity/protocols/application-default-credentials
3. Install the Python client library for Google APIs by running
   `pip install --upgrade google-api-python-client`
"""
from pprint import pprint

from googleapiclient import discovery
from oauth2client.client import GoogleCredentials

import google.auth

#credentials = GoogleCredentials.get_application_default()

credentials, project = google.auth.default()

# credentials, project = google.auth.default(
#   scopes=['https://www.googleapis.com/auth/cloud-platform']
# )

print ("cred = ", credentials)
print ("proj = ", project)

service = discovery.build('dns', 'v1', credentials=credentials)

# Identifies the project addressed by this request.
#project = 'devel-final'  # TODO: Update placeholder value.

request = service.managedZones().list(project=project)
while request is not None:
    response = request.execute()

    for managed_zone in response['managedZones']:
        # TODO: Change code below to process each `managed_zone` resource:
        pprint(managed_zone)

    request = service.managedZones().list_next(previous_request=request, previous_response=response)