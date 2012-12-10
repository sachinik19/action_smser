require 'net/http'
require 'net/https'

module ActionSmser::DeliveryMethods

  # Very simple implementation of http request to gateway. Options used are
  # server, use_ssl, username, password
  # overwrite deliver_path(sms, options) with your own if you have different type of path
  class Aql < SimpleHttp
    
    def self.deliver(sms)
      options = sms.delivery_options[:aql] || {}
      options = options.dup

      options[:server] = 'gw.aql.com'
      options[:save_delivery_reports] = false #currently delivery report is not supported.
      options[:use_ssl] ||= true
      #options[:status_report_req] ||= sms.delivery_options[:save_delivery_reports]

      sms.delivery_info = []

      to = sms.to_numbers_array.map{ |num| format_number(num) }.join(',')
      deliver_path = self.deliver_path(sms, to, options)
      response = self.deliver_http_request(sms, options, deliver_path)

      logger.info "Aql delivery http ||| #{deliver_path} ||| #{response.inspect}"
      logger.info response.body if !response.blank?

      sms.delivery_info.push(response)

      result = valid?(response) ? SMSResponse.new(response) : response

      # Results include sms_id or error code in each line
      if sms.delivery_options[:save_delivery_reports]
        dr = ActionSmser::DeliveryReport.build_from_sms(sms, to, result["message-id"])
        if result["status"].to_i > 0
          dr.status = "SENT_ERROR_#{result["status"]}"
          dr.log += "aql_error: #{result["error-text"]}"
        end
        dr.save
        sms.delivery_reports.push(dr)
      end

      sms.delivery_options[:save_delivery_reports] ? sms.delivery_reports : sms.delivery_info
    end

    def self.deliver_path(sms, to, options)
      "/sms/sms_gw.php?username=#{options[:username]}&password=#{options[:password]}&destination=#{to}&message=#{sms.body_escaped}"
    end

    # Callback message status handling
    # This has to return array of hashes. In hash msg_id is the key and other params are updated to db
    def self.process_delivery_report(params)
      processable_array = []
      if msg_id = params["messageId"]
        processable_array << {'msg_id' => params["messageId"], 'status' => params['status']}
      end
      return processable_array
    end

    def self.format_number(num)
      num.gsub(/\D/, "")  # removes all non digit characters
    end

    def self.valid?(res)
      res.code == 200   
    end 
                                                                                                            end


  class SMSResponse
    attr_reader :code, :credits, :message
    
    def initialize(res) 
      parts = res.match(/^([0-9]):(\d+)\s(.+)$/)
      @code = parts[1]  
      @credits = parts[2]
      @message = parts[3].strip
    end
  end                                                                                                    

end
