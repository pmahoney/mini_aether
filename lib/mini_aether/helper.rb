require 'strscan'

module MiniAether
  module Helper
    System = Java::JavaLang::System

    def local_repository_path
      default_local_repo_path =
        File.join(System.getProperty('user.home'), '.m2', 'repository')

      if File.exists? M2_SETTINGS
        xml = File.read M2_SETTINGS
        begin
          parser = XmlParser.new(xml)
          parser.pull_to_path(:settings, :localRepository)
          interpolate(parser.pull_text_until_end.strip)
        rescue XmlParser::NotFoundError
          default_local_repo_path
        end
      else
        default_local_repo_path
      end
    end

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

    # Build a m2 repository path fragment for +dep+.  For example,
    # coordinates of +com.example:project:1.0.1+ would result in
    # +com/example/project/1.0.1/project-1.0.1.jar+.
    #
    # @param [Hash] dep a hash with keys +:group_id+, +:artifact_id+, and +:version+
    # @return [String] a path fragment to this artifact in m2 repository format
    def jar_path(dep)
      group_id = dep[:group_id]
      group_path = group_id.gsub('.', '/')
      artifact_id = dep[:artifact_id]
      version = dep[:version]

      file_name = "#{artifact_id}-#{version}.jar"
      "#{group_path}/#{artifact_id}/#{version}/#{file_name}"
    end
  end
end
