module Elasticsearch
  module ResponseExt
    def single_model_records(options = {})
      @records ||= begin
        single_model_klass = klass.single_model_name.constantize
        Elasticsearch::Model::Response::Records.new(single_model_klass, self, options)
      end
    end
  end
end

Elasticsearch::Model::Response::Response.prepend(Elasticsearch::ResponseExt)
