#!/usr/bin/python

import json
import sys
import urllib2

def main(args):
    """ Main function """

    if len(args) < 2:
        print "Usage: <jenkins_host> <jenkins_project>"
        sys.exit(1)

    jenkins_host = args[0]
    jenkins_project = args[1]
    jenkins_url = '{}/job/{}/lastBuild/api/json'.format(jenkins_host, jenkins_project)
    res_json = None
    try:
        res = urllib2.urlopen(jenkins_url)
        res_json = json.load(res)
    except urllib2.HTTPError as err:
        print "URL error: {}".format(err)
        sys.exit(2)
    except ValueError as err:
        print "Error: {}".format(err)
        sys.exit(3)

    build_result = res_json.get('result', '')
    build_timestamp = res_json.get('timestamp', 0)
    commit_items = res_json.get('changeSet', {}).get('items', [{}])
    commit_timestamps = [x['timestamp'] for x in commit_items]
    commit_timestamp = max(commit_timestamps)
    if len(str(build_timestamp)):
        build_timestamp = build_timestamp / 1000
    if len(str(commit_timestamp)):
        commit_timestamp = commit_timestamp / 1000
    delta = commit_timestamp - build_timestamp

    if build_result != 'SUCCESS':
        print "Latest build was not succesfull."
        sys.exit(4)

    print "[{}] latest build status: {}".format(jenkins_project, build_result)
    sys.exit(0)

if __name__ == '__main__':
    main(sys.argv[1:])
