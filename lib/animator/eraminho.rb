module Animator
  class Eraminho < ActiveRecord::Base
    scope :with_animable_id, ->(animable_id) { where(animable_id: animable_id) }
    scope :with_animable_class, ->(animable_class) { where(animable_class: animable_class) }
    scope :with_transaction_uuid, ->(transaction_uuid) { where(transaction_uuid: transaction_uuid) }

    def self.inanimate_for(klass)
      klass.from("(#{with_animable_class(klass.base_class.name).select((["\"eraminhos\".\"id\" AS \"eraminho_id\""] + klass.columns.map { |column| "(\"eraminhos\".\"anima\"::json->>'#{column.name}')::#{column.sql_type} AS \"#{column.name}\"" }).join(', ')).to_sql}) AS \"#{klass.table_name}\"")
    end

    def animable=(animable)
      if animable
        raise(TypeError, "Attempted to set #{animable.inspect} as the animable of an Eraminho, but #{animable.class.name} has not included Animator::Animable") unless animable.is_a?(Animable)

        self.animable_class = animable.class.base_class.name
        self.animable_id = animable[animable.class.primary_key] if animable.class.primary_key
        self.transaction_uuid = Animator.current_transaction_uuid
        self.anima = ActiveSupport::JSON.encode animable.anima_attributes
      end

      @animable = animable
    end

    def animable
      animable! rescue nil
    end

    def animable!
      @animable ||= self.class.where(id: id).inanimate_for(animable_class.constantize).first!
    end
  end
end