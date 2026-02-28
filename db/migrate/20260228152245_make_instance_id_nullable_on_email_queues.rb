class MakeInstanceIdNullableOnEmailQueues < ActiveRecord::Migration[8.1]
  def change
    change_column_null :email_queues, :instance_id, true
  end
end
