require 'plugins/app_config/lib/configuration'
require 'ostruct'
require 'yaml'
Rails::Initializer.run do |config|
  # Load the config file and put the details into an OpenStruct
  begin
    application_config = OpenStruct.new(YAML.load_file("#{RAILS_ROOT}/config/config.yml"))
    env_config = application_config.send(RAILS_ENV)
    application_config.common.update(env_config) unless env_config.nil?
  rescue Exception
    application_config = OpenStruct.new()
  end

  # Merge config.yml into ::AppConfig
  unless application_config.common.nil?
    application_config.common.keys.each do |key|
      config.app_config[key] = application_config.common[key]
    end
  end
end
