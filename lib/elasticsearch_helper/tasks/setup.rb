module ElasticsearchHelper
  module Tasks
    class Setup
      def initialize(es_version, cerebro_version, es_setup_dir )
        @elasticsearch_version = es_version
        @cerebro_version = cerebro_version
        @setup_dir = es_setup_dir
      end

      def run
        `mkdir -p #{setup_dir}`
        install_elasticsearch
        # install_cerebro
      end

      private

        attr_reader :elasticsearch_version, :cerebro_version, :setup_dir

        def install_elasticsearch
          if !File.directory?(elasticsearch_dir)
            puts 'Installing elasticsearch'

            Dir.chdir setup_dir do
              `curl -L -O #{elasticsearch_package_url}`
              `tar -xvf elasticsearch-#{elasticsearch_version}.tar.gz`
              `rm elasticsearch-#{elasticsearch_version}.tar.gz`
            end
          else
            puts 'Elasticsearch already installed'
          end
        end

        def install_cerebro
          if !File.directory?(cerebro_dir)
            puts 'Installing cerebro'

            Dir.chdir setup_dir do
              `curl -L -O #{cerebro_package_url}`
              `tar -xvf cerebro-#{cerebro_version}.tgz`
              `sed -i #{''.shellescape} #{'s/logs\/application.log/log\/cerebro.log/'.shellescape} cerebro-#{cerebro_version}/conf/logback.xml`
              `rm cerebro-#{cerebro_version}.tgz`
            end
          else
            puts 'Cerebro already installed'
          end
        end

        def elasticsearch_dir
          File.join(setup_dir, "elasticsearch-#{elasticsearch_version}")
        end

        def cerebro_dir
          File.join(setup_dir, "cerebro-#{cerebro_version}")
        end

        def elasticsearch_package_url
          "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-#{elasticsearch_version}.tar.gz"
        end

        def cerebro_package_url
          "https://github.com/lmenezes/cerebro/releases/download/v#{cerebro_version}/cerebro-#{cerebro_version}.tgz"
        end
    end
  end
end
