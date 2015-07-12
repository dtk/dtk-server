module XYZ
  class ContextTable
    class << self
      # TBD: may have parent class for infra tables
      def set_db(db)
        @db = db
      end

  ###### SchemaProcessing
  def create?
          @db.create_schema?(CONTEXT_TABLE[:schema])

    @db.create_table? CONTEXT_TABLE do
      primary_key :id #TBD: more columns will be put in
          end
        end
        ###### end: SchemaProcessing

        ###### DataProcessing
        def create_default_contexts?
    #TBD : hard coding contexts 1 and 2
    [1, 2].each do|id|
      context_ds().insert(id: id) if context_ds().where(id: id).empty?
          end
  end

      private

        def context_ds
    @db.dataset(CONTEXT_TABLE)
        end
      ###### end: DataProcessing
    end
  end
end
