module Animator
  module Animable
    extend ActiveSupport::Concern

    class_methods do
      def reanimate_all(*args)
        all.find_each { |animable| animable.reanimate(*args) }
      end

      def inanimate
        Eraminho.inanimate_for(self)
      end
    end

    attr_reader :eraminho_id

    def eraminho
      eraminho! rescue nil
    end

    def animable?
      destroyed? && eraminho.try(:persisted?)
    end

    def reanimate(*args)
      reanimate!(*args) rescue self
    end

    def reanimate!(transactional = true)
      raise(ReanimationError, "#{inspect} is not animable.") unless animable?

      _destroyed, _eraminho, _eraminho_id = @destroyed, @eraminho, @eraminho_id

      begin
        transaction do
          run_callbacks(:reanimate) do
            if transactional
              other_eraminhos_in_transaction = Eraminho.where.not(id: eraminho_id).with_transaction_uuid(eraminho!.transaction_uuid)

              other_eraminhos_in_transaction.uniq.pluck(:animable_class).each do |animable_class|
                other_eraminhos_in_transaction.inanimate_for(animable_class.constantize).find_in_batches do |animables|
                  eraminhos = Eraminho.where(id: animables.map(&:eraminho_id)).to_a

                  animables.each.with_index do |animable, index|
                    eraminho = eraminhos[index]

                    animable.preload_eraminho!(eraminho)
                    animable.reanimate! false
                  end
                end
              end
            end

            self.class.unscoped.insert arel_attributes_with_values_for_create self.class.column_names

            eraminho!.destroy!

            @destroyed, @eraminho, @eraminho_id = false, nil, nil
          end
        end
      rescue Exception
        @destroyed, @eraminho, @eraminho_id = _destroyed, _eraminho, _eraminho_id

        raise
      end

      self
    end

    protected

    def preload_eraminho!(eraminho)
      raise TypeError, 'Eraminho does not match' unless eraminho.try(:id) == eraminho_id

      @eraminho = eraminho
    end

    def anima_attributes
      attributes.merge(changed_attributes)
    end

    private

    def eraminho!
      @eraminho ||= Eraminho.find_by!(id: eraminho_id) if eraminho_id
    end

    included do
      define_callbacks :reanimate

      after_initialize do
        @eraminho_id = read_attribute(:eraminho_id)
        @destroyed = true if @eraminho_id
      end

      after_destroy do
        unless self.is_a?(Eraminho)
          @eraminho = Eraminho.create!(animable: self)
          @eraminho_id = @eraminho.id
        end
      end
    end
  end
end
