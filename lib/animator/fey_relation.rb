module Animator
  class FeyRelation
    attr_reader :transaction_uuid
    attr_reader :where_values_hash
    attr_reader :klass

    def initialize(klass, transaction_uuid = nil, where_values_hash = {}, &block)
      @transaction_uuid = transaction_uuid
      @where_values_hash = where_values_hash
      @klass = klass

      instance_exec(&block) if block
    end

    def spawn(&block)
      self.class.new(@klass, @transaction_uuid, @where_values_hash, &block)
    end

    def where(where_values_hash, &block)
      self.class.new(@klass, @transaction_uuid, @where_values_hash.merge(where_values_hash), &block)
    end

    def merge(relation)
      if relation.is_a?(ActiveRecord::Relation)
        raise(NotImplementedError, "#{self.class.name} does not support joins.") if relation.joins_values.any? || relation.includes_values.any? || relation.joined_includes_values.any?
        raise(NotImplementedError, "#{self.class.name} does not support custom select.") if relation.select_values.any?
        raise(NotImplementedError, "#{self.class.name} does not support aggragation.") if relation.group_values.any? || relation.having_values.any?
      end

      if relation.respond_to?(:klass, false)
        raise('Class mismatch while attempting to merge into #{self.class.name}') unless relation.klass == @klass
      end

      where(relation.where_values_hash) do
        @limit_value = relation.limit_value if relation.respond_to?(:limit_value, false)
        @offset_value = relation.offset_value if relation.respond_to?(:offset_value, false)
      end
    end

    def all
      spawn
    end

    def to_a
      eraminho_relation.map(&:animable)
    end

    def take
      eraminho_relation.take.try(:animable)
    end

    def take!
      take || raise(ActiveRecord::RecordNotFound)
    end

    def find_by(where_values_hash)
      where(where_values_hash).take
    end

    def find_by!(where_values_hash)
      where(where_values_hash).take!
    end

    def find(id)
      find_by!(@klass.primary_key => id)
    end

    def first(limit = nil)
      if limit
        eraminho_relation.first(limit).map(&:animable)
      else
        eraminho_relation.first.try(:animable)
      end
    end

    def first!
      first || raise(ActiveRecord::RecordNotFound)
    end

    def last(limit = nil)
      if limit
        eraminho_relation.last(limit).map(&:animable)
      else
        eraminho_relation.last.try(:animable)
      end
    end

    def last!
      last || raise(ActiveRecord::RecordNotFound)
    end

    def exists?(where_values_hash = nil)
      if where_values_hash
        where(where_values_hash).exists?
      else
        eraminho_relation.exists?
      end
    end

    def count
      eraminho_relation.count
    end

    def pluck(*columns)
      if columns.count > 1
        eraminho_relation.map { |eraminho| columns.map { |column| eraminho.animable!.public_send(column) } }
      else
        eraminho_relation.map { |eraminho| eraminho.animable!.public_send(columns.first) }
      end
    end

    def limit(limit_value)
      spawn do
        @limit_value = limit_value
      end
    end

    def offset(offset_value)
      spawn do
        @offset_value = offset_value
      end
    end

    def ids
      eraminho_relation.pluck(:animable_id)
    end

    def find_each(options = {}, &block)
      eraminho_relation.find_each(options) { |eraminho| block.call(eraminho.animable!) }
    end

    def reset
      eraminho_relation.reset
    end

    def loaded?
      eraminho_relation.loaded?
    end

    def inspect
      entries = to_a.take(11).map!(&:inspect)
      entries[10] = '...' if entries.size == 11

      "#<#{self.class.name} [#{entries.join(', ')}]>"
    end

    def ==(other)
      case other
      when FeyRelation
        eraminho_relation.to_sql == other.eraminho_relation.to_sql
      when Array
        to_a == other
      end
    end

    def reanimate_all!(options = {})
      options = { force: false, transactional: true, validate: true }.merge(options)

      validation_queue = []

      Eraminho.transaction do
        if options[:transactional]
          Eraminho.with_transaction_uuid(eraminho_relation.pluck(:transaction_uuid))
        else
          eraminho_relation
        end.find_each do |eraminho|
          if options[:force]
            eraminho.animable!.reanimate(options.merge(transactional: false, force: false), validation_queue)
          else
            eraminho.animable!.reanimate!(options.merge(transactional: false, force: false), validation_queue)
          end
        end

        validation_queue.each do |animable| 
          unless animable.valid?(:reanimate)
            raise(ActiveRecord::RecordInvalid.new(animable))
          end
        end

        reset
      end

      true
    end

    def reanimate_all(options = {})
      reanimate_all! rescue false
    end

    def to_active_record_relation
      @_active_record_relation ||= @klass.where(@where_values_hash)
    end

    def divine(options = {}, &block)
      options = { validate: false }.merge(options)

      result = nil

      @klass.transaction do
        reanimate_all!(options)
        result = to_active_record_relation.instance_exec(&block)
        raise ActiveRecord::Rollback
      end

      result
    end

    def respond_to_missing?(method_name, include_private = false)
      @klass.respond_to?(method_name, false) || [].respond_to?(method_name, false) || super
    end

    def method_missing(method_name, *args, &block)
      if @klass.respond_to?(method_name, false)
        result = to_active_record_relation.public_send(method_name, *args, &block)

        if result.respond_to?(:where_values_hash)
          result = merge(result)
        else
          result
        end
      elsif [].respond_to?(method_name, false)
        to_a.public_send(method_name, *args, &block)
      else
        super
      end
    end

    protected

    def eraminho_relation
      unless @eraminho_relation
        @eraminho_relation = Eraminho.with_animable_class(@klass.name)

        @eraminho_relation = @eraminho_relation.with_transaction_uuid(@transaction_uuid) if @transaction_uuid

        animable_id = @where_values_hash[@klass.primary_key] || @where_values_hash[@klass.primary_key.to_sym]
        animable_attributes = @where_values_hash.reject { |key| key == @klass.primary_key || key == @klass.primary_key.to_sym }

        @eraminho_relation = @eraminho_relation.with_animable_id(animable_id) if animable_id
        @eraminho_relation = @eraminho_relation.with_animable_attributes(animable_attributes)

        @eraminho_relation = @eraminho_relation.limit(@limit_value) if @limit_value
        @eraminho_relation = @eraminho_relation.offset(@offset_value) if @offset_value
      end

      @eraminho_relation
    end
  end
end