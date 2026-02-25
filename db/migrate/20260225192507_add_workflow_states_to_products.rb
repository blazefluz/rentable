class AddWorkflowStatesToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :workflow_state, :integer, default: 0
    add_column :products, :in_maintenance, :boolean, default: false
    add_column :products, :out_of_service, :boolean, default: false
    add_column :products, :reserved_until, :datetime
    add_column :products, :in_transit, :boolean, default: false
    add_column :products, :transit_notes, :text
  end
end
