#!/usr/bin/env python
import os
import requests
import json
import subprocess
from urlparse import urlsplit,urlunsplit
from flask import Flask
from flask import request
from flask import Response
from flask import jsonify

app = Flask(__name__)

# ensure unicode is used
_u = lambda t: t.decode('UTF-8', 'replace') if isinstance(t, str) else t

@app.route('/getdkp', methods = ['GET', 'POST'])
def getdkp():
    if request.method == 'GET':
        request_data = request.get_data()
        # if you want to use GET put stuff here
        return "this is a GET request"
    
    if request.method == 'POST':
        request_data = request.args.get('text')
        request_json = request.get_json(force=True)
        player_name = str(request_json["text"])
        # eqdkp2 scraper, player_name is sent as an arg to webhook command
        playerproc = subprocess.Popen(["sh","./report-dkp.sh", player_name],
                                      stdout=subprocess.PIPE)
        playerout = playerproc.stdout.read()
        response = app.response_class(response=str(playerout), status=200,
                                      mimetype="application/json")
        return response
    else:
        return "405 Method Not Allowed"

@app.route('/')
def root():
    """
    Home handler
    """
    return "OK"

# Python wsgi server options
if __name__ == "__main__":
    port = int(os.environ.get('MATTERMOST_DKP_PORT', 8089))
    # use 0.0.0.0 if it shall be accessible from outside of host
    app.run(host='127.0.0.1', port=port)
