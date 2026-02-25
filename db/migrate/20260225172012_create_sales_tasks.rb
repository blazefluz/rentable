class CreateSalesTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :sales_tasks do |t|
      t.references :client, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.integer :task_type
      t.integer :priority
      t.integer :status
      t.datetime :due_date
      t.datetime :completed_date
      t.boolean :deleted

      t.timestamps
    end
  end
end
