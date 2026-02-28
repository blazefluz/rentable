class UpdateMaintenanceStatusJob < ApplicationJob
  queue_as :default

  def perform
    # Update maintenance status for all products based on their schedules
    update_product_maintenance_status

    # Update maintenance status for product instances
    update_product_instance_maintenance_status

    # Mark overdue schedules
    mark_overdue_schedules
  end

  private

  def update_product_maintenance_status
    # Find all products with enabled maintenance schedules
    products_with_schedules = Product.joins(:maintenance_schedules)
      .where(maintenance_schedules: { enabled: true })
      .distinct

    products_with_schedules.each do |product|
      # Skip if there's an active maintenance override
      next if product.maintenance_override_by.present?

      new_status = determine_product_maintenance_status(product)

      # Only update if status has changed
      if product.maintenance_status != new_status
        product.update_column(:maintenance_status, Product.maintenance_statuses[new_status])
      end
    end

    Rails.logger.info "[UpdateMaintenanceStatusJob] Updated maintenance status for #{products_with_schedules.count} products"
  end

  def update_product_instance_maintenance_status
    # Find all product instances
    instances_with_schedules = ProductInstance
      .joins(product: :maintenance_schedules)
      .where(maintenance_schedules: { enabled: true })
      .distinct

    instances_with_schedules.each do |instance|
      # Skip if there's an active maintenance override
      next if instance.maintenance_override_by.present?

      new_status = determine_product_maintenance_status(instance.product)

      # Only update if status has changed
      if instance.maintenance_status != new_status
        instance.update_column(:maintenance_status, ProductInstance.maintenance_statuses[new_status])
      end
    end

    Rails.logger.info "[UpdateMaintenanceStatusJob] Updated maintenance status for #{instances_with_schedules.count} product instances"
  end

  def determine_product_maintenance_status(product)
    schedules = product.maintenance_schedules.enabled

    # Check if any schedules are overdue
    if schedules.overdue.any?
      :overdue
    # Check if product is currently in maintenance
    elsif product.workflow_state == 'maintenance' || product.in_maintenance?
      :in_maintenance
    # Check if any schedules are due soon (within 7 days)
    elsif schedules.due_soon(7).any?
      :due_soon
    else
      :current
    end
  end

  def mark_overdue_schedules
    # Find all schedules that should be marked as overdue
    schedules_to_mark = MaintenanceSchedule.enabled
      .where('next_due_date < ?', Time.current)
      .where.not(status: :overdue)

    schedules_to_mark.each do |schedule|
      schedule.mark_overdue!
    end

    Rails.logger.info "[UpdateMaintenanceStatusJob] Marked #{schedules_to_mark.count} schedules as overdue"
  end
end
