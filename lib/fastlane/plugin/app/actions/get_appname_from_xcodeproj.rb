require 'fastlane/action'
require_relative '../helper/app_helper'

module Fastlane
  module Actions
    module SharedValues
      APP_NAME = "APP_NAME"
    end
    # 获取app名
    class GetAppnameFromXcodeprojAction < Action
      require 'xcodeproj'
      require 'pathname'


      # default run： 这个方法为Action的主方法
      def self.run(params)
        # UI.message("The appinfo plugin is working!")
        unless params[:xcodeproj]
          if Helper.test?
            params[:xcodeproj] = "/tmp/fastlane/tests/fastlane/xcodeproj/app_fixture_project.xcodeproj"
          else
            params[:xcodeproj] = Dir["*.xcodeproj"][0] unless params[:xcodeproj]
          end
        end

        if params[:target]
          app_name = get_app_name_using_target(params)
        else
          app_name = get_app_name_using_scheme(params)
        end

        # 设置全局变量，供其他Actions使用
        Actions.lane_context[SharedValues::APP_NAME] = app_name 
        app_name
      end

      # 使用target获取app名
      def self.get_app_name_using_target(params)
        # 获取target
        project = Xcodeproj::Project.open(params[:xcodeproj])
        if params[:target]
          target = project.targets.detect { |t| t.name == params[:target] }
        else
          target = project.targets.detect do |t|
            t.kind_of?(Xcodeproj::Project::Object::PBXNativeTarget) &&
              t.product_type == 'com.apple.product-type.application'
          end
          target = project.targets[0] if target.nil?
        end

        # 获取app_name对象
        app_name = target.resolved_build_setting('BUNDLE_DISPLAY_NAME', true)
        UI.user_error! 'Cannot resolve app display name build setting.' if app_name.nil? || app_name.empty?

        if !(build_configuration_name = params[:build_configuration_name]).nil?
          app_name = app_name[build_configuration_name]
          UI.user_error! "Cannot resolve $(BUNDLE_DISPLAY_NAME) build setting for #{build_configuration_name}." if app_name.nil?
        else
          app_name = app_name.values.compact.uniq
          UI.user_error! 'Cannot accurately resolve $(BUNDLE_DISPLAY_NAME) build setting, try specifying :build_configuration_name.' if app_name.count > 1
          app_name = app_name.first
        end
        app_name
      end

      # 使用scheme获取app名
      def self.get_app_name_using_scheme(params)
        config = { project: params[:xcodeproj], scheme: params[:scheme], configuration: params[:build_configuration_name] }
        project = FastlaneCore::Project.new(config)
        project.select_scheme

        app_name = project.build_settings(key: 'BUNDLE_DISPLAY_NAME')
        UI.user_error! "Cannot resolve $(BUNDLE_DISPLAY_NAME) in for the scheme #{config.scheme} with the name #{params.configuration}" if app_name.nil? || app_name.empty?
        app_name
      end


      def self.description
        'Gets the $(BUNDLE_DISPLAY_NAME) build setting using the specified parameters, or the first if not enough parameters are passed.'
      end

      def self.authors
        ["linjw"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "App information can be obtained and set from Xcode"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                  env_name: "FL_APP_NAME_PROJECT",
                               description: "Optional, you must specify the path to your main Xcode project if it is not in the project root directory or if you have multiple *.xcodeproj's in the root directory",
                                  optional: true,
                                      verify_block: proc do |value|
                                         UI.user_error!("Please pass the path to the project, not the workspace") if value.end_with? ".xcworkspace"
                                         UI.user_error!("Could not find Xcode project at path '#{File.expand_path(value)}'") if !File.exist?(value) and !Helper.is_test?
                                       end),
          FastlaneCore::ConfigItem.new(key: :target,
                                       env_name: "FL_APP_NAME_TARGET",
                                       optional: true,
                                       conflicting_options: [:scheme],
                                       description: "Specify a specific target if you have multiple per project, optional"),
          FastlaneCore::ConfigItem.new(key: :scheme,
                                       env_name: "FL_APP_NAME_SCHEME",
                                       optional: true,
                                       conflicting_options: [:target],
                                       description: "Specify a specific scheme if you have multiple per project, optional"),
          FastlaneCore::ConfigItem.new(key: :build_configuration_name,
                                       optional: true,
                                       description: "Specify a specific build configuration if you have different build settings for each configuration")
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        %i[ios mac].include? platform
      end
    end
  end
end
