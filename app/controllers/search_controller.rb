#encoding: utf-8
class SearchController < ApplicationController
  layout "bootstrap"
  def index
    @sources = [params[:source] || []].flatten
    @q = params[:q]
    response = INatAPIService.get(
      "/search",
      q: @q,
      page: params[:page],
      sources: @sources.join( "," )
    )
    record_ids_by_type = response.results.inject( {} ) do |memo, result|
      memo[result["type"]] ||= []
      memo[result["type"]] << result["record"]["id"]
      memo
    end
    records_by_type_id = record_ids_by_type.inject( {} ) do |memo, ( type, ids )|
      memo[type] ||= {}
      scope = Object.const_get( type ).where( id: ids )
      if type == "Taxon"
        scope = scope.includes( { taxon_photos: :photo }, :taxon_descriptions, { taxon_names: :place_taxon_names } )
      end
      scope.each do |record|
        memo[type][record.id] = record
      end
      memo
    end
    records = response.results.map do |result|
      next unless klass = Object.const_get( result["type"] )
      records_by_type_id[result["type"]][result["record"]["id"]]
    end.compact
    @results = WillPaginate::Collection.create( response["page"], response["per_page"], response["total_results"] || 0 ) do |pager|
      pager.replace( records )
    end
  end
end
