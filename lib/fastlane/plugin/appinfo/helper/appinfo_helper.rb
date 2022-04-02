require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class AppinfoHelper
      # class methods that you define here become available in your action
      # as `Helper::AppinfoHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the appinfo plugin helper!")
      end
    end
  end
end
