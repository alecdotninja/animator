require 'rails/generators'
require 'rails/generators/active_record'

module Animator
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    source_root File.expand_path('../templates', __FILE__)

    def create_migration_file
      migration_template 'create_eraminhos.rb', 'db/migrate/create_eraminhos.rb'
      create_file_template 'animator.rb', 'config/initializers/animator.rb'
    end

    private

    def create_file_template(source, destination)
      source  = File.expand_path(find_in_source_paths(source.to_s))
      context = instance_eval('binding')
      create_file(destination, ERB.new(::File.binread(source), nil, '-', '@output_buffer').result(context))
    end
  end
end