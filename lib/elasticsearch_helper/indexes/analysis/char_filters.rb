module ElasticsearchHelper
  module Indexes
    module Analysis
      module CharFilters
        def img_source_char_filter
          {
            img_source_char_filter: {
              type: "pattern_replace",
              pattern: "<img.*?src=\"([^\"]+)\"[^>]+>",
              replacement: "$1"
            }
          }
        end

        def new_line_char_filter
          {
            new_line_char_filter: {
              type: "mapping",
              mappings: [
                "\\u000a => \\u0020"
              ]
            }
          }
        end
      end
    end
  end
end
