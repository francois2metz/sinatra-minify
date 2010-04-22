require 'yaml'

module Sinatra
  module Minify
    class Builder
      # Returns the root path of the main Sinatra application.
      # Mimins the root_path functionality of Monk.`
      def root_path(*args)
        File.join(File.dirname(settings.app_file), *args)
      end

      # Deletes all minified files.
      def clean
        [:js, :css].each do |type|
          assets_config(type).keys.each do |set|
            prefix = type == :js ? settings.js_path : settings.css_path
            path = root_path File.join(prefix, "#{set}.min.#{type}")
            File.unlink path  if File.exists? path
          end
        end
      end

      # Rebuilds the minified .min.js and .min.css files.
      def build
        out = []
        [:js, :css].each do |type|
          assets_config(type).keys.each do |set|
            prefix = type == :js ? settings.js_path : settings.css_path
            path = root_path(prefix, "#{set}.min.#{type}")
            File.open(path, 'w') { |f| f.write compress(type, set) }
            out << path
          end
        end
        out
      end

      def initialize(app_class = ::Main)
        @app_class = app_class
      end

      def settings
        @app_class
      end

      # Returns the file sets for a given type as defined in the `assets.yml` config file.
      #
      # Params:
      #  - `type` (Symbol/string) - Can be either `:js` or `:css`
      #
      def assets_config(type)
        YAML.load_file(root_path("config/assets.yml"))[type.to_s]
      end

      # Returns HTML code with `<script>` tags to include the scripts in a given `set`.
      # In a production environment, this tries to include the minified version of the
      # files. If it doesn't exist, it falls back to the original files.
      #
      # Params:
      #   - `set` (String) - The set name, as defined in `config/assets.yml`.
      #
      # Example:
      #
      #   <%= js_assets 'base' %>
      #
      def js_assets( set )
        min_file = root_path(settings.js_path, "#{set}.min.js")
        min_path = "/#{settings.js_url}/#{set}.min.js".squeeze("/")
        if settings.minify? and File.exists? min_file
          mtime = File.mtime(min_file).to_i
          "<script src='#{min_path}?#{mtime}' type='text/javascript'></script>\n"
        else
          js_assets_all set
        end
      end

      def js_assets_all(set)
        assets(:js, set).map { |script|
          "<script src='#{script[:url]}' type='text/javascript'></script>"
        }.join("\n")
      end

      # Returns HTML code with `<link>` tags to include the stylesheets in a given `set`.
      # In a production environment, this tries to include the minified version of the
      # files. If it doesn't exist, it falls back to the original files.
      #
      # Params:
      #   - `set` (String) - The set name, as defined in `config/assets.yml`.
      #
      # Example:
      #
      #   <%= css_assets 'base' %>
      #
      def css_assets( set )
        min_file = root_path settings.css_path, "#{set}.min.css"
        min_path = "/#{settings.css_url}/#{set}.min.css".squeeze("/")
        if settings.minify? and File.exists? min_file
          mtime = File.mtime(file).to_i
          "<link rel='stylesheet' href='#{min_path}?#{mtime}' media='screen' />\n"
        else
          css_assets_all set
        end
      end

      def css_assets_all(set)
        assets(:css, set).map { |sheet| 
          "<link rel='stylesheet' href='#{sheet[:url]}' media='screen' />" 
        }.join("\n")
      end

      # Returns the raw consolidated CSS/JS contents of a given type/set
      def combine(type, set)
        assets(type, set).map { |asset| File.open(asset[:path]).read }.join("\n").strip
      end

      # Returns compressed code
      def compress(type, set)
        code = combine(type, set)
        if type == :js
          minify_js code
        elsif type == :css
          minify_css code
        else
          raise ArgumentError, "type should be one of :js or :css"
        end
      end

<<<<<<< HEAD
      def minify_css( src )
        src.gsub! /\s+/, " "
        src.gsub! /\/\*(.*?)\*\//, ""
        src.gsub! /\} /, "}\n"
        src.gsub! /\n$/, ""
        src.gsub! /[ \t]*\{[ \t]*/, "{"
        src.gsub! /;[ \t]*\}/, "}"
        src.gsub! /[ \t]*([,|{|}|>|:|;])[ \t]*/,"\\1" # Tersify
        src.gsub! /[ \t]*\n[ \t]*/, "" # Hardcore mode (no NLs)
=======
      def minify_css(src)
        src.gsub!(/\s+/, " ")         
        src.gsub!(/\/\*(.*?)\*\//, "")
        src.gsub!(/\} /, "}\n")       
        src.gsub!(/\n$/, "")          
        src.gsub!(/[ \t]*\{[ \t]*/, "{")
        src.gsub!(/;[ \t]*\}/, "}") 

        src.gsub!(/[ \t]*([,|{|}|>|:|;])[ \t]*/,"\\1") # Tersify
        src.gsub!(/[ \t]*\n[ \t]*/, "") # Hardcore mode (no NLs)
>>>>>>> ad444475ec551442761b1ec38235e5fa4c939cce
        src.strip
      end

      def minify_js(src)
        JSMin.minify src
      end


      # Returns the file path of where assets of a certain type are stored.
      #
      # Params:
      #   - `type` (Symbol)  - Either `:js` or `:css`.
      #
      # Example:
      #   get_path :js
      #   # Possible value: "/home/rsc/myproject/public/js" 
      #
      def get_path(type)
        path = (type == :js) ? settings.js_path : settings.css_path
        root_path path.squeeze('/')
      end

      # Returns the URL for a given filename and a type.
      #
      # Params:
      #   - `type` (Symbol)  - Either `:js` or `:css`.
      #
      # Example:
      #   get_url :js, '/path/to/file.js'
      #
      def get_url(type, filename)
        prefix = (type == :js) ? settings.js_url : settings.css_url
        path   = filename.gsub(/^#{Regexp.escape(get_path(type))}/, '')
        File.join(prefix, path).squeeze('/')
      end

      # Returns a list of assets of a given type for a given set.
      #
      # Params:
      #   - `type` (Symbol)  - Either `:js` or `:css`.
      #   - `set` (String)   - The set name, as defined in `config/assets.yml`.
      #
      # Returns:
      #   An array of objects.
      #
      #  Example:
      #
      #     puts assets(:js, 'base').to_json
      #     # Possible output:
      #     # [ { 'url': '/js/app.js', 'path': '/home/rsc/projects/assets/public/js/app.js' },
      #     #   { 'url': '/js/main.js', 'path': '/home/rsc/projects/assets/public/js/main.js' },
      #     #   ...
      #     # ]
      #
      # See also:
      #   - js_assets
      #
      def assets(type, set)
        # type is either :js or :css
        specs = assets_config(type)[set]
        path  = get_path(type)
        done  = []
        # `specs` will be a list of filespecs. Find all files that
        # match all specs.
        [specs].flatten.inject([]) do |ret, spec|
          filepath = "#{path}/#{spec}"
          files    = Dir[filepath]

          # Add it anyway if it doesn't match anything
          unless files.any? || done.include?(filepath) || filepath.include?('*')
            ret  << { :url => get_url(type, filepath), :path => filepath }
            done << filepath
          end

          files.each do |filename|
            unless done.include? filename
              ret << {
                :url  => [get_url(type, filename), File.mtime(filename).to_i].join('?'),
                :path => filename
              }
              done << filename
            end
          end
          ret
        end
      end
    end
  end
end
