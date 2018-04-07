#!/usr/bin/env python
# -*- coding: iso-8859-1 -*-

"""
This is a very basic server application that receives Mattermost slash commands.
Set up your slash commands as described in http://docs.mattermost.com/developer/slash-commands.html

This should call 'report-dkp.sh', parse the results and reply with a proper JSON
response hopefully

"""

from BaseHTTPServer import BaseHTTPRequestHandler
import urlparse
import json

# Define server address and port, use localhost if you are running this on your Mattermost server.
HOSTNAME = 'localhost'
PORT = 8089

# guarantee unicode string
_u = lambda t: t.decode('UTF-8', 'replace') if isinstance(t, str) else t


class MattermostRequest(object):
    """
    This is what we get from Mattermost
    """
    def __init__(self, response_url=None, text=None, token=None, channel_id=None, team_id=None, command=None,
                 team_domain=None, user_name=None, channel_name=None):
        self.response_url = response_url
        self.text = text
        self.token = token
        self.channel_id = channel_id
        self.team_id = team_id
        self.command = command
        self.team_domain = team_domain
        self.user_name = user_name
        self.channel_name = channel_name


class PostHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        """Respond to a POST request."""
        # Extract the contents of the POST
        length = int(self.headers['Content-Length'])
        post_data = urlparse.parse_qs(self.rfile.read(length).decode('utf-8'))

        # Get POST data and initialize MattermostRequest object
        for key, value in post_data.iteritems():
            if key == 'response_url':
                MattermostRequest.response_url = value
            elif key == 'text':
                MattermostRequest.text = value
            elif key == 'token':
                MattermostRequest.token = value
            elif key == 'channel_id':
                MattermostRequest.channel_id = value
            elif key == 'team_id':
                MattermostRequest.team_id = value
            elif key == 'command':
                MattermostRequest.command = value
            elif key == 'team_domain':
                MattermostRequest.team_domain = value
            elif key == 'user_name':
                MattermostRequest.user_name = value
            elif key == 'channel_name':
                MattermostRequest.channel_name = value

        responsetext = ''

        # Triggering the token is possibly more failure-resistant and secure:
        # if MattermostRequest.token == '<your token from Mattermost slash integration>':
        #    responsetext = do_some_thing(MattermostRequest.text, MattermostRequest.user_name)
        # elif MattermostRequest.token == '<another token from Mattermost slash integration>':
        #    responsetext = do_some_other_thing(MattermostRequest.text, MattermostRequest.user_name)
        # Here we trigger the command
        if MattermostRequest.command[0] == u'/getdkp':
            responsetext = dosomething(MattermostRequest.text, MattermostRequest.user_name)

        if responsetext:
            data = {}
            # 'response_type' may also be 'in_channel'
            data['response_type'] = 'ephemeral'
            data['text'] = responsetext
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(data))
        return

def obtain_dkp(text, username):
    username = ''.join(username).encode('latin1')
    text = ''.join(text).encode('latin1')
    answer = subprocess.check_output(['./report-dkp.sh text'])
    #print("the answer is {}".format(answer))
    return u'#### Hello ' + username + '!\n : `' + text + "`."

if __name__ == '__main__':
    from BaseHTTPServer import HTTPServer
    server = HTTPServer((HOSTNAME, PORT), PostHandler)
    print('Starting DKP query server, use <Ctrl-C> to stop')
    server.serve_forever()
