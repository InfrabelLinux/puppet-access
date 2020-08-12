require 'digest'

Puppet::Type.type(:accessrule).provide(:linux) do

    def initialize(value = {})
        super(value)
        @property_flush = {}
    end

    mk_resource_methods
    
    def exists?
        @property_hash[:ensure] == :present
    end

    def create
        @property_flush[:ensure] = :present
    end

    def destroy
        @property_flush[:ensure] = :absent
    end

    def self.order_from_name(name)
        name_m = /^([0-9]+) (.*)$/i.match(name)
        return name_m[1].to_i
    end

    def self.convert_rule_component_to_array(component)
        if component.nil?
            return []
        end
        component_a = component.split(' ').map(&:strip)
        if component =~ /except/i
            component_orig = component_a.dup
            component_a = []
            component_orig.each_with_index do | part, index |
                if component_orig[index + 1] =~ /except/i
                    component_a << component_orig[index] + ' ' + component_orig[index + 1] + ' ' + component_orig[index + 2]
                elsif component_orig[index] =~ /except/i
                    next
                elsif component_orig[index - 1] =~ /except/i
                    next
                else
                    component_a << part
                end
            end
        end
        component_a
    end

    ##
    # Code for self.instances
    ##
    def self.get_rules
        parsed_rules = {}
        if File.file?('/etc/security/access.conf')
            file_a = File.readlines('/etc/security/access.conf').map(&:chomp)
        else
            file_a = []
        end
        file_a.each_with_index do | line, line_no |
            if line =~ /^# [0-9]+ .*$/i
                name_m = /^# ([0-9]+) (.*)$/i.match(line)
                if ! file_a[line_no + 1].nil?
                    parsed_rules[name_m[1] + ' ' + name_m[2]] = self.rule_to_hash(file_a[line_no + 1], name_m[1] + ' ' + name_m[2])
                end
            else
                # Also include rogue lines
                if file_a[line_no - 1].nil? || file_a[line_no - 1] !~ /^# [0-9]+ .*$/i
                    rogue_rule_digest = Digest::MD5.hexdigest(line)
                    parsed_rules['9999 ' + rogue_rule_digest] = self.rule_to_hash(line, '9999 ' + rogue_rule_digest)
                end
            end
        end
        return parsed_rules
    end

    def self.rule_to_hash(rule, name)
        rule_a = rule.split(/ ?: ?/i).map(&:strip)

        origin = self.convert_rule_component_to_array(rule_a[2])
        who = self.convert_rule_component_to_array(rule_a[1])

        return {
            'name' => name,
            'permission' => rule_a[0],
            'who' => who,
            'origin' => origin
        }
    end

    def self.instances
        instances = []
        self.get_rules.each do | rule_name, rule_hash |
            instances << new(
                :ensure => :present,
                :name => rule_name,
                :permission => rule_hash['permission'],
                :who => rule_hash['who'],
                :origin => rule_hash['origin']
            )
        end
        return instances
    end

    def self.get_rule_properties(rule_name)
        rules = self.get_rules
        rule_properties = {}
        if ! rules[rule_name].nil?
            rule_hash = rules[rule_name]
            rule_properties[:ensure] = :present
            rule_properties[:name] = rule_hash['name']
            rule_properties[:permission] = rule_hash['permission'],
            rule_properties[:who] = rule_hash['who'],
            rule_properties[:origin] = rule_hash['origin']
        end
        return rule_properties
    end

    def self.prefetch(resources)
        # http://garylarizza.com/blog/2013/12/15/seriously-what-is-this-provider-doing/
        instances.each do | prov |
            resource = resources[prov.name] # resources = all resources in the catalog
            if ! resource.nil?
                # Populate @provider_hash
                resource.provider = prov
            end
        end
    end

    def flush
        ordered_rules = []
        inserted = false
        self.class.instances.each do | instance |
            if instance.properties[:name] == resource[:name]
                if @property_flush[:ensure] == :absent
                    next
                end
                ordered_rules << {
                    'name' => resource[:name].to_s,
                    'permission' => resource[:permission].to_s,
                    'who' => resource[:who].join(' ').to_s,
                    'origin' => resource[:origin].join(' ').to_s
                }
                inserted = true
            else
                ordered_rules << {
                    'name' => instance.properties[:name].to_s,
                    'permission' => instance.properties[:permission].to_s,
                    'who' => instance.properties[:who].join(' ').to_s,
                    'origin' => instance.properties[:origin].join(' ').to_s
                }
            end
        end
        if ! inserted && @property_flush[:ensure] != :absent
            ordered_rules << {
                'name' => resource[:name].to_s,
                'permission' => resource[:permission].to_s,
                'who' => resource[:who].join(' ').to_s,
                'origin' => resource[:origin].join(' ').to_s
            }
        end

        ordered_rules.sort_by! do | rule |
            self.class.order_from_name(rule['name'])
        end

        fh = File.open('/etc/security/access.conf', 'w')

        ordered_rules.each do | rule |
            fh.puts '# ' + rule['name']
            fh.puts rule['permission'] + ' : ' + rule['who'] + ' : ' + rule['origin']
        end
        fh.close
        @property_hash = self.class.get_rule_properties(resource[:name])
    end

    def properties
        if @property_hash.empty?
            @property_hash = query || { ensure: :absent }
            @property_hash[:ensure] = :absent if @property_hash.empty?
        end
        @property_hash.dup
    end

    def query
        self.class.instances.each do | instance |
            if instance.name == name || instance.name.downcase == name
                return instance.properties
            end
        end
        nil
    end

end