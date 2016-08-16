Puppet::Type.newtype(:rabbitmq_binding) do
  desc 'Native type for managing rabbitmq bindings'

  ensurable do
    defaultto(:present)
    newvalue(:present) do
      provider.create
    end
    newvalue(:absent) do
      provider.destroy
    end
  end

  # Match patterns without '@' as arbitrary names; match patterns with
  # src@dst@vhost to their named params for backwards compatibility.
  def self.title_patterns
    [
      [
        /(^([^@]*)$)/m,
        [
          [ :name ]
        ]
      ],
      [
        /^(\S+)@(\S+)@(\S+)$/m,
        [
          [ :source ],
          [ :dest ],
          [ :vhost ]
        ]
      ]
    ]
  end

  newparam(:name) do
    desc 'resource name, either source@dest@vhost or arbitrary name with params'
    
    isnamevar
  end

  newparam(:source) do
    desc 'source of binding'

    newvalues(/^\S+$/)
    isnamevar
  end

  newparam(:dest, :namevar => true) do
    desc 'destination of binding'

    newvalues(/^\S+$/)
    isnamevar
  end

  newparam(:vhost, :namevar => true) do
    desc 'vhost'

    newvalues(/^\S+$/)
    defaultto('/')
    isnamevar
  end

  newparam(:routing_key, :namevar => true) do
    desc 'binding routing_key'

    newvalues(/^\S*$/)
    defaultto('#')
    isnamevar
  end

  newparam(:destination_type) do
    desc 'binding destination_type'
    newvalues(/queue|exchange/)
    defaultto('queue')
  end

  newparam(:arguments) do
    desc 'binding arguments'
    defaultto {}
    validate do |value|
      resource.validate_argument(value)
    end
  end

  newparam(:user) do
    desc 'The user to use to connect to rabbitmq'
    defaultto('guest')
    newvalues(/^\S+$/)
  end

  newparam(:password) do
    desc 'The password to use to connect to rabbitmq'
    defaultto('guest')
    newvalues(/\S+/)
  end

  autorequire(:rabbitmq_vhost) do
    setup_autorequire('vhost')
  end
  
  autorequire(:rabbitmq_exchange) do
    setup_autorequire('exchange')
  end

  autorequire(:rabbitmq_queue) do
    setup_autorequire('queue')
  end

  autorequire(:rabbitmq_user) do
    [self[:user]]
  end

  autorequire(:rabbitmq_user_permissions) do
    [
      "#{self[:user]}@#{self[:source]}",
      "#{self[:user]}@#{self[:dest]}"
    ]
  end

  def setup_autorequire(type)
    destination_type = value(:destination_type)
    if type == 'exchange'
      rval = ["#{self[:source]}@#{self[:vhost]}"]
      if destination_type == type
        rval.push("#{self[:dest]}@#{self[:vhost]}")
      end
    else
      if destination_type == type
        rval = ["#{self[:dest]}@#{self[:vhost]}"]
      else
        rval = []
      end
    end
    rval
  end

  def validate_argument(argument)
    unless [Hash].include?(argument.class)
      raise ArgumentError, "Invalid argument"
    end
  end

end
