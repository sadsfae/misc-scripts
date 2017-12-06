## Flask Mattermost API for an EQDKP2 Webhook

* ```mattermost-dkpbot.py``` Flask app that runs an simple API to query with a
  Mattermost outgoing webhook.

* ```report-dkp-webhook.sh``` Shell script that queries EQDKP2 (tested on 2.2)
  which pulls in character name and matching DKP points.

### Installation

* Clone the repository
* Edit your ```dkp_url``` variable in ```report-dkp-webhook.sh```
* Run the Python application via ```python mattermost-dkpbot.py```
   - You might want to run this via a systemd service or init script once you're happy with it.

### Mattermost Server Settings

* System Console -> Developer Settings -> Allow untrusted internal connections to: ```localhost```
* System Console -> Custom Integrations -> Enable integrations to override usernames: ```true```
* System Console -> Enable integrations to override profile picture icons: ```true```

### Webhook Settings

* Main Menu -> Integrations -> Outgoing Webhook
  - Add Outgoing Webhook
  - Content-type: ```application/json```
  - Trigger When: ```First word matches a trigger word exactly```
  - Callback URLs:  ```http://localhost:8098/getdkp```

### Action Pic

![getdkp](/image/getdkp.png?raw=true)
