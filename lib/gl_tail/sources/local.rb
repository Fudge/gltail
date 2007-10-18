
module GlTail
  module Source

    class Local < Base
      config_attribute :command, "The Command to run"
      config_attribute :files, "The files to tail", :deprecated => "Should be embedded in the :command"

      # TODO: code to run comand locally and parse streams
    end
  end
end
