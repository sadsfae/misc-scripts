supybot-excuses
===============
This plugin fetches a BOFH Excuses file from a web server (one excuse per
line), picks a random one, and returns it to the channel when the excuse
command is called.

I use this with a [remote git
repo](https://hobo.house/2016/06/13/secure-distributed-password-resources-with-gpg-git-and-vim/)
and a git post-receive hook like the following to keep the excuses up to date.

```
#!/bin/bash
echo "adding your sweet excuses.."
git --work-tree=/home/repouser/public_html/ --git-dir=/home/repouser/excuses
checkout -f
```
