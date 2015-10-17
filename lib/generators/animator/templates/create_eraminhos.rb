class CreateEraminhos < ActiveRecord::Migration
  def change
    create_table :eraminhos do |t|
      t.uuid     :transaction_uuid, null: false
      t.string   :animable_class,   null: false
      t.text     :anima,            null: false
      t.datetime :created_at,       null: false
    end

    add_index :eraminhos, [:transaction_uuid, :animable_class]
  end
end