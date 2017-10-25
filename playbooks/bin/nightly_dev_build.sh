#!/bin/bash
PIDFILE=/home/designsafe/.nigtly_dev_build.pid
SLACK_WEBHOOK=$DEV_BUILD_SLACK_WEBHOOK

#Setting ansible.cfg
export ANSIBLE_CONFIG=$HOME/ansible/ansible.cfg

# Check for pid file and for a job running with the same pid
if [ -f $PIDFILE ]
then
  PID=$(cat $PIDFILE)
  ps -p $PID > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "Job is already running with PID: ${PID} using PIDFILE: ${PIDFILE}"
    exit 1
  fi
fi

# Create PIDFILE
echo $$ > $PIDFILE
if [ $? -ne 0 ]
then
  echo "Could not create PID file at ${PIDFILE}"
  exit 1
fi

# Get list of remote dev tags
# We knoe the dev tags are in the form YYYYMM##
# Where:
# YYYY = 4 digit year
# MM = 2 digit month
# ## = 2 digit number of release of the month
# e.g. 20171006 - 6th release of October/2017
LATEST=$(git ls-remote https://github.com/DesignSafe-CI/portal.git | grep -e 'refs\/tags\/[0-9]\{8\}\^' | sed "s/refs\/tags\/\([0-9]*\).*/\1/g" | awk '{print $2}' | sort -r | sed -n 1p)
echo "Latest tag in GIT repo ${LATEST}"

#Check latest tag in docker hub
REMOTE_LATEST=$(wget -q https://registry.hub.docker.com/v1/repositories/designsafeci/portal/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}' | grep -e '[0-9]\{8\}' | sort -r | sed -n 1p)
echo "Latest docker image tag in docker hub ${REMOTE_LATEST}"

# Check if latest tag is greater than remote docker hub tag.
# If it's only different maybe a tag was deleted from the GIT repo.
# Something like that should need a manual intervention.
push_release=false

# If year or month is greater do a push release
if [ "${LATEST:0:4}" -gt "${REMOTE_LATEST:0:4}" ] || [ "${LATEST:4:2}" -gt "${REMOTE_LATEST:4:2}" ]
then
  echo "Latest version is greater than docker hub latest tag"
  push_release=true
else
  # If year and month are equal check if number of release is greater
  if [ "${LATEST:0:4}" -eq "${REMOTE_LATEST:0:4}" -a "${LATEST:4:2}" -eq "${REMOTE_LATEST:4:2}" ] && [ "${LATEST:6:2}" -gt "${REMOTE_LATEST:6:2}" ] 
  then
    echo "Latest version is greater than docker hub latest tag"
    push_release=true
  else
    echo "Latest tag is either less than or equals docker hub tag: $LATEST <= $REMOTE_LATEST"
  fi
fi

# Do a release if needed
revert_release=false
if [ "$push_release" = true ]
then
  echo "Modifying group_vars to point to the newest tag"
  echo "s/version: \"[0-9]\{8\}\"/version: \"$LATEST\"/g"
  /bin/sed -i "s/version: \"[0-9]\{8\}\"/version: \"$LATEST\"/g" $DEV_BUILD_ANSIBLE_VARS

  echo "Doing a release using $LATEST tag"
  ANSIBLE_CONFIG=$HOME/ansible/ansible.cfg /bin/ansible-playbook $HOME/ansible/playbooks/portal_qa.yml --limit=worker-dev
  out=$?
  if [ $out -eq 0 ]
  then
    ANSIBLE_CONFIG=$HOME/ansible/ansible.cfg /bin/ansible-playbook $HOME/ansible/playbooks/portal_qa.yml --limit=portal-dev
    out=$?
  fi

  #Check if last command went OK
  if [ $out -ne 0 ]
  then
    revert_release=true
    echo "posting slack fail"
    /bin/curl -XPOST "$SLACK_WEBHOOK" --data "{ \
      \"username\": \"Dev Release Bot\", \
      \"icon_emoji\": \":meeseks:\", \
      \"attachments\": [ \
        {
           \"fallback\": \"dev release FAIL with image: designsafeci/portal:$LATEST. Rolling back.\",
           \"color\": \"ff6363\",
	       \"pretext\": \"FAIL\",
           \"title\": \"Dev Release\",
           \"text\": \"dev release FAIL with image: designsafeci/portal:$LATEST. Rolling back.\nPlease make sure group vars are updated as needed.\"
        }
      ] \
      }"
  else
    /bin/curl -XPOST "$SLACK_WEBHOOK" --data "{ \
      \"username\": \"Dev Release Bot\", \
      \"icon_emoji\": \":meeseks:\", \
      \"attachments\": [ \
        {
           \"fallback\": \"New dev release SUCCESS with image: designsafeci/portal:$LATEST\",
           \"color\": \"67efb2\",
	       \"pretext\": \"SUCCESS\",
           \"title\": \"Dev Release\",
           \"text\": \"New dev release SUCCESS with image: designsafeci/portal:$LATEST\"
        }
      ] \
      }"
  fi

