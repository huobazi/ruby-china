class PostgreSearch < ActiveRecord::Base
  belongs_to :searchable, polymorphic: true

  def self.index_searchable(obj)
    return unless obj.respond_to? :postgre_search
    ps = obj.postgre_search
    if ps.nil?
      PostgreSearch.create(searchable: obj)
      ps = obj.reload.postgre_search
    end

    stemmer = "simple"
    search_data = Search.prepare_data obj.to_search_data
    PostgreSearch.exec_sql("UPDATE postgre_searches SET
                            search_data = TO_TSVECTOR('#{stemmer}', :search_data)
                            WHERE id = :id", search_data: search_data, id: ps.id)
  end

  def self.scrub_html_for_search(html)
    HtmlScrubber.scrub(html)
  end

  # Execute SQL manually
  def self.exec_sql(*args)
    conn = ActiveRecord::Base.connection
    sql = ActiveRecord::Base.send(:sanitize_sql_array, args)
    conn.execute(sql)
  end

  def exec_sql(*args)
    ActiveRecord::Base.exec_sql(*args)
  end

  class HtmlScrubber < Nokogiri::XML::SAX::Document
    attr_reader :scrubbed

    def initialize
      @scrubbed = ""
    end

    def self.scrub(html)
      me = new
      parser = Nokogiri::HTML::SAX::Parser.new(me)
      begin
        copy = "<div>"
        copy << html unless html.nil?
        copy << "</div>"
        parser.parse(html) unless html.nil?
      end
      me.scrubbed
    end

    def start_element(name, attributes=[])
      attributes = Hash[*attributes.flatten]
      if attributes["alt"]
        scrubbed << " "
        scrubbed << attributes["alt"]
        scrubbed << " "
      end
      if attributes["title"]
        scrubbed << " "
        scrubbed << attributes["title"]
        scrubbed << " "
      end
    end

    def characters(string)
      scrubbed << " "
      scrubbed << string
      scrubbed << " "
    end
  end
end
