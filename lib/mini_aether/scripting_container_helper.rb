module MiniAether
  module ScriptingContainerHelper
    def mini_aether_dump(obj)
      Marshal.dump(obj).to_java_bytes
    end

    def mini_aether_load(bytes)
      Marshal.load(String.from_java_bytes(bytes))
    end
  end
end
