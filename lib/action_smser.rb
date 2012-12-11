require "action_smser/base"

require "action_smser/delivery_methods/test_array"
require "action_smser/delivery_methods/simple_http"
require "action_smser/delivery_methods/nexmo"
require "action_smser/delivery_methods/aql"
require "action_smser/delivery_methods/delayed_job"

module ActionSmser

  #mattr_accessor :delivery_options
  @@delivery_options = {}
  
  def self.delivery_options
    @@delivery_options
  end

  def delivery_options.[]= key, value
    super
    #@@delivery_options[key.to_sym] = value
    puts "true**********8" if key.to_sym == :save_delivery_reports and value
    puts "key : " + key.to_s + " : value : " + value.to_s 
    require "action_smser/engine" if key.to_sym == :save_delivery_reports and value
  end

  def self.delivery_options= options
    options.each { |key, value| delivery_options[key] = value }
  end

  self.delivery_options= {:delivery_method => :test_array, :save_delivery_reports => false, :default_ttl => (24*60*60) }
  self.delivery_options[:gateway_commit] = {}
  self.delivery_options[:gateway_commit_observers] = []

  def self.gateway_commit_observer_add(observer_class)
    self.delivery_options[:gateway_commit_observers].push(observer_class)
  end

  class Logger
    def self.info(str)
      Rails.logger.info("ActionSmser: #{str}")
    end
    def self.warn(str)
      Rails.logger.warn("ActionSmser: #{str}")
    end
    def self.error(str)
      Rails.logger.error("ActionSmser: #{str}")
    end
  end

end


