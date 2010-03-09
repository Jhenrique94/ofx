module OFX
  module Parser
    class Base
      attr_reader :headers
      attr_reader :body
      attr_reader :content
      attr_reader :parser

      def initialize(resource)
        @content = open_resource(resource).read
        @headers, @body = prepare(content)

        @parser = case @headers["VERSION"]
        when "102"; OFX::Parser::OFX102.new(:headers => headers, :body => body)
        else
          raise OFX::UnsupportedVersionError
        end
      end

      def open_resource(resource)
        if resource.respond_to?(:read)
          return resource
        else
          begin
            return open(resource)
          rescue
            return StringIO.new(resource)
          end
        end
      end

      private
        def prepare(content)
          # Split headers & body
          headers, body = content.dup.split(/\n{2,}|:?<OFX>/, 2)

          # Parse headers. When value is NONE, convert it to nil.
          headers = headers.to_enum(:each_line).inject({}) do |memo, line|
            _, key, value = *line.match(/^(.*?):(.*?)(\r?\n)*$/)
            memo[key] = value == "NONE" ? nil : value
            memo
          end

          # Replace body tags to parse it with Nokogiri
          body.gsub!(/>\s+</m, '><')
          body.gsub!(/\s+</m, '<')
          body.gsub!(/>\s+/m, '>')
          body.gsub!(/<(\w+?)>([^<]+)/m, '<\1>\2</\1>')

          [headers, body]
        end
    end
  end
end
