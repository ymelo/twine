require 'erb'
require 'rubygems'
require 'test/unit'
require 'twine'

class TwineTest < Test::Unit::TestCase
  def test_generate_string_file_1
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'fr.xml')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-1.txt #{output_path}))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-1.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_2
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'en.strings')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-1.txt #{output_path} -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-2.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_3
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'en.json')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-1.txt #{output_path} -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-5.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_4
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'en.strings')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-2.txt #{output_path} -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-6.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_5
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'en.po')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-1.txt #{output_path} -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-7.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_6
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'en.xml')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-3.txt #{output_path}))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-8.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_7
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'en.xml')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-2.txt #{output_path} -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-10.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_8
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'fr.xml')
      Twine::Runner.run(%W(generate-string-file --format tizen test/fixtures/strings-1.txt #{output_path}))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-12.txt')).result, File.read(output_path))
    end
  end

  def test_include_translated
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'fr.xml')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-1.txt #{output_path} --include translated))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-13.txt')).result, File.read(output_path))
    end
  end

  def test_consume_string_file_1
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-1.txt test/fixtures/fr-1.xml -o #{output_path} -l fr))
      assert_equal(File.read('test/fixtures/test-output-3.txt'), File.read(output_path))
    end
  end

  def test_consume_string_file_2
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-1.txt test/fixtures/en-1.strings -o #{output_path} -l en -a))
      assert_equal(File.read('test/fixtures/test-output-4.txt'), File.read(output_path))
    end
  end

  def test_consume_string_file_3
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-1.txt test/fixtures/en-1.json -o #{output_path} -l en -a))
      assert_equal(File.read('test/fixtures/test-output-4.txt'), File.read(output_path))
    end
  end

  def test_consume_string_file_4
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-1.txt test/fixtures/en-1.po -o #{output_path} -l en -a))
      assert_equal(File.read('test/fixtures/test-output-4.txt'), File.read(output_path))
    end
  end

  def test_consume_string_file_5
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-1.txt test/fixtures/en-2.po -o #{output_path} -l en -a))
      assert_equal(File.read('test/fixtures/test-output-9.txt'), File.read(output_path))
    end
  end

  def test_consume_string_file_6
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-2.txt test/fixtures/en-3.xml -o #{output_path} -l en -a))
      assert_equal(File.read('test/fixtures/test-output-11.txt'), File.read(output_path))
    end
  end

  def test_json_line_breaks_consume
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/test-json-line-breaks/line-breaks.txt test/fixtures/test-json-line-breaks/line-breaks.json -l fr -o #{output_path}))
      assert_equal(File.read('test/fixtures/test-json-line-breaks/consumed.txt'), File.read(output_path))
    end
  end

  def test_consume_string_file_plurals
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'plurals_output.txt')
      puts output_path
      Twine::Runner.run(%W(consume-string-file test/fixtures/plurals_input_1.txt test/fixtures/strings.stringsdict -o #{output_path} -l en))
      assert_equal(File.read('test/fixtures/test-output-plurals-1.txt'), File.read(output_path))
    end
  end

  def test_json_line_breaks_generate
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'en.json')
      Twine::Runner.run(%W(generate-string-file test/fixtures/test-json-line-breaks/line-breaks.txt #{output_path}))
      assert_equal(File.read('test/fixtures/test-json-line-breaks/generated.json'), File.read(output_path))
    end
  end

  def test_generate_string_file_14_include_untranslated
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'include_untranslated.xml')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-1.txt #{output_path} --include untranslated -l fr))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-14.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_14_references
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'references.xml')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-4-references.txt #{output_path} -l fr -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-14-references.txt')).result, File.read(output_path))
    end
  end

  def test_generate_plural_string_file_1
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'plurals_output.stringsdict')
      Twine::Runner.run(%W(generate-string-file test/fixtures/plurals_input_2.txt #{output_path} -l en -t plurals))
      assert_equal(ERB.new(File.read('test/fixtures/plurals_expected_output.txt')).result, File.read(output_path))
    end
  end
end
