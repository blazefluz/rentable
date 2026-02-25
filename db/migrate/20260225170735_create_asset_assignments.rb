class CreateAssetAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_assignments do |t|
      t.references :product, null: false, foreign_key: true
      t.references :assigned_to, polymorphic: true, null: false
      t.datetime :start_date
      t.datetime :end_date
      t.string :purpose
      t.text :notes
      t.integer :status
      t.datetime :returned_date
      t.boolean :deleted

      t.timestamps
    end
  end
end
