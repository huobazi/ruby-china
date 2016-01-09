class SearchIndexer < ActiveJob::Base
  queue_as :search_indexer

  def perform(type, id)
    obj = nil
    case type
    when 'topic'
      obj = Topic.find(id)
    when 'page'
      obj = Page.find(id)
    when 'user'
      obj = User.find(id)
    end

    PostgreSearch.index_searchable(obj)
  end
end
