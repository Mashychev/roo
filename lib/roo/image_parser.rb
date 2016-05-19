require 'nokogiri'
require 'zip'

module Roo
  class ImageParser
    class << self
      attr_accessor :array_of_drawings, :array_of_images, :image_files

      def parse_xlsx(file_name)
        return [] unless File.exist? file_name
        Zip::File.open(file_name) do |zip_file|
          find_drawing_entries(zip_file)
          parse_drawings(zip_file)
          find_images(zip_file)
        end
        @image_files
      end

      private
      def find_drawing_entries(zip_file)
        doc = zip_file.find_entry("xl/workbook.xml")
          xml = Nokogiri::XML.parse(doc.get_input_stream)
          count_of_sheets = xml.xpath('//@name').map { |e| e.text}.count
          @array_of_drawings = []
          1.upto(count_of_sheets) do |k|
            @array_of_drawings << "xl/drawings/_rels/drawing#{k}.xml.rels"
          end
      end

      def parse_drawings(zip_file)
        @array_of_images = []
        @array_of_drawings.compact.each do |drawing|
          doc = zip_file.find_entry(drawing)
          xml = Nokogiri::XML.parse(doc.respond_to?(:get_input_stream) ? doc.get_input_stream : [])
          @array_of_images << xml.xpath('//@Target').map { |e| e.text.sub('..', '')}
        end
      end

      def find_images(zip_file)
        @image_files = []
        @array_of_images.flatten.each do |image|
          @image_files << zip_file.find_entry(File.join('xl', image))
        end
      end
    end
  end
end