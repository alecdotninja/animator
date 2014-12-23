require 'securerandom'
require 'yaml'

module Animator
  class Eraminho < ActiveRecord::Base
    scope :with_animable_id, ->(animable_id) { where(animable_id: animable_id) }
    scope :with_animable_class, ->(animable_class) { where(animable_class: animable_class) }
    
    scope :with_animable_attribute, ->(attribute_name, value) { where(arel_table[:anima].matches("% #{YAML.dump(attribute_name.to_s => value).gsub(/^---\n/, '')}%")) }
    scope :with_animable_attributes, ->(attributes) { attributes.to_a.reduce(all) { |relation, key_value_pair| relation.with_animable_attribute(*key_value_pair) } }
    
    scope :with_transaction_uuid, ->(transaction_uuid) { where(transaction_uuid: transaction_uuid) }

    def animable=(animable)
      if animable
        raise(TypeError, "Attempted to set #{animable.inspect} as the animable of an Eraminho, but #{animable.class.name} has not included Animator::Animable") unless animable.is_a?(Animable)

        self.animable_class = animable.class.name
        self.animable_id = animable[animable.class.primary_key] if animable.class.primary_key
        self.transaction_uuid = get_current_transaction_uuid(animable.class.connection)
        self.anima = YAML.dump(animable)
      end

      @animable = animable
    end

    def animable
      animable! rescue nil
    end

    def animable!
      unless @animable
        animable_class.constantize rescue nil # This is required because of ActiveSupport's lazy loading
        @animable = YAML.load(anima)

        raise(ReanimationError, "#{@animable.class.name} has not included Animator::Animable") unless @animable.is_a?(Animable)

        @animable.instance_variable_set(:@destroyed, true)
        @animable.instance_variable_set(:@eraminho, self)
      end

      @animable
    end

    private

    def get_current_transaction_uuid(connection)
      connection.current_transaction.instance_eval { @__animator_transaction_uuid__ ||= SecureRandom.uuid }
    end
  end
end