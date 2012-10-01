require 'rexml/parsers/pullparser'

module MiniAether
  # Simple helper methods around REXML pull parser.
  #
  # @author Patrick Mahoney <pat@polycrystal.org>
  # @since 0.0.1, 1-June-2012
  class XmlParser < REXML::Parsers::PullParser
    class NotFoundError < RuntimeError; end

    # Pull events until the start of an element of tag name +name+ is
    # reached.
    def pull_to_start(name)
      loop do
        res = pull
        raise NotFoundError if res.event_type == :end_document
        next if res.start_element? && res[0] == name.to_s
      end
    end

    # Pull events to the start of each name, following a path of
    # +name1/name2/...+.
    def pull_to_path(*names)
      names.each { |name| pull_to_start name }
    end

    # Pull all text nodes until the next +end_element+ event.  Return
    # the concatenation of text nodes.
    def pull_text_until_end
      texts = []
      loop do
        res = pull
        break unless res.text?
        texts << res[0]
      end
      texts.join
    end
  end
end
