class AddMaintenanceFieldsToMaintenanceJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :maintenance_jobs, :is_recurring, :boolean
    add_column :maintenance_jobs, :recurrence_pattern, :string
    add_column :maintenance_jobs, :recurrence_interval, :integer
    add_column :maintenance_jobs, :day_of_week, :integer
    add_column :maintenance_jobs, :day_of_month, :integer
    add_column :maintenance_jobs, :next_occurrence_date, :date
    add_column :maintenance_jobs, :last_generated_date, :date
    add_column :maintenance_jobs, :auto_generate, :boolean
    add_column :maintenance_jobs, :maintenance_type, :integer
    add_column :maintenance_jobs, :estimated_duration_hours, :decimal
    add_column :maintenance_jobs, :required_parts, :jsonb
    add_column :maintenance_jobs, :procedure_notes, :text
    add_column :maintenance_jobs, :actual_duration_hours, :decimal
    add_column :maintenance_jobs, :findings, :text
    add_column :maintenance_jobs, :actions_taken, :text
    add_column :maintenance_jobs, :parts_used, :jsonb
    add_column :maintenance_jobs, :total_cost_breakdown, :jsonb
    add_column :maintenance_jobs, :notified_at, :datetime
  end
end
