require 'nokogiri'
module Twine
  module Formatters
    class Apple < Abstract
      FORMAT_NAME = 'apple'
      EXTENSION = '.strings'
      DEFAULT_FILE_NAME = 'Localizable.strings'

      def self.can_handle_directory?(path)
        Dir.entries(path).any? { |item| /^.+\.lproj$/.match(item) }
      end

      def default_file_name
        return DEFAULT_FILE_NAME
      end

      def determine_language_given_path(path)
        path_arr = path.split(File::SEPARATOR)
        path_arr.each do |segment|
          match = /^(.+)\.lproj$/.match(segment)
          if match
            if match[1] != "Base"
              return match[1]
            end
          end
        end

        return
      end

      def read_file(path, lang)
        #parse_string_file(path, lang)
        parse_stringdict_file(path, lang)
      end

      def parse_string_file(path, lang)
        encoding = Twine::Encoding.encoding_for_path(path)
        sep = nil
        if !encoding.respond_to?(:encode)
          # This code is not necessary in 1.9.3 and does not work as it did in 1.8.7.
          if encoding.end_with? 'LE'
            sep = "\x0a\x00"
          elsif encoding.end_with? 'BE'
            sep = "\x00\x0a"
          else
            sep = "\n"
          end
        end

        if encoding.index('UTF-16')
          mode = "rb:#{encoding}"
        else
          mode = "r:#{encoding}"
        end

        fileType = File.extname(path)
        File.open(path, mode) do |f|
          last_comment = nil
          while line = (sep) ? f.gets(sep) : f.gets
            if encoding.index('UTF-16')
              if line.respond_to? :encode!
                line.encode!('UTF-8')
              else
                require 'iconv'
                line = Iconv.iconv('UTF-8', encoding, line).join
              end
            end
            match = /"((?:[^"\\]|\\.)+)"\s*=\s*"((?:[^"\\]|\\.)*)"/.match(line)
            if match
              key = match[1]
              value = match[2]
              read_string(key, lang, value)
              if last_comment
                set_comment_for_key(key, last_comment)
              end
            end
            if @options[:consume_comments]
              match = /\/\* (.*) \*\//.match(line)
              if match
                last_comment = match[1]
              else
                last_comment = nil
              end
            end
          end
        end
      end

      def parse_stringdict_file(path, lang)
        encoding = Twine::Encoding.encoding_for_path(path)
        if encoding.index('UTF-16')
          mode = "rb:#{encoding}"
        else
          mode = "r:#{encoding}"
        end

        doc = Nokogiri::XML(File.open(path)) do |config|
          config.strict.nonet
          config.strict.noblanks
        end
        #root_dict will contain the whole working documents (excluding the xml, namespace, and plist delcaration)
        root_dict = doc.xpath("/plist/dict")
        string_keys = nil
        string_dicts = nil
        string = nil
        variable_name = nil
        variable_dict_keys = nil
        variable_dict_strings = nil

        root_dict.each do | t |
          string_keys = t.xpath("key")
          string_dicts = t.xpath("dict")
        end
        if string_keys.size == string_dicts.size
          for i in 0..string_keys.size
            if !string_keys[i].nil?
              key = string_keys[i].inner_text
              dicts = string_dicts[i]
              if !dicts.nil?
                string = dicts.xpath("string")
                variable_name = dicts.xpath("key")[1].inner_text
                variable_dict_keys = dicts.xpath("dict/key")
                variable_dict_strings = dicts.xpath("dict/string")
                if variable_dict_keys.size == variable_dict_strings.size
                  for j in 0..variable_dict_keys.size
                    if !variable_dict_keys[j].nil? && !variable_dict_keys[j].inner_text.start_with?("NSS")
                      value = string.inner_text
                      value["\%\#\@#{variable_name}\@"] = variable_dict_strings[j]
                      key.gsub!('\\"', '"')
                      value.gsub!('\\"', '"')
                      value = iosify_substitutions(value)
                      set_translation_for_key_with_quantity(key, lang, variable_dict_keys[j].inner_text, value)
                    end #if
                  end #for
                end #if size
              end #if dicts nil
            end #if strings key[i] nil
          end # for
        end # if size
      end

      def read_string(key, lang, value)
        key.gsub!('\\"', '"')
        value.gsub!('\\"', '"')
        value = iosify_substitutions(value)
        set_translation_for_key(key, lang, value)
      end

      def read_plural

      end

      def format_header(lang)
        "/**\n * Apple Strings File\n * Generated by Twine #{Twine::VERSION}\n * Language: #{lang}\n */"
      end

      def format_section_header(section)
        "/********** #{section.name} **********/\n"
      end

      def key_value_pattern
        "\"%{key}\" = \"%{value}\";\n"
      end

      def format_comment(comment)
        "/* #{comment.gsub('*/', '* /')} */"
      end

      def format_key(key)
        escape_quotes(key)
      end

      def format_value(value)
        escape_quotes(value)
      end

      def escape_quotes(text)
        text.gsub('"', '\\\\"')
      end

    end
  end
end
