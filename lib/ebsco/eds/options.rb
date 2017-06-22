require 'ebsco/eds/jsonable'

module EBSCO

  module EDS

    class Options
      include JSONable
      attr_accessor :SearchCriteria, :RetrievalCriteria, :Actions
      def initialize(options = {}, info)
  
        @SearchCriteria = EBSCO::EDS::SearchCriteria.new(options, info)

        @RetrievalCriteria = EBSCO::EDS::RetrievalCriteria.new(options, info)
  
        @Actions = []

        options.each do |key, value|

          case key

            when :actions
              add_actions(options[:actions], info)

            # SOLR: Need to add page actions whenever other actions are present since the other actions
            # will always reset the page to 1 even though a PageNumber is present in RetrievalCriteria.
            when 'page'
              @Actions.push "GoToPage(#{value.to_i})"

            # solr facet translation
            # "f"=>{"format"=>["eBooks"]}
            when 'f'
              if value.has_key?('format')
                format_list = value['format']
                format_list.each do |item|
                  @Actions.push "addfacetfilter(SourceType:#{item})"
                end
              end

              if value.has_key?('language_facet')
                lang_list = value['language_facet']
                lang_list.each do |item|
                  @Actions.push "addfacetfilter(Language:#{item})"
                end
              end

              if value.has_key?('subject_topic_facet')
                subj_list = value['subject_topic_facet']
                subj_list.each do |item|
                  @Actions.push "addfacetfilter(SubjectEDS:#{item})"
                end
              end

              if value.has_key?('geographic_facet')
                subj_list = value['geographic_facet']
                subj_list.each do |item|
                  @Actions.push "addfacetfilter(SubjectGeographic:#{item})"
                end
              end

              if value.has_key?('publisher_facet')
                subj_list = value['publisher_facet']
                subj_list.each do |item|
                  @Actions.push "addfacetfilter(Publisher:#{item})"
                end
              end

              if value.has_key?('journal_facet')
                subj_list = value['journal_facet']
                subj_list.each do |item|
                  @Actions.push "addfacetfilter(Journal:#{item})"
                end
              end

              if value.has_key?('category_facet')
                subj_list = value['category_facet']
                subj_list.each do |item|
                  @Actions.push "addfacetfilter(Category:#{item})"
                end
              end

              if value.has_key?('content_provider_facet')
                subj_list = value['content_provider_facet']
                subj_list.each do |item|
                  item = eds_sanitize item
                  @Actions.push "addfacetfilter(ContentProvider:#{item})"
                end
              end

              if value.has_key?('library_location_facet')
                subj_list = value['library_location_facet']
                subj_list.each do |item|
                  item = eds_sanitize item
                  @Actions.push "addfacetfilter(LocationLibrary:#{item})"
                end
              end

              if value.has_key?('search_limiters')
                _list = value['search_limiters']
                _list.each do |item|
                  if item == 'Full Text'
                    @Actions.push "addlimiter(FT:y)"
                  end
                  if item == 'Peer Reviewed'
                    @Actions.push "addlimiter(RV:y)"
                  end
                  if item == 'Available in Library Collection'
                    @Actions.push "addlimiter(FT1:y)"
                  end
                end
              end

              if value.has_key?('pub_date_facet')
                _list = value['pub_date_facet']
                _this_year = Date.today.year
                _this_month = Date.today.month
                _list.each do |item|
                  if item == 'This year'
                    _range = _this_year.to_s + '-01/' + _this_year.to_s + '-' + _this_month.to_s
                    @Actions.push "addlimiter(DT1:#{_range})"
                  end
                  if item == 'Last 3 years'
                    _range = (_this_year-3).to_s + '-' + _this_month.to_s + '/' + _this_year.to_s + '-' + _this_month.to_s
                    @Actions.push "addlimiter(DT1:#{_range})"
                  end
                  if item == 'Last 10 years'
                    _range = (_this_year-10).to_s + '-' + _this_month.to_s + '/' + _this_year.to_s + '-' + _this_month.to_s
                    @Actions.push "addlimiter(DT1:#{_range})"
                  end
                  if item == 'Last 50 years'
                    _range = (_this_year-50).to_s + '-' + _this_month.to_s + '/' + _this_year.to_s + '-' + _this_month.to_s
                    @Actions.push "addlimiter(DT1:#{_range})"
                  end
                  if item == 'More than 50 years ago'
                    _range = '0000-01/' + (_this_year-50).to_s + '-12'
                    @Actions.push "addlimiter(DT1:#{_range})"
                  end
                end
              end

            else

          end
        end
  
      end
  
      def add_actions(actions, info)
        if actions.kind_of?(Array) && actions.count > 0
          actions.each do |item|
            #if is_valid_action(item, info)
            @Actions.push item
            #end
          end
        else
          #if is_valid_action(actions, info)
          @Actions = [actions]
          #else
          #end
        end
      end

      def eds_sanitize(str)
        pattern = /(\'|\"|\.|\*|\/|\-|\\|\)|\$|\+|\(|\^|\?|\!|\~|\`)/
        str = str.gsub(pattern){ |match| '\\' + match }
        str
      end

      # def is_valid_action(action, info)
      #   # actions in info that require an enumerated value (e.g., addlimiter(LA99:Bulgarian))
      #   _available_actions = info.available_actions
      #   _defined_action = _available_actions.include? action
      #   # actions not enumerated in info (e.g., GoToPage(3))
      #   _available_standard_actions = ['GoToPage']
      #   _standard_action = _available_standard_actions.any? { |std| action.include? std }
      #   # actions in info that require a user supplied value (e.g., addlimiter(TI:value))
      #   _available_value_actions = %w{PG4 CS1 FM FT FR RV DT1 SO}
      #   _value_action = _available_value_actions.any? { |type| action.include? type }
      #
      #   if _value_action || _defined_action || _standard_action
      #     true
      #   else
      #     false
      #   end
      # end

      # query-1=AND,volcano&sort=relevance&includefacets=y&searchmode=all&autosuggest=n&view=brief&resultsperpage=20&pagenumber=1&highlight=y
      def to_query_string
        qs = ''

        # SEARCH CRITERIA:

        # query
        qs << 'query-1=' + @SearchCriteria.Queries[0][:BooleanOperator]
        if @SearchCriteria.Queries[0].has_key? :FieldCode
          qs << ',' + @SearchCriteria.Queries[0][:FieldCode]
        end
        qs << ',' + @SearchCriteria.Queries[0][:Term]

        # mode
        qs << '&searchmode=' + @SearchCriteria.SearchMode

        # facets
        qs << '&includefacets=' + @SearchCriteria.IncludeFacets

        # sort
        qs << '&sort=' + @SearchCriteria.Sort

        # auto-suggest
        qs << '&autosuggest=' + @SearchCriteria.AutoSuggest

        # limiters
        unless @SearchCriteria.Limiters.nil?
          qs << '&limiter=' + @SearchCriteria.Limiters
        end

        # expanders
        qs << '&expander=' + @SearchCriteria.Expanders.join(',')

        # facet filters
        unless @SearchCriteria.FacetFilters.nil?
          qs << '&facetfilter=1,' + @SearchCriteria.FacetFilters
        end

        # related content
        unless @SearchCriteria.RelatedContent.nil?
          qs << '&relatedcontent=' + @SearchCriteria.RelatedContent.join(',')
        end

        # TODO: publication ID

        # Retrieval Criteria

        unless @RetrievalCriteria.View.nil?
          qs << '&view=' + @RetrievalCriteria.View
        end
        unless @RetrievalCriteria.ResultsPerPage.nil?
          qs << '&resultsperpage=' + @RetrievalCriteria.ResultsPerPage.to_s
        end
        unless @RetrievalCriteria.PageNumber.nil?
          qs << '&pagenumber=' + @RetrievalCriteria.PageNumber.to_s
        end
        unless @RetrievalCriteria.Highlight.nil?
          qs << '&highlight=' + @RetrievalCriteria.Highlight
        end

        return qs
      end

    end
  
    class SearchCriteria
      include JSONable
      attr_accessor :Queries, :SearchMode, :IncludeFacets, :FacetFilters, :Limiters, :Sort, :PublicationId,
                    :RelatedContent, :AutoSuggest, :Expanders

      def initialize(options = {}, info)

        # defaults
        @SearchMode = info.default_search_mode
        @IncludeFacets = 'y'
        @Sort = 'relevance'
        @AutoSuggest = info.default_auto_suggest
        _has_query = false

        @Expanders = info.default_expander_ids
        _my_expanders = []
        _available_expander_ids = info.available_expander_ids

        @Limiter = nil
        _my_limiters = []

        @RelatedContent = info.default_related_content_types
        _my_related_content = []
        _available_related_content_types = info.available_related_content_types

        options.each do |key, value|

          case key

            # ====================================================================================
            # query
            # ====================================================================================
            when :query, 'q'

              # add blacklight search_fields
              _field_code = ''
              if options.has_key? 'search_field'
                _field = options['search_field']
                case _field
                  when 'author'
                    _field_code = 'AU'
                  when 'subject'
                    _field_code = 'SU'
                  when 'title'
                    _field_code = 'TI'
                end
              end

              _boolean_operator = 'AND'
              if options.has_key? 'boolean_operator'
                _boolean_operator = options['boolean_operator']
              end

              if not _field_code == ''
                @Queries =  [{:FieldCode => _field_code, :Term => value, :BooleanOperator => _boolean_operator}]
              else
                @Queries =  [{:Term => value, :BooleanOperator => _boolean_operator}]
              end
              _has_query = true

            # ====================================================================================
            # mode
            # ====================================================================================
            when :mode
              if info.available_search_mode_types.include? value.downcase
                @SearchMode = value.downcase
              else
                @SearchMode = info.default_search_mode
              end

            # ====================================================================================
            # facets
            # ====================================================================================
            when :include_facets
              @IncludeFacets = value ? 'y' : 'n'

            when :facet_filters
              @FacetFilters = value

            # # handle solr facets without causing the page to reset to 1 again?
            # when 'f'
            #
            #   if value.has_key?('content_provider_facet')
            #     f_filter = {'FilterId' => 1, 'FacetValues' => []}
            #     flist = value['content_provider_facet']
            #     flist.each do |item|
            #       item = eds_sanitize item
            #       f_filter['FacetValues'].push({'Id' => 'ContentProvider', 'Value' => item})
            #     end
            #     @FacetFilters.push f_filter
            #     puts 'FACET FILTERS: ' + @FacetFilters.inspect
            #   end

            # ====================================================================================
            # sort
            # ====================================================================================
            when :sort, 'sort'
              if info.available_sorts(value.downcase).empty?
                if value.downcase == 'newest' || value.downcase == 'pub_date_sort desc'
                  @Sort = 'date'
                elsif value.downcase == 'oldest' || value.downcase == 'pub_date_sort asc'
                  @Sort = 'date2'
                elsif value.downcase == 'score desc'
                  @Sort = 'relevance'
                else
                  @Sort = 'relevance'
                end
              else
                @Sort = value.downcase
              end

            # ====================================================================================
            # publication id
            # ====================================================================================
            when :publication_id
              @PublicationId = value

            when :auto_suggest
              @AutoSuggest = value ? 'y' : 'n'

            # ====================================================================================
            # expanders
            # ====================================================================================
            when :expanders
              value.each do |item|
                if _available_expander_ids.include? item.downcase
                  _my_expanders.push(item)
                end
              end
              if _my_expanders.empty?
                _my_expanders = info.default_expander_ids
              end
              @Expanders = _my_expanders

            # ====================================================================================
            # limiters
            # ====================================================================================
            when :limiters
              value.each do |item|
                _key = item.split(':',2).first.upcase
                _values = item.split(':',2).last
                # is limiter id available?
                if info.available_limiter_ids.include? _key
                  _limiter = info.available_limiters(_key)
                  # if multi-value, add the values if they're available
                  if _limiter['Type'] == 'multiselectvalue'
                    _available_values = info.available_limiter_values(_key)
                    _multi_values = []
                    _values.split(',').each do |val|
                      # todo: make case insensitive?
                      if _available_values.include? val
                        _multi_values.push(val)
                      end
                    end
                    if _multi_values.empty?
                      # do nothing, none of the values are available
                    else
                      _my_limiters.push({:Id => _key, :Values => _multi_values})
                    end
                    # single value, just pass it on
                  else
                    _my_limiters.push({:Id => _key, :Values => [_values]})
                  end
                end
              end
              @Limiters = _my_limiters

            # ====================================================================================
            # related content
            # ====================================================================================
            when :related_content
              value.each do |item|
                if _available_related_content_types.include? item.downcase
                  _available_related_content_types.push(item)
                else
                  # silently ignore
                end
              end
              if _my_related_content.empty?
                _my_related_content = info.default_related_content_types
              end
              @RelatedContent = _my_related_content

            # ====================================================================================
            # unsupported parameters, ignore
            # ====================================================================================
            else
              # ignore

          end

        end

      end
    end

    class RetrievalCriteria
      include JSONable
      attr_accessor :View, :ResultsPerPage, :PageNumber, :Highlight
      def initialize(options = {}, info)

        # defaults
        @View = info.default_result_list_view
        @ResultsPerPage = info.default_results_per_page
        @PageNumber = 1

        options.each do |key, value|

          case key

            # ====================================================================================
            # view
            # ====================================================================================
            when :view
              if info.available_result_list_views.include? value.downcase
                @View = value.downcase
              else
                @View = info.default_result_list_view
              end

            # ====================================================================================
            # results per page
            # ====================================================================================
            when :results_per_page, 'results_per_page', 'rows', 'per_page'
              if value.to_i > info.max_results_per_page
                @ResultsPerPage = info.max_results_per_page
              else
                @ResultsPerPage = value.to_i
              end

            # ====================================================================================
            # page number
            # ====================================================================================
            when :page_number, 'page_number', 'page'
              @PageNumber = value.to_i
            # solr starts at page 0
            when 'start'
              @PageNumber = value.to_i + 1

            # ====================================================================================
            # highlight
            # ====================================================================================
            when :highlight
              @Highlight = value ? 'y' : 'n'
            # solr/blacklight version
            when 'hl'
              if value == 'on'
                @Highlight = 'y'
              else
                @Highlight = 'n'
              end

            else

          end

        end

      end
  
    end

  end
end