module ElasticsearchHelper
  module Indexes
    module Analysis
      module Filters
        STOPWORDS = %w(
          i me my myself we our ours ourselves you you're you've
          you'll you'd your yours yourself yourselves he him his himself
          she she's her hers herself it it's its itself they them
          their theirs themselves what which who whom this that that'll
          these those am is are was were be been being have has
          had having do does did doing a an the and but if or
          because as until while of at by for with about against
          between into through during before after above below to from
          up down in out on off over under again further then once
          here there when where why how all any both each few more
          most other some such no nor not only own same so than
          too very s t can will just don don't should should've
          now d ll m o re ve y ain aren aren't couldn couldn't
          didn didn't doesn doesn't hadn hadn't hasn hasn't haven
          haven't isn isn't ma mightn mightn't mustn mustn't needn
          needn't shan shan't shouldn shouldn't wasn wasn't weren weren't
          won won't wouldn wouldn't search google ok tell say videos
          video journeys journey learn show practice
        ).freeze

        def custom_edge_ngram_filter
          {
            custom_edge_ngram_filter: {
              type: 'edge_ngram',
              min_gram: '2',
              max_gram: '30'
            }
          }
        end

        def mathjax_shingle_filter
          {
            mathjax_shingle_filter: {
              type: 'shingle',
              max_shingle_size: 5,
              min_shingle_size: 2,
              filler_token: ''
            }
          }
        end

        def shingle_filter
          {
            shingle_filter: {
              type: 'shingle',
              max_shingle_size: 3,
              min_shingle_size: 2,
              filler_token: '',
              output_unigrams: false
            }
          }
        end

        def english_filters
          {
            english_stop: {
              type: 'stop',
              stopwords: STOPWORDS
            },
            english_stemmer: {
              type: 'stemmer',
              language: 'english'
            },
            english_possessive_stemmer: {
              type: 'stemmer',
              language: 'possessive_english'
            }
          }
        end

        def trigram_filter
          {
            trigram_filter: {
              type: 'shingle',
              filler_token: '',
              max_shingle_size: 3,
              min_shingle_size: 2
            }
          }
        end
      end
    end
  end
end
