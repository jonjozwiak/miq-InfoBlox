###################################
#
# CFME Automate Method: RestartGridServices
#
# Author: Kevin Morey
#
# Notes: This method attempts to restart Infoblox Grid Services
# gem requirements: 'rest_client', 'nori', 'json'
#
###################################
begin
  # Method for logging
  def log(level, msg, update_message=false)
    @method = 'RestartGridServices'
    $evm.log(level, "#{@method} - #{msg}")
    $evm.root['miq_provision'].message = "#{@method} - #{msg}" if $evm.root['miq_provision'] && update_message
  end

  # dump_root
  def dump_root()
    log(:info, "Root:<$evm.root> Begin $evm.root.attributes")
    $evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}
    log(:info, "Root:<$evm.root> End $evm.root.attributes")
    log(:info, "")
  end

  # call_infoblox
  def call_infoblox(action, ref='grid', content_type=:xml, body=nil )
    require 'rest_client'
    require 'nori'
    require 'json'

    servername = nil || $evm.object['servername']
    username = nil || $evm.object['username']
    password = nil || $evm.object.decrypt('password')
    api_version = nil || $evm.object['api_version']
    url = "https://#{servername}/wapi/#{api_version}/"+"#{ref}"

    params = {
      :method=>action,
      :url=>url,
      :user=>username,
      :password=>password,
      :verify_ssl=>false,
      :headers=>{ :content_type=>content_type, :accept=>:xml }
    }
    content_type == :json ? (params[:payload] = JSON.generate(body) if body) : (params[:payload] = body if body)
    log(:info, "Calling -> Infoblox: #{url} action: #{action} payload: #{params[:payload]}")
    response = RestClient::Request.new(params).execute
    raise "Failure <- Infoblox Response: #{response.code}" unless response.code == 200 || response.code == 201
    # use Nori to convert xml to ruby hash
    response_hash = Nori.new.parse(response)
    log(:info, "Return code: #{response.code} response_hash: #{response_hash.inspect}")
    return response_hash
  end

  log(:info, "CFME Automate Method Started", true)

  # dump all root attributes to the log
  #dump_root()

  # call infoblox to get the grid ref
  grid_response = call_infoblox(:get, 'grid')
  raise "grid_response returned nil" if grid_response.nil?
  grid_ref = grid_response['value'][0]['_ref'][0]
  log(:info, "grid_ref: #{grid_ref}")

  restart_ref = grid_ref + "?_function=restartservices"

  # call Infoblox to get the next available IP Address
  body_restart_grid = { :member_order => "SEQUENTIALLY", :restart_option => "RESTART_IF_NEEDED", :sequential_delay => 10, :service_option => "ALL" }
  call_infoblox(:post, restart_ref, :json, body_restart_grid)
  log(:info, "Successfully restarted Infoblox grid services", true)

  # Exit method
  log(:info, "CFME Automate Method Ended", true)
  exit MIQ_OK

  # Set Ruby rescue behavior
rescue => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
