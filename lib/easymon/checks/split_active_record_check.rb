module Easymon
  class SplitActiveRecordCheck
    attr_accessor :block
    attr_accessor :results
    
    # Here we pass a block so we get a fresh instance of ActiveRecord::Base or
    # whatever other class we might be using to make database connections
    # 
    # For example, given the following other class:
    # module Easymon
    #   class Base < ActiveRecord::Base
    #     def establish_connection(spec = nil)
    #       if spec
    #         super
    #       elsif config = Easymon.database_configuration
    #         super config
    #       end
    #     end
    #
    #     def database_configuration
    #       env = "#{Rails.env}_slave"
    #       config = YAML.load_file(Rails.root.join('config/database.yml'))[env]
    #     end
    #   end
    # end
    # 
    # We would check both it and ActiveRecord::Base like so:
    # check = Easymon::SplitActiveRecordCheck.new {
    #   [ActiveRecord::Base.connection, Easymon::Base.connection] 
    # }
    # Easymon::Repository.add("split-database", check)
    def initialize(&block)
      self.block = block
    end 
    
    # Assumes only 2 connections
    def check
      connections = Array(@block.call)

      results = connections.map{|connection| database_up?(connection) }
      
      master_status = results.first ? "Master: Up" : "Master: Down"
      slave_status = results.last ? "Slave: Up" : "Slave: Down"
      
      [(results.all? && results.count > 0), "#{master_status} - #{slave_status}"]
    end
    
    private
      def database_up?(connection)
          1 == connection.select_value("SELECT 1=1").to_i
      rescue
        false
      end
  end
end