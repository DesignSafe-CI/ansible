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

  * Should be configured outside the playbook, e.g. /designsafe/ansible/hosts
  * A template for this is available ?here? [[TODO]]

* Ansible variables Variables for deployment targets

  * Should be configured outside the playbook, e.g. /designsafe/ansible/variables/variables.yml
  * A template for this is available ?here? [[TODO]]

Configuration
+++++++++++++

Inventory
---------

Before you can use these playbooks you will need to configure your Ansible inventory and
setup your variables file(s). The default inventory location is ``/etc/ansible/inventory``.
The ``ansible.cfg`` file located at the root of this repository sets the inventory file
location to ``~/.ansible/hosts``. To use this config file either a) run playbooks from the
root of this repository or b) copy the ``ansible.cfg`` file to ``$HOME``.

Variables
---------

Variables files for each playbook should be placed in the directory
``~/.ansible/designsafe/vars/``.


Playbooks
+++++++++

The following playbooks are available. For each is listed the inventory group and
variables file that will be activated when you run the associated playbook.

DesignSafe Main Portal
----------------------

Production
''''''''''

Inventory group: ``designsafe_portal_prod``
Variables file: ``~/.ansible/designsafe/vars/portal_prod.yml``
Playbook: ``playbooks/portal_prod.yml``

QA/Testing
''''''''''

Inventory group: ``designsafe_portal_qa``
Variables file: ``~/.ansible/designsafe/vars/portal_qa.yml``
Playbook: ``playbooks/portal_qa.yml``

DesignSafe EF Sites
-------------------

Inventory group: ``designsafe_ef_prod``
Variables file: ``~/.ansible/designsafe/vars/portal_prod.yml``
Playbook: ``playbooks/ef_prod.yml``


Elasticsearch cluster
---------------------

TODO

DesignSafe VCoP Forums
----------------------

TODO


