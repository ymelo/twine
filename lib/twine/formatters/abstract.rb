module Twine
  module Formatters
    class Abstract
      attr_accessor :strings
      attr_accessor :options

      def self.can_handle_directory?(path)
        return false
      end

      def initialize(strings, options)
        @strings = strings
        @options = options
      end

      def iosify_substitutions(str)
        # use "@" instead of "s" for substituting strings
        str.gsub!(/%([0-9\$]*)s/, '%\1@')
        return str
      end

      def androidify_substitutions(str)
        # 1) use "s" instead of "@" for substituting strings
        str.gsub!(/%([0-9\$]*)@/, '%\1s')

        # 1a) escape strings that begin with a lone "@"
        str.sub!(/^@ /, '\\@ ')

        # 2) if there is more than one substitution in a string, make sure they are numbered
        substituteCount = 0
        startFound = false
        str.each_char do |c|
          if startFound
            if c == "%"
              # ignore as this is a literal %
            elsif c.match(/\d/)
              # leave the string alone if it already has numbered substitutions
              return str
            else
              substituteCount += 1
            end
            startFound = false
          elsif c == "%"
            startFound = true
          end
        end

        if substituteCount > 1
          currentSub = 1
          startFound = false
          newstr = ""
          str.each_char do |c|
            if startFound
              if !(c == "%")
                newstr = newstr + "#{currentSub}$"
                currentSub += 1
              end
              startFound = false
            elsif c == "%"
              startFound = true
            end
            newstr = newstr + c
          end
          return newstr
        else
          return str
        end
      end

      def set_translation_for_key(key, lang, value)
        set_translation_for_key_with_quantity(key, lang, "", value)
      end

      def set_translation_value(key, lang, quantity, value)
        if @strings.strings_map[key].translations[lang].nil?
            @strings.strings_map[key].translations[lang] = Hash.new
        end
        @strings.strings_map[key].translations[lang][quantity] = value
      end

      def set_translation_for_key_with_quantity(key, lang, quantity, value)

        if @strings.strings_map.include?(key)
          #puts "EXIST #{key} #{lang} #{quantity}"
          # @strings.strings_map[key].translations[lang] = value
          set_translation_value(key, lang, quantity, value)
        elsif @options[:consume_all]
          STDERR.puts "Adding new string '#{key}' to strings data file."
          arr = @strings.sections.select { |s| s.name == 'Uncategorized' }
          current_section = arr ? arr[0] : nil
          if !current_section
            current_section = StringsSection.new('Uncategorized')
            @strings.sections.insert(0, current_section)
          end
          current_row = StringsRow.new(key)
          current_section.rows << current_row

          if @options[:tags] && @options[:tags].length > 0
              current_row.tags = @options[:tags]
          end

          @strings.strings_map[key] = current_row
          set_translation_value(key, lang, quantity, value)
        else
          STDERR.puts "Warning: '#{key}' not found in strings data file."
        end
        if !@strings.language_codes.include?(lang)
          @strings.add_language_code(lang)
        end
      end

      def set_comment_for_key(key, comment)
        if @strings.strings_map.include?(key)
          @strings.strings_map[key].comment = comment
        end
      end

      def default_file_name
        raise NotImplementedError.new("You must implement default_file_name in your formatter class.")
      end

      def determine_language_given_path(path)
        raise NotImplementedError.new("You must implement determine_language_given_path in your formatter class.")
      end

      def read_file(path, lang)
        raise NotImplementedError.new("You must implement read_file in your formatter class.")
      end

      def default_language
        #split the string so we can handle plurals such as en:one en:other en..
        #if not a plural it will return the full lang name
        @options[:developer_language] || @strings.language_codes[0].split(':')[0]
      end

      def fallback_languages(lang)
        [default_language]
      end

      def format_file(lang)
        result = format_header(lang) + "\n"
        result += format_sections(lang)
      end

      def format_header(lang)
        raise NotImplementedError.new("You must implement format_header in your formatter class.")
      end

      def format_sections(lang)
        sections = @strings.sections.map { |section| format_section(section, lang) }
        sections.join("\n")
      end

      def format_section_header(section)
      end

      def format_section(section, lang)
        rows = section.rows.select { |row| row.matches_tags?(@options[:tags], @options[:untagged]) }

        result = ""
        unless rows.empty?
          if section.name && section.name.length > 0
            section_header = format_section_header(section)
            result += "\n#{section_header}" if section_header
          end
        end

        rows.map! { |row| format_row(row, lang) }
        rows.compact! # remove nil entries
        rows.map! { |row| "\n#{row}" }  # prepend newline
        result += rows.join
      end

      def format_row(row, lang)
        value = row.translated_string_for_lang(lang)

        return if value && @options[:include] == 'untranslated'

        if value.nil? && @options[:include] != 'translated'
          value = row.translated_string_for_lang(fallback_languages(lang))
        end

        return nil unless value

        result = ""
        if row.comment
          comment = format_comment(row.comment)
          result += comment + "\n" if comment
        end
        #result += key_value_pattern % { key: format_key(row.key.dup), value: format_all_values(value.dup) }
        result += format row.key.dup, value.dup
      end

      def format(key, value)
        #default behaviour
        return key_value_pattern % { key: format_key(key), value: format_value(value) }
      end

      def format_comment(comment)
      end

      def key_value_pattern
        raise NotImplementedError.new("You must implement key_value_pattern in your formatter class.")
      end

      def format_key(key)
        key
      end

      def format_all_values(values)
        if values.is_a?(Hash)
          flattenedValue = String.new
          values.each do |value|
            flattenedValue << "\n"
            flattenedValue << format_value(value)
          end
        else
          return format_value(values)
        end
      end

      def format_value(value)
        value
      end

      def write_file(path, lang)
        encoding = @options[:output_encoding] || 'UTF-8'

        File.open(path, "w:#{encoding}") do |f|
          f.puts format_file(lang)
        end
      end

      def write_all_files(path)
        if !File.directory?(path)
          raise Twine::Error.new("Directory does not exist: #{path}")
        end

        file_name = @options[:file_name] || default_file_name
        langs_written = []
        Dir.foreach(path) do |item|
          if item == "." or item == ".."
            next
          end
          item = File.join(path, item)
          if File.directory?(item)
            lang = determine_language_given_path(item)
            if lang
              write_file(File.join(item, file_name), lang)
              langs_written << lang
            end
          end
        end
        if langs_written.empty?
          raise Twine::Error.new("Failed to generate any files: No languages found at #{path}")
        end
      end
    end
  end
end
