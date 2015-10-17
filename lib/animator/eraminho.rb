module Animator
  class Eraminho < ActiveRecord::Base
    scope :with_animable_class, ->(animable_class) { where(animable_class: animable_class) }
    scope :with_transaction_uuid, ->(transaction_uuid) { where(transaction_uuid: transaction_uuid) }

    before_create :record_animable_class!
    before_create :record_current_transaction_uuid!
    before_create :record_anima!

    def self.inanimate_for(klass)
      klass.from("(#{with_animable_class(klass.base_class.name).select((["\"#{table_name}\".\"id\" AS \"eraminho_id\""] + klass.columns.map { |column| "(\"#{table_name}\".\"anima\"::json->>'#{column.name}')::#{column.sql_type} AS \"#{column.name}\"" }).join(', ')).to_sql}) AS \"#{klass.table_name}\"")
    end

    def animable=(animable)
      if animable && !animable.is_a?(Animable)
        raise(TypeError, "Attempted to set #{animable.inspect} as the animable of an Eraminho, but #{animable.class.name} has not included Animator::Animable")
      end

      @animable = animable
    end

    def animable
      animable! rescue nil
    end

    def animable!
      @animable ||= self.class.where(id: id).inanimate_for(animable_class.constantize).first!
    end

    private

    def record_animable_class!
      self.animable_class = animable!.class.base_class.name
    end

    def record_current_transaction_uuid!
      self.transaction_uuid = Animator.current_transaction_uuid
    end

    def record_anima!
      self.anima = ActiveSupport::JSON.encode animable!.anima_attributes
    end
  end
end