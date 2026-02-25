class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :addressable, polymorphic: true, null: false
      t.integer :address_type
      t.string :street_line1
      t.string :street_line2
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country
      t.boolean :is_primary
      t.boolean :deleted

      t.timestamps
    end
  end
end
