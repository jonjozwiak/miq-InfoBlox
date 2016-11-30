# miq-InfoBlox

## General Information

| Name      | miq-InfoBlox |
| --- | --- | --- |
| License   | GPL v2 (see LICENSE file) |
| Version   | 1.0 |

## Author
| Name      | E-mail |
| --- | --- |
| John Hardy | jahrdy@redhat.com |
| Kevin Morey | kmorey@redhat.com |

## Packager
| Name              | E-mail |
| --- | --- |
| Jose Simonelli    | jose@redhat.com |


## Install
1) Download import/export rake scripts
```
cd /tmp

if [ -d cfme-rhconsulting-scripts-master ] ; then
    rm -fR /tmp/cfme-rhconsulting-scripts-master
fi

wget -O cfme-rhconsulting-scripts.zip https://github.com/rhtconsulting/cfme-rhconsulting-scripts/archive/master.zip
unzip cfme-rhconsulting-scripts.zip
cd cfme-rhconsulting-scripts-master
make install
```

2) Install {project-name} on appliance
```
PROJECT_NAME="miq-InfoBlox"
PROJECT_ZIP="https://github.com/rhtconsulting/miq-InfoBlox/archive/master.zip"
cd /tmp
wget -O ${PROJECT_NAME}.zip ${PROJECT_ZIP}
unzip ${PROJECT_NAME}.zip
cd ${PROJECT_NAME}-master
sh install.sh
```

## Usage
Setup Infoblox login credentials in automate.  

* Automate -> Explorer
* Datastore -> miq-Marketplace -> Integration -> Infoblox
* On the DynamicDropDown class, click the Schema tab
  * Configuration -> Edit the selected Schema
  * Update the servername, user, password, and api_version to match your environment.  If this schema has dns_domain and view you will want to update those as well.  (you can get the api version from https://infoblox_fqdn/wapidoc/.  For example v1.7.1, v2.2.2, etc)
* Repeat for the 'Methods' and 'StateMachines' classes
* In the Methods class, select the InfoBlox_AcquireIPAddress method (not the instance, and edit it's code.  
  * Find the get_network section and update to include your network details.  

Update your provisioning state machine to reference Infoblox
* Select ManageIQ->Infrastructure->VM->Provisioning->StateMachines->VMProvision_VM->Provision VM from Template (template)
  * If you have other domains, make certain you haven't already overridden this!  
* Configuration -> Copy this instance (if you don't already have a copy)
* Edit the AcquireIPAddress instance.  Point it to /Integration/Infoblox/Methods/InfoBlox_AcquireIPaddress


Repeat for your retirement state machine
* Go to Automate -> Explorer
* Select ManageIQ->Infrastructure->VM->Retirement->StateMachines->VMRetirement->Default
  * Again, if you have other domains, check for an override
* Configuration -> Copy this instance...  (from the highest domain)
* Edit the ReleaseIPAddress instance.  Point it to /Integration/Infoblox/Methods/InfoBlox_ReclaimIPaddress

Create a Service Dialog 
* It should have an element named 'option_1_network_cidr' with values/description like '192.168.209.0/24', '192.168.210.0/24', etc.

Create a Catalog / Catalog Item 
* Use the dialog you created 
* Provisioning entry point should be /Service/Provisioning/StateMachines/ServiceProvision_Template/CatalogItemInitialization
  * A customization specification is needed to actually apply the IP to the OS 


