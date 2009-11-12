# Load the config file into an openstruct.
def get_config
  @application_config = OpenStruct.new(YAML.load_file("#{RAILS_ROOT}/config/config.yml"))
end

# Save the app_config settings into the yaml file.
def save_config
  # Add a comment to the start of the YAML file then write to disk.
  output = "# Settings are accessed with AppConfig.setting_name\n" + @application_config.marshal_dump.to_yaml
  config_file = File.join(RAILS_ROOT, "config/config.yml")
  File.open(config_file, 'w') { |f| f.write(output) }  
  
  # Move the @application_config variable into new_application_config to allow easier reading of the code
  # Pull the environment sepcific variables out and use them to overwrite the common variables
  # (allows environment to override common) then write each key to the currently running AppConfig.
  new_application_config = @application_config
  env_config = new_application_config.send(RAILS_ENV)
  new_application_config.common.update(env_config) unless env_config.nil?
  new_application_config.common.keys.each do |key|
    AppConfig.set_param(key,new_application_config.common[key])
  end
end

# Save settings action. Takes all settings, merges them with existing settings.
# After this, writes to the yaml file and updates all current settings.
def save_settings
  get_config
  settings_group = params["settings"]
  settings = {}
  # find all the parameters that start with the settings group eg common_xxx
  for param in params
    if param[0].include? settings_group
      settings[param[0].gsub(settings_group + "_", "")] = param[1]
    end
  end
  #convert the current settings to a table then update all the originals with the new settings
  settings_dump = @application_config.marshal_dump
  settings_dump.each do |section|
    if section[0].to_s == settings_group && section[1]
      settings_dump[section[0]].each do |item|
        settings_dump[section[0]][item[0]] = settings[item[0]]
      end
    end
    # find any new fields and add them to the settings
    for item in params.each
      theLabel = section[0].to_s+"_new_label_"
      if item[0].include? theLabel
        count = item[0].gsub(theLabel,"")
        theField = params[item[0]]
        theValue = params[section[0].to_s+"_new_value_"+count]
        if settings_dump[section[0]] != nil
          settings_dump[section[0]].merge!({theField => theValue})
        else
          settings_dump.merge!({section[0] => {theField => theValue}})
        end
      end
    end
  end
  # if there are new settings then save them. helps stop all settings being wiped
  if settings_dump
    @application_config = OpenStruct.new(settings_dump)
  end
  save_config
end
