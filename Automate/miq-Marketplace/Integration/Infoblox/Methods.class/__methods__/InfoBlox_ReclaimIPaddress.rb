#CFME Automate Method: Infoblox_ReclaimPAddress
#
###################################
begin
  # Method for logging
  def log(level, msg, update_message=false)
    $evm.log(level, "#{msg}")
    $evm.root['miq_provision'].message = "#{msg}" if $evm.root['miq_provision'] && update_message
  end

  # dump_root
  def dump_root()
    log(:info, "Root:<$evm.root> Begin $evm.root.attributes")
    $evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")} if $evm.root
    log(:info, "Root:<$evm.root> End $evm.root.attributes")
    log(:info, "")
  end

  def call_infoblox(action, ref='record:host', content_type=:xml, body=nil )
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
    log(:info, "Inspecting response: #{response.inspect}")
    raise "Failure <- Infoblox Response: #{response.code}" unless response.code == 200 || response.code == 201 || response.code == 202 || response.code == 203

    # use Nori to convert xml to ruby hash
    response_hash = Nori.new.parse(response)
    log(:info, "Inspecting response_hash: #{response_hash.inspect}")
    return response_hash
  end

  log(:info, "CFME Automate Method Started", true)


  vm = $evm.root['vm']
  domain_name = $evm.object['dns_domain']


  log(:info, "Releasing IP Address for #{vm.name}.#{domain_name}", true)

  query_name_response = call_infoblox(:get, "record:host?name=#{vm.name}.#{domain_name}")

  #name_ref = query_name_response["value"][0]["_ref"][0]
  name_ref = query_name_response["list"]["value"]["_ref"]


  log(:info, "Releasing ref: #{name_ref}")

  release_ipaddress = call_infoblox(:delete, "#{name_ref}")



  # Exit method
  log(:info, "CFME Automate Method Ended")
  exit MIQ_OK

  # Set Ruby rescue behavior
rescue => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end