fi

# Revert release if something went wrong
if [ "$revert_release" = true ]
then
  echo "Rolling back release to tag $REMOTE_LATEST because something went wrong"
  echo "Modifying group_vars to point to the newest tag"
  echo "s/version: \"[0-9]\{8\}\"/version: \"$REMOTE_LATEST\"/g"
  /bin/sed -i "s/version: \"[0-9]\{8\}\"/version: \"$REMOTE_LATEST\"/g" $DEV_BUILD_ANSIBLE_VARS
  ANSIBLE_CONFIG=$HOME/ansible/ansible.cfg /bin/ansible-playbook $HOME/ansible/playbooks/portal_qa.yml --limit=worker-dev 
  out=$?
  if [ $out -eq 0 ]
  then
    ANSIBLE_CONFIG=$HOME/ansible/ansible.cfg /bin/ansible-playbook $HOME/ansible/playbooks/portal_qa.yml --limit=portal-dev
    out=$?
  fi
  #Check if last command went OK
  if [ $out -ne 0 ]
  then
    echo "Something is terribly wrong, immidate action needed!"
    /bin/curl -XPOST "$SLACK_WEBHOOK" --data "{ \
      \"username\": \"Dev Release Bot\", \
      \"icon_emoji\": \":meeseks:\", \
      \"attachments\": [ \
        {
           \"fallback\":\"dev rollback FAIL with image: designsafeci/portal:$REMOTE_LATEST. \n Something went terribly wrong. Somebody do something!\",
           \"color\": \"ff6363\",
	       \"pretext\": \"FAIL\",
           \"title\": \"Dev Release\",
           \"text\":\"dev rollback FAIL with image: designsafeci/portal:$REMOTE_LATEST. \n Something went terribly wrong. Somebody do something!\"
        }
      ] \
      }"
  else
    /bin/curl -XPOST "$SLACK_WEBHOOK" --data "{ \
      \"username\": \"Dev Release Bot\", \
      \"icon_emoji\": \":meeseks:\", \
      \"attachments\": [ \
        {
           \"fallback\": \"dev rollback SUCCESS  with image: designsafeci/portal:$REMOTE_LATEST. \n There's still something weird with designsafeci/portal:$LATEST image! \",
           \"color\": \"67efb2\",
	       \"pretext\": \"SUCCESS\",
           \"title\": \"Dev Release\",
           \"text\":\"dev rollback SUCCESS  with image: designsafeci/portal:$REMOTE_LATEST. \n There's still something weird with designsafeci/portal:$LATEST image! \"
        }
      ] \
      }"
  fi
fi

# Removing designsafeci/portal docker images
echo "Removing designsafeci/portal docker images"
/bin/docker images | grep designsafeci/portal | awk '{ print $3 }' | xargs docker rmi

# Remove PIDFILE
rm $PIDFILE
