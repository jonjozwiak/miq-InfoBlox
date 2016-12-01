# list_infoblox_networks.rb
#
# Author: Kevin Morey <kmorey@redhat.com>
# License: GPL v3
#
# Description: This method is list InfoBlox networks
#
#
require 'rest_client'
require 'json'


def log_and_update_message(level, msg, update_message=false)
  $evm.log(level, "#{msg}")
  @task.message = msg if @task && (update_message || level == 'error')
end

def get_infoblox_networks_hash(network_view)
  # convert networks_array into a nested hash sorted by network_views
  ref = 'network'
  if network_view 
    ref += "?network_view=#{network_view}"   
  end
  networks_array = call_infoblox(:get, ref)
  log_and_update_message(:info, "Inspecting networks_array: #{networks_array.inspect}")
  networks_hash = networks_array.each_with_object(Hash.new { |h, k| h[k] = {} }) {|net, hash| hash[net["network_view"]][net["network"]] = net["_ref"] }
  log_and_update_message(:info, "Inspecting networks_hash: #{networks_hash.inspect}")
  return networks_hash
end

def valid_json?(json)
  begin
    JSON.parse(json)
    return true
  rescue => parserr
    return false
  end
end

def call_infoblox(action, ref='network', body_hash=nil)
  begin
    servername  = nil || $evm.object['servername']
    username    = nil || $evm.object['username']
    password    = nil || $evm.object.decrypt('password')
    api_version = nil || $evm.object['api_version']
    url = "https://#{servername}/wapi/v#{api_version}/"+"#{ref}"
    params = {
      :method=>action, :url=>url,:user=>username, :password=>password,
      :verify_ssl=>false, :headers=>{ :content_type=>:json, :accept=>:json }
    }
    params[:payload] = JSON.generate(body_hash) if body_hash
    log_and_update_message(:info, "Calling -> Infoblox:<#{url}> action:<#{action}> payload:<#{params[:payload]}>")
    response = RestClient::Request.new(params).execute
    raise "Failure code: #{response.code} response:<#{response.inspect}>" unless response.code == 200 || response.code == 201
    valid_json?(response) ? (return JSON.parse(response)) : (return response)
  rescue => badrequest
    raise "Bad url: #{url} or possibly wrong api_version: #{api_version}"
  end
end

dialog_hash = {}
network_view = $evm.object['network_view']

# call infoblox to get a list of networks
network_views_hash = get_infoblox_networks_hash(network_view)
network_views_hash.each do |view, networks|
  networks.each do |net, ref|
    dialog_hash[net] = "#{net} in view #{view}"
  end
end

if dialog_hash.blank?
  dialog_hash[''] = "< No networks found, Contact Administrator >"
else
  #$evm.object['default_value'] = dialog_hash.first
  #dialog_hash[''] = '< choose a network >'
end

$evm.object["values"]     = dialog_hash
$evm.log(:info, "$evm.object['values']: #{$evm.object['values'].inspect}")
