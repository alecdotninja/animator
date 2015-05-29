module Animator
  module Animable
    extend ActiveSupport::Concern

    module ClassMethods
      def reanimate!(id, options = {})
        Eraminho.find_by!(animable_class: name, animable_id: id).animable!.reanimate!(options)
      end

      def reanimate(id, options = {})
        reanimate!(id, options) rescue nil
      end

      def divine(id, options = {}, &block)
        options = { validate: false }.merge(options)

        result = nil

        transaction do
          instance = reanimate!(id, options)
          result = instance.instance_exec(&block)
          raise ActiveRecord::Rollback
        end

        result
      end

      def inanimate(transaction_uuid = nil, relation = all)
        AlmostARelation.new(relation.klass, transaction_uuid).merge(relation)
      end
    end

    def divine(options = {}, &block)
      options = { validate: false }.merge(options)

      result = nil
      eraminho = @eraminho
      destroyed = @destroyed

      transaction do
        reanimate!(options)
        result = instance_exec(&block)
        raise ActiveRecord::Rollback
      end

      @eraminho = eraminho
      @destroyed = destroyed
      result
    end

    def animable?
      destroyed? && !@eraminho.nil?
    end

    def reanimate!(options = {}, validation_queue = nil)
      klass = self.class
      options = { force: false, transactional: true, validate: true, dry: false }.merge(options)
      
      raise(ReanimationError, "#{inspect} is not animable.") unless animable?

      eraminho = @eraminho

      transaction do
        if validation_queue
          run_callbacks(:reanimate) do
            if options[:transactional]
              Eraminho.with_transaction_uuid(@eraminho.transaction_uuid).find_each do |eraminho|
                if options[:force]
                  eraminho.animable!.reanimate(options.merge(transactional: false, force: false), validation_queue)
                else
                  eraminho.animable!.reanimate!(options.merge(transactional: false, force: false), validation_queue)
                end
              end
            else
              klass.unscoped.insert arel_attributes_with_values_for_create attribute_names
              validation_queue << self if options[:validate]
              @eraminho.delete
            end

            @eraminho = nil
            @destroyed = false   
          end 
        else
          validation_queue = []

          reanimate!(options, validation_queue)

          validation_queue.each do |animable| 
            unless animable.valid?(:reanimate)
              raise(ActiveRecord::RecordInvalid.new(animable))
            end
          end

          if options[:dry]
            @eraminho = eraminho
            @destroyed = true
            raise(ActiveRecord::Rollback) 
          end
        end
      end

      self
    end

    def reanimate(options = {}, validation_queue = nil)
      reanimate!(options, validation_queue) rescue self
    end

    def eraminho
      @eraminho
    end

    included do
      define_callbacks :reanimate
      
      before_destroy do |animable| 
        unless animable?
          @eraminho = Eraminho.create!(animable: animable)
        end
      end
    end
  end
end
