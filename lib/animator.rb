require 'animator/eraminho'
require 'animator/animable'
require 'animator/reanimation_error'

module Animator
  cattr_reader(:transaction_registry) { ObjectSpace::WeakMap.new }

  def self.connection
    ActiveRecord::Base.connection
  end

  def self.current_transaction
    connection.current_transaction if connection.open_transactions > 0
  end

  def self.current_transaction_uuid
    transaction_registry[current_transaction] ||= SecureRandom.uuid if current_transaction
  end
end