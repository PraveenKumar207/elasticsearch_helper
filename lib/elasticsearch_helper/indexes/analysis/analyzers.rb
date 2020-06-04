module ElasticsearchHelper
  module Indexes
    module Analysis
      module Analyzers
        def custom_english_analyzer
          {
            custom_english_analyzer: {
              tokenizer: "standard",
              filter: [
                "english_possessive_stemmer",
                "lowercase",
                "english_stop",
                "english_stemmer"
              ]
            }
          }
        end

        def standard_analyzer
          {
            standard_analyzer: {
              type: "custom",
              tokenizer: "standard"
            }
          }
        end

        def edge_ngram_analyzer
          {
            edge_ngram_analyzer: {
              type: "custom",
              tokenizer: "standard",
              filter: [
                "lowercase",
                "english_possessive_stemmer",
                "english_stop",
                "english_stemmer",
                "custom_edge_ngram_filter"
              ]
            }
          }
        end

        def mathjax_analyzer
          {
            mathjax_analyzer: {
              type: "custom",
              tokenizer: "whitespace",
              char_filter: ["img_source_char_filter", "html_strip"],
              filter: [
                "lowercase",
                "english_possessive_stemmer",
                "english_stop",
                "english_stemmer"
              ]
            }
          }
        end

        def mathjax_shingle_analyzer
          {
            mathjax_shingle_analyzer: {
              type: "custom",
              tokenizer: "whitespace",
              char_filter: ["img_source_char_filter", "html_strip"],
              filter: [
                "lowercase",
                "english_possessive_stemmer",
                "english_stop",
                "english_stemmer",
                "mathjax_shingle_filter"
              ]
            }
          }
        end

        def shingle_analyzer
          {
            shingle_analyzer: {
              type: "custom",
              tokenizer: "standard",
              filter: [
                "lowercase",
                "english_possessive_stemmer",
                "english_stemmer",
                "shingle_filter"
              ]
            }
          }
        end

        def reverse_analyzer
          {
            reverse_analyzer: {
              type: "custom",
              tokenizer: "standard",
              filter: [
                "lowercase",
                "english_possessive_stemmer",
                "english_stop",
                "english_stemmer",
                "reverse"
              ]
            }
          }
        end

        def trigram_analyzer
          {
            trigram_analyzer: {
              type: "custom",
              tokenizer: "standard",
              filter: [
                "lowercase",
                "english_possessive_stemmer",
                "english_stop",
                "english_stemmer",
                "trigram_filter"
              ]
            }
          }
        end
      end
    end
  end
end
