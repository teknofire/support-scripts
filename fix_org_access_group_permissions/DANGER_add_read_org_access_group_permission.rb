#!/opt/opscode/embedded/bin/ruby
# Usage: ./DANGER_add_read_org_access_group_permission.rb ORGNAME USERNAME
# Description: This script will manually add the correct db entries for
#              the given org and user to allow read access to members of the
#              ORGNAME_read_access_group
# Author: Will Fisher <will@chef.io>

require 'sequel'
require 'json'

orgname = ARGV[0]
username = ARGV[1]
if orgname.nil?
  STDERR.puts "usage: DANGER_add_read_org_access_group_permission.rb ORGNAME USERNAME"
  STDERR.puts "Please specify an organization name."
  exit 1
end

if username.nil?
  STDERR.puts "usage: DANGER_add_read_org_access_group_permission.rb ORGNAME USERNAME"
  STDERR.puts "Please specify an username."
  exit 1
end

running_config = JSON.parse(File.read("/etc/opscode/chef-server-running.json"))

db_user = running_config['private_chef']['postgresql']['username']
db_password = JSON.parse(`/opt/opscode/embedded/bin/veil-dump-secrets /etc/opscode/private-chef-secrets.json`)['postgresql']['db_superuser_password']
db_host = running_config['private_chef']['postgresql']['listen_address']

@db = Sequel.connect(:adapter => 'postgres', :host => db_host,
                     :database => 'opscode_chef', :user => db_user,
                     :password => db_password, :convert_infinite_timestamps => :float)

read_access_group_authz_id = @db[:groups].select(:authz_id).where(:name => "#{orgname}_read_access_group", :org_id => '00000000000000000000000000000000').first[:authz_id]
user_authz_id = @db[:users].select(:authz_id).where(:username => "#{username}").first[:authz_id]

@bifrost_db = Sequel.connect(:adapter => 'postgres', :host => db_host,
                     :database => 'bifrost', :user => db_user,
                     :password => db_password, :convert_infinite_timestamps => :float)

group_id = @bifrost_db[:auth_group].select(:id).where(authz_id: read_access_group_authz_id).first[:id]
user_id = @bifrost_db[:auth_actor].select(:id).where(authz_id: user_authz_id).first[:id]
if !group_id || !user_id
  STDERR.puts "ERROR: Unable to find the group_id and/or user_id for the given org and username."
  exit 1
end

puts "Found group and user id's"

permission_check = @bifrost_db[:actor_acl_group].where(target: user_id, authorizee: group_id, permission: 'read').count

if permission_check == 0
  puts "Adding read permission for #{orgname}_read_access_group and #{username}"
  @bifrost_db[:actor_acl_group].insert(target: user_id, authorizee: group_id, permission: 'read')
else
  puts "The read permission already exists for #{orgname}_read_access_group and #{username}"
end
