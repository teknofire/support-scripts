# support-scripts

Quick collection of scripts used to fix various support issues

## fix_org_access_group_permission

If a user in the admin group is getting a `missing read permission` error when trying to access user information it probably means that the user is missing the `#{ORGNAME}_access_group` read permission on their global ACL.

You can check this using a command like this from the chef-server

```
$ knife raw /users/USERNAME/_acl -s https://CHEFSERVER.HOSTNAME -u pivotal -k /etc/opscode/pivotal.pem

{
  "create": {
    "actors": [
      "USERNAME",
      "pivotal"
    ],
    "groups": [
      "::server-admins"
    ]
  },
  "read": {
    "actors": [
      "USERNAME",
      "pivotal"
    ],
    "groups": [
      "::foo_read_access_group",
      "::server-admins"
    ]
  },
  "update": {
    "actors": [
      "USERNAME",
      "pivotal"
    ],
    "groups": [
      "::server-admins"
    ]
  },
  "delete": {
    "actors": [
      "USERNAME",
      "pivotal"
    ],
    "groups": [
      "::server-admins"
    ]
  },
  "grant": {
    "actors": [
      "USERNAME",
      "pivotal"
    ],
    "groups": [

    ]
  }
}

```
### Adding read permission for #{ORGNAME}_access_group on the users global ACL

This script will check to see if the #{ORGNAME}_access_group exists and add it to the users read permission global ACL (`/users/USERNAME/_acl`). It will then directly modify the bifrost database adding the missing relationship row since there is no API available to update this setting.  Another possible work around is to remove the user from the org and then re-add them back.

**NOTE: This script will need to be run from the chef-server or a chef-server-frontend with root permissions to access the necessary secrets for database access.**

**USAGE:** `DANGER_add_read_org_access_group_permission.rb ORGNAME USERNAME`
