#!/usr/bin/env python
# simple flask app / API that can serve an outgoing webhook for Mattermost
# acts as a simple dice roller
import os
import sys
import requests
import json
import subprocess
import random
from urlparse import urlsplit,urlunsplit
from flask import Flask
from flask import request
from flask import Response
from flask import jsonify

app = Flask(__name__)

USERNAME="vegas"

_u = lambda t: t.decode('UTF-8', 'replace') if isinstance(t, str) else t

def is_int(s):
    try:
        int(s)
        return True
    except ValueError:
        return False

@app.route('/hotdice', methods = ['GET', 'POST'])
def hotdice():
    if request.method == 'GET':
        """return the information for <user_id>"""
        request_data = request.get_data()
        return "nothing here\n"
        # your code goes here.
    if request.method == 'POST':
        """modify/update the information for <user_id>"""
        request_json = request.get_json(force=True)
        text_input = str(request_json["text"])
	dicerange_array=text_input.split()
	if len(dicerange_array) > 1:
          dicerange=str(dicerange_array[1])
          if not is_int(dicerange):
            dicerange='1000'
        else:
          dicerange='1000'
        user_name = str(request_json["user_name"])
        diceroll = random.randint(0, int(dicerange))
        diceroll_result = user_name + " rolled a %s out of %s" % (str(diceroll), str(dicerange))
        diceroll_out = {"response_type": "ephemeral", "icon_url":
                        "https://funcamp.net/w/dice.png", "username":
                        "vegas", "text": diceroll_result}
        response = app.response_class(response=json.dumps(diceroll_out) + '\n', status=200, mimetype="application/json")
        return response
    else:
        return "405 Method Not Allowed"

@app.route('/')
def root():
    """
    Home handler
    """

    return "OK"

if __name__ == "__main__":
    # wsgi server options
    USERNAME = os.environ.get('USERNAME', USERNAME)
    port = int(os.environ.get('MATTERMOST_DKP_PORT', 8090))
    # use 0.0.0.0 if it shall be accessible from outside of host
    app.run(host='127.0.0.1', port=port)
