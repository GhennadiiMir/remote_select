require "rails/generators/base"

module RemoteSelect
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Copy remote_select JS and CSS into your application"

      class_option :force, type: :boolean, default: false,
        desc: "Overwrite existing files"

      def copy_javascript
        source = RemoteSelect::Engine.root.join("app/javascript/remote_select.js")
        dest   = File.join(destination_root, "app/javascript/remote_select.js")

        if File.exist?(dest) && !options[:force]
          say_status :skip, "app/javascript/remote_select.js already exists (use --force to overwrite)", :yellow
        else
          version_comment = "// remote_select v#{RemoteSelect::VERSION} — copied by rails generate remote_select:install\n"
          create_file "app/javascript/remote_select.js", version_comment + source.read
        end
      end

      def copy_stylesheet
        source = RemoteSelect::Engine.root.join("app/assets/stylesheets/remote_select.css")
        dest   = File.join(destination_root, "app/assets/stylesheets/remote_select.css")

        if File.exist?(dest) && !options[:force]
          say_status :skip, "app/assets/stylesheets/remote_select.css already exists (use --force to overwrite)", :yellow
        else
          version_comment = "/* remote_select v#{RemoteSelect::VERSION} — copied by rails generate remote_select:install */\n"
          create_file "app/assets/stylesheets/remote_select.css", version_comment + source.read
        end
      end

      def print_post_install
        say ""
        say "remote_select files copied successfully!", :green
        say ""

        js_pipeline = detect_js_pipeline
        case js_pipeline
        when :importmap
          say "Importmap detected. Add to config/importmap.rb:"
          say '  pin "remote_select"'
          say ""
          say "And in app/javascript/application.js:"
          say '  import "remote_select"'
        when :esbuild, :rollup, :webpack
          say "#{js_pipeline} detected. Add to app/javascript/application.js:"
          say '  import "./remote_select"'
        else
          say "Add to your JS entry point:"
          say '  import "./remote_select"'
        end

        say ""

        css_pipeline = detect_css_pipeline
        case css_pipeline
        when :cssbundling
          say "cssbundling (sass) detected. Add to your main SCSS/CSS entry:"
          say '  @import "./remote_select";'
        when :sprockets
          say "Sprockets detected. Add to application.css:"
          say '  *= require remote_select'
        else
          say "Add to your CSS entry point:"
          say '  @import "./remote_select";'
          say '  or (Sprockets): *= require remote_select'
        end
      end

      private

      def app_root
        Pathname.new(destination_root)
      end

      def detect_js_pipeline
        return :importmap if app_root.join("config/importmap.rb").exist?

        pkg = read_package_json
        return nil unless pkg

        build_script = pkg.dig("scripts", "build") || ""
        deps = (pkg["dependencies"] || {}).merge(pkg["devDependencies"] || {})

        return :esbuild  if deps.key?("esbuild") || build_script.include?("esbuild")
        return :rollup   if deps.key?("rollup")  || build_script.include?("rollup")
        return :webpack  if deps.key?("webpack") || build_script.include?("webpack")

        nil
      end

      def detect_css_pipeline
        pkg = read_package_json
        if pkg
          build_css = pkg.dig("scripts", "build:css") || ""
          deps = (pkg["dependencies"] || {}).merge(pkg["devDependencies"] || {})
          return :cssbundling if build_css.include?("sass") || deps.key?("sass")
        end

        if app_root.join("app/assets/stylesheets/application.css").exist?
          return :sprockets
        end

        nil
      end

      def read_package_json
        path = app_root.join("package.json")
        return nil unless path.exist?
        JSON.parse(path.read)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
