Ansible Playbooks for DesignSafe
================================

Ansible playbooks for deploying/managing various components of the DesignSafe-CI.

Prequisites
+++++++++++

Before you can run these playbooks, you will need to make sure the following is all set up
and configured.

Install:

* build-essential
* libssl-dev
* python 2.x
* python-dev
* python-setuptools
* pip
* Ansible 2.x

Configure:

* Host keys for deployment targets
* Host file(s) for deployment targets

  * Should be configured outside the playbook, e.g. ~/.ansible/designsafe/hosts
  * A template for this is available ?here? [[TODO]]

* Ansible variables Variables for deployment targets

  * Should be configured outside the playbook, e.g. ~/.ansible/designsafe/variables.yml
  * A template for this is available ?here? [[TODO]]

Playbooks
+++++++++

The following playbooks are available:

Deploying the Main DS Portal
----------------------------

TODO

Deploying the DS EF Sites
-------------------------

TODO

Deploying the DS Elasticsearch cluster
--------------------------------------

TODO

Deploying the DS Community Forums
---------------------------------

TODO


