
module SimCtl

    class SimDevice
    end

    class SimDeviceType
    end

    class SimRuntime
    end

    def self.cmd(command)
        %x[xcrun simctl #{command}]
    end

    # Considering adding constants, e.g.
    # IPHONE4 = 'iPhone 4'
    # IOS8_1 = 'iOS 8.1'
end

# line is something like
#  "   thing number 1 (number 2 is here) (number3) (possibly4)"
#
# returns
#  ["thing number 1", "number 2 is here", "number3", "possibly4"]
#
def parse_std_line(line)
    a = line.scan(/[ ]*([^()]*) \(/)[0]
    a << line.scan( /(?:\()([^()]*)(?:\))/)
    a.flatten
end

class SimCtl::SimDevice
    attr_accessor :name
    attr_accessor :id
    attr_accessor :booted
    attr_accessor :runtime_name

    def runtime
        SimCtl.runtimes[@runtime_name]
    end

    def builtin?
        # this is kind of unperformant. .device_types will probably very rarely ever change,
        # so we could cache it.
        types = SimCtl.device_types.values.map {|t| t.name}
        types.include? name
    end

    # commands are defined further down
end

class SimCtl::SimRuntime
    attr_accessor :name  
    attr_accessor :id
    # attr_accessor :devices   # dictionary of devices, indexed by name
    attr_accessor :available

    def devices
        SimCtl.devices.select { |d| d.runtime_name == name}
    end
end

class SimCtl::SimDeviceType
    attr_accessor :name
    attr_accessor :id
end

# SimCtl main methods

module SimCtl
    module_function

    def runtimes
        hash = {}
    
        SimCtl.cmd('list runtimes').lines.each do |l|
            case l[0]
            when'='
                # skip first line
            else
                r = SimRuntime.new()
                parse_arr = parse_std_line(l)

                # r.name = l.scan(/([^()]*) \(/).flatten[0];
                # parens = l.scan( /(?:\()([^()]*)(?:\))/).flatten
                r.name      = parse_arr[0]
                r.id        = parse_arr[2]
                r.available = parse_arr.length < 4
                hash[r.name] = r
            end
        end
    
        hash.freeze
    end

    # e.g. device line like "    iPhone 4s (4F61DADF-CB4E-483A-B52A-1FA6EC0E2147) (Shutdown)\n"
    def devices
        devices = []
        present_runtime_name = nil

        SimCtl.cmd('list devices').lines.each do |l|
            case l[0]
            when'='
              # skip
            when '-'
              present_runtime_name = /^-- (.*) --$/.match(l)[1]
            when ' '
                arr = parse_std_line(l)
                # pp arr
                # exit 0
                d = SimDevice.new
                d.name    = arr[0]
                d.id      = arr[1]
                d.booted  = (arr[2] == "Booted")
                d.runtime_name = present_runtime_name
                devices << d
            else
                #error 
            end
        end

        devices.freeze
    end

    def devices_with_runtime(runtime)
        get_devices.select { |x| x.runtime_name == runtime.name}
    end

    def device_types
        device_types = {}

        SimCtl.cmd('list devicetypes').lines.each do |l|
            case l[0]
            when'='
                # skip
            else
                parse_arr = parse_std_line(l)     
                dt = SimDeviceType.new()
                dt.name = parse_arr[0]
                dt.id   = parse_arr[1]
                device_types[dt.name] = dt
            end
        end

        device_types.freeze
    end

    # create        Create a new device.
    def create(name, device_type_name='iPhone 6', runtime_name='iOS 8.1', avoid_conflict: true)
        if avoid_conflict then
            conflicts = devices.find { |d| d.name == name && d.runtime_name == runtime_name }
            raise "conflict detected for creating device #{runtime_name}/#{name}" if conflicts
        end

        dt = device_types[device_type_name]
        raise "invalid device type name" if dt.nil?

        r  = runtimes[runtime_name]
        raise "invalid runtime name" if r.nil?

        id = cmd "create \"#{name}\" #{dt.id} #{r.id}"
        id.strip!

        if id.nil? || id.length == 0 then
            raise "Device not created"
        else
            puts "Created device #{id} of type \"#{device_type_name}\" and runtime \"#{runtime_name}\""
        end

        d = devices.find { |d| d.id == id }
        raise "Could not find device object for created id \"#{id}\"" if d.nil?

        d
    end

    # Right now, raises exception on more than one. Don't like it. Don't have better idea.
    def find_unique_device(name)
        devs = SimCtl.devices.select {|d| d.name == name}

        case devs.length
        when 0
            return nil
        when 1
            return devs[0]
        else
            raise "more than one device with name"
            return nil
        end
 
    end

    # Figure this will be the goto method in testing
    def create_or_find(name)
        d = find_unique_device(name)
        if d.nil? then
            d = create(name)
        end
        d
    end

    # delete("MyName")      -- deletes single unique device of name "MyName". If 0 or >1 device of that
    #                          name then will exception.
    # delete(device_object) -- calls device_object.delete
    # delete(array)         -- calls itself recursively for each item in array
    #
    # Will on delete builtin Devices when passed the named parameter `builtin_protection: false`

    def delete(device_or_devices, builtin_protection: true)
        case device_or_devices
        when SimCtl::SimDevice
            device_or_devices.delete(builtin_protection: builtin_protection)
        when ::String
            devs = devices.select { |d| d.name == device_or_devices }
            case devs.length
            when 0
                raise "device not found with id \"#{device_or_devices}\""
            when 1
                devs[0].delete
            else
                raise "more than one device found with id \"#{device_or_devices}\""                
            end
        when ::Array
            puts "Deleting Array"
            device_or_devices.each { |d| delete d }
        else
            raise "Don't know how to handle objects of type #{device_or_devices.class}"
        end
        nil
    end
end

# SimDevice methods
#
# This is where the bulk of command-line simctl functionality lives/will-live.

class SimCtl::SimDevice

    def runcmd(command, other_args = nil)
        SimCtl.cmd("#{command} #{self.id} #{other_args || ''}")
    end

    # erase         Erase a device's contents and settings.
    def erase
        runcmd 'erase'
    end

    # boot          Boot a device.
    def boot
        runcmd 'boot'
    end

    # shutdown      Shutdown a device.
    def shutdown
        runcmd 'shutdown'
    end

    # getenv        Print an environment variable from a running device.
    # TODO I haven't proven to myself this works yet    
    def getenv(varname)
        out = runcmd 'getenv', varname
        out.strip!
    end

    # openurl       Open a URL in a device.
    # TODO I haven't proven to myself this works yet    
    def openurl(url)
        runcmd 'openurl', url
    end

    # addphoto      Add a photo to the photo library of a device.
    #
    # Adds the photo at path to this device
    def add_photo(path)
        runcmd 'addphoto', path
        puts "Added photo #{path}"
        raise "problem adding photo" if !$?.success? 
    end

    def add_photos(path_arr)
        path_arr.each do |photo_path|
            add_photo photo_path
        end
    end

    # install       Install an app on a device.
    def install(app_path)
        runcmd 'install', app_path
    end

    # uninstall     Uninstall an app from a device.
    # Usage: simctl uninstall <device> <app identifier>

    # UNTESTED
    def uninstall(app_id)
        runcmd 'uninstall', app_id
    end

    # launch        Launch an application by identifier on a device.
    def launch(app_id)
        runcmd 'launch', app_id
    end

    # spawn         Spawn a process on a device.
    def spawn
        raise "not yet implemented"
    end

    # notify_post   Post a darwin notification on a device.
    def notify_post
        raise "not yet implemented"
    end

    # icloud_sync   Trigger iCloud sync on a device.
    def icloud_sync
        raise "not yet implemented"
    end

    # delete        Delete this device.
    def delete(builtin_protection: true)
        if builtin_protection && builtin? then
            raise "cannot delete builtin device without setting builtin_protection to false"
        else
            runcmd 'delete'
        end
        nil
    end

    # rename        Rename a device.
    def rename(new_name, builtin_protection: true)
        if builtin_protection && builtin? then
            raise "cannot rename builtin device without setting builtin_protection to false"
        else
            runcmd 'rename', new_name
            @name = new_name
        end
        self
    end
end
