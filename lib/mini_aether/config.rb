module MiniAether
  MAVEN_CENTRAL_REPO = 'http://repo1.maven.org/maven2'.freeze

  class LoggerConfig
    attr_reader :level

    def initialize
      @level = 'INFO'
    end

    def level=(level)
      @level = case level
               when Symbol, String
                 level.to_s.upcase
               when Logger::FATAL, Logger::ERROR
                 'ERROR'
               when Logger::WARN
                 'WARN'
               when Logger::INFO
                 'INFO'
               when Logger::DEBUG
                 'DEBUG'
               else
                 'INFO'
               end
    end

    def info?
      case @level
      when 'INFO', 'DEBUG'
        true
      else
        false
      end
    end
  end

  class << self
    def logger
      @logger ||= LoggerConfig.new
    end
  end
end
