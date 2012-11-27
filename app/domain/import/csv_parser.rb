# encoding: UTF-8
require 'csv'
require 'cmess/guess_encoding'

module Import
  class CsvParser
    extend Forwardable
    def_delegators :csv, :size, :headers, :first, :to_csv, :[], :each
    attr_reader :csv, :error
    POSSIBLE_SEPARATORS = [",", "\t", ':', ';']

    def initialize(input)
      @input = input
    end

    def parse
      begin
        data = encode_as_utf8(@input)
        @csv = CSV.parse(data, col_sep: find_separator(data), headers: true)
        strip_spaces
      rescue Exception => e
        @error = e.to_s
      end
      error.blank?
    end

    def map(header_mapping)
      header_mapping = header_mapping.with_indifferent_access
      header_mapping.reject! {|key, value| value.blank? } 
      csv.map do |row|
        headers.each_with_object({}) do |name, object|
          key = header_mapping[name]
          object[key] = row[name] if key.present?
        end
      end
    end

    def flash_notice
      text = size > 1 ? "#{size} Datensätze"  : "#{size} Datensatz"
      text += " erfolgreich gelesen."
    end

    def flash_alert(filename="csv formular daten")
      "Fehler beim Lesen von #{filename}: #{error}"
    end

    private
    def encode_as_utf8(input)
      raise "Enthält keine Daten" if input.nil?
      charset = CMess::GuessEncoding::Automatic.guess(input)
      raise "Enthält keine Daten" if charset == "UNKNOWN"
      charset = Encoding::ISO8859_1 if charset == "MACINTOSH"
      input.force_encoding(charset).encode("UTF-8")
    end
 
    def find_separator(input)
      start = input[0..500]
      POSSIBLE_SEPARATORS.inject do |most_seen,char|
        start.count(char) > start.count(most_seen) ? char : most_seen
      end
    end

    def strip_spaces
      headers.each {|header| header && header.strip! }
      each do |row| 
        row.fields.each do |field|
          field && field.strip!
        end
      end
    end
  end
end 