require 'strscan'

module MiniAether
  module Helper
    java_import java.lang.System

    # Interpolate variables like +${user.home}+ and +${env.HOME}+ from
    # system properties and environment variables respectively.
    def interpolate(str)
      ret = ''

      s = StringScanner.new(str)
      pos = s.pos

      while s.scan_until(/\$\{[^\s}]+\}/) # match ${stuff}
        # add the pre_match, but only starting from previous position
        ret << str.slice(pos, (s.pos - pos - s.matched.size))

        # interpolate
        var = s.matched.slice(2..-2)
        ret << case var
               when /^env\.(.*)/
                 ENV[$1] || ''
               else
                 System.getProperty(var) || ''
               end

        pos = s.pos
      end
      ret << s.rest
      
      ret
    end
  end
end
