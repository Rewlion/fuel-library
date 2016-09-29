require 'json'

module CgroupsSettings
  require 'facter'
  # validates input values for service's properties
class RedhatValidator
  @nop = ->() {true}

  @bool_validator = lambda do |str|
    str.to_s == 'true' || str.to_s == 'false'
  end

  @shares_value_validator = lambda do |value|
    valid_syntax = value.to_s =~ /^[0-9]+$/

    return (2..262_144).cover?(value.to_s.to_i) if valid_syntax
    false
  end

  @cpuquota_value_validator = lambda do |value|
    value.to_s =~ /^[0-9]+%$/
  end

  @memory_value_validator = lambda do |value|
    value.to_s =~ /^[0-9]+[K|M|G|T]?$/
  end

  @taskmax_value_validator = lambda do |value|
    value.to_s =~ /^[0-9]+$/
  end

  @blockweight_value_validator = lambda do |value|
    valid_syntax = value =~ %r{^/dev/.+\s+[0-9]+$}

    return (1..1000).cover?(value.split[1].to_i) if valid_syntax
    false
  end

  @devicebites_value_validator = lambda do |value|
    value =~ %r{^/dev/.+\s+[0-9]+[K|M|G|T]?$}
  end

  @deviceallow_value_validator = lambda do |value|
    value =~ %r{^/dev/.+\s+[r|w|x]?$}
  end

  @devicepolicy_value_validator = lambda do |value|
    value.to_s =~ /strict|auto|closed/
  end

  @validators_by_property_hash = {
    'CPUAccounting' =>         @bool_validator,
    'MemoryAccounting' =>      @bool_validator,
    'TasksAccounting' =>       @bool_validator,
    'BlockIOAccounting' =>     @bool_validator,
    'CPUShares' =>             @shares_value_validator,
    'StartupCPUShares' =>      @shares_value_validator,
    'CPUQuota' =>              @cpuquota_value_validator,
    'MemoryLimit' =>           @memory_value_validator,
    'TasksMax' =>              @taskmax_value_validator,
    'BlockIODeviceWeight' =>   @blockweight_value_validator,
    'BlockIOReadBandwidth' =>  @devicebites_value_validator,
    'BlockIOWriteBandwidth' => @devicebites_value_validator,
    'DeviceAllow' =>           @deviceallow_value_validator,
    'DevicePolicy' =>          @devicepolicy_value_validator,
    'Slice' =>                 @nop,
    'Delegate' =>              @nop
  }

  def self.validate_option(service, property, value)
    err_by_type = "#{service}::#{property}::#{value} is not a type of[String,Integer]"
    err_by_value = "#{service}::#{property}::#{value} is not valid"
    err_by_unknown = "#{service}::#{property} is not supported"

    validator = @validators_by_property_hash[property]
    
    raise(err_by_type) unless value.is_a?(String) || value.is_a?(Integer)
    raise(err_by_unknown) if validator.is_a?(NilClass)
    raise(err_by_value) unless validator.call(value)
  end
end

  
  def CgroupsSettings.parse_properties(service, json)
    options = JSON.parse(json) rescue raise("#{service}::#{json} invalid json")

    unless options.is_a?(Hash)
      raise(Puppet::ParseError, "#{service}::#{options} is not a hash")
    end

    v = CgroupsSettings::RedhatValidator
    options.each do |property, value|
      v.validate_option(service, property, value)
    end

    options
  end

  def CgroupsSettings.parse_redhat_settings(settings)
    settings.each do |service, properties|
      settings[service] = CgroupsSettings.parse_properties(service, properties)
    end

    settings
  end


  # value is valid if value has integer type or
  # matches with pattern: %percent, min_value, max_value
  def self.handle_value(option, value)
    # transform value in megabytes to bytes for limits of memory
    return handle_memory(value) if option.to_s.end_with? "_in_bytes"
    # keep it as it is for others
    return value if value.is_a?(Integer)
  end

  def self.handle_memory(value)
    return mb_to_bytes(value) if value.is_a?(Integer)
    if value.is_a?(String) and matched_v = value.match(/%(\d+),\s*(\d+),\s*(\d+)/)
      percent, min, max = matched_v[1..-1].map(&:to_i)
      total_memory = Facter.value(:memorysize_mb)
      res = (total_memory.to_f / 100.0) * percent.to_f
      return mb_to_bytes([min, max, res].sort[1]).to_i
    end
  end

  def self.mb_to_bytes(value)
    return value * 1024 * 1024
  end
end

 def CgroupsSettings.parse_debian_settings(cgroups)
    serialized_data = {}

    cgroups.each do |service, settings|
      hash_settings = JSON.parse(settings) rescue raise("'#{service}': JSON parsing  error for : #{settings}")
      hash_settings.each do |group, options|
        raise("'#{service}': group '#{group}' options is not a HASH instance") unless options.is_a?(Hash)
        options.each do |option, value|
          options[option] = CgroupsSettings.handle_value(option, value)
          raise("'#{service}': group '#{group}': option '#{option}' has wrong value") if options[option].nil?
        end
      end
      serialized_data[service] = hash_settings unless hash_settings.empty?
    end
    serialized_data
  end


Puppet::Parser::Functions::newfunction(:prepare_cgroups_hash, :type => :rvalue, :arity => 1, :doc => <<-EOS
    This function get hash contains service and its cgroups settings(in JSON format) and serialize it.

    ex: prepare_cgroups_hash(hiera('cgroups'))

    Following input:
    {
      'metadata' => {
        'always_editable' => true,
        'group' => 'general',
        'label' => 'Cgroups',
        'weight' => 50
      },
      cinder-api: {"blkio":{"blkio.weight":500}}
    }

    will be transformed to:
      [{"cinder-api"=>{"blkio"=>{"blkio.weight"=>500}}}]

    Pattern for value field:
      {
        group1 => {
          param1 => value1,
          param2 => value2
        },
        group2 => {
          param3 => value3,
          param4 => value4
        }
      }

    EOS
  ) do |argv|
  raise(Puppet::ParseError, "prepare_cgroups_hash(...): Wrong type of argument. Hash is expected.") unless argv[0].is_a?(Hash)

  # wipe out UI metadata
  cgroups = argv[0].tap { |el| el.delete('metadata') }

  os_fact = Facter.value(:osfamily).to_s
  parsed_hash =  case os_fact 
                 when 'Debian'
                  CgroupsSettings.parse_debian_settings cgroups
                 when 'RedHat'
                  CgroupsSettings.parse_redhat_settings cgroups
                 else
                  raise "#{os_fact} is not unsupported"
                 end
  parsed_hash
end

# vim: set ts=2 sw=2 et :
