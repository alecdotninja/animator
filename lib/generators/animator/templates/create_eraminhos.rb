class CreateEraminhos < ActiveRecord::Migration
  def change
    create_table :eraminhos do |t|
      t.string   :transaction_uuid, null: false
      t.string   :animable_class,   null: false
      t.integer  :animable_id,      null: true   # Support for tables without a primary key
      t.text     :anima,            null: false
      t.datetime :created_at,       null: false
    end

    add_index :eraminhos, [:animable_class, :animable_id]
    add_index :eraminhos, [:animable_class, :transaction_uuid]
    add_index :eraminhos, [:transaction_uuid]
  end
end