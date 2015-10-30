module Twine
  module Formatters
    #Simple wrapper that will use the Apple class (in which we have the plural stuff)
    class Apple_plist < Apple
      FORMAT_NAME = 'appleplist'
      EXTENSION = '.stringsdict'
      DEFAULT_FILE_NAME = 'Localizable.stringsdict'

      def format_header(lang)
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
      end

      def format_sections(lang)
        result = "<plist version=\"1.0\">"
        result += super(lang) + "\n"
        result += '</plist>'
      end


      def key_value_pattern
        raise NotImplementedError.new("Apple plist does not support strings out of a dictionary.")
      end

      def read_file(path, lang)
        begin
          require "nokogiri"
        rescue LoadError
          raise Twine::Error.new "You must run 'gem install nokogiri' in order to read or write stringsdict files."
        end
        #.stringsdict only handles plurals
        parse_stringdict_file(path, lang)
      end

      def parse_stringdict_file(path, lang)
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

    end
  end
end
