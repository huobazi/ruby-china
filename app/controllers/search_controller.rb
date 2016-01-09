class SearchController < ApplicationController
  def index
    @result = Search.new(params[:q]).query_results.paginate(page: params[:page])
  end
end
