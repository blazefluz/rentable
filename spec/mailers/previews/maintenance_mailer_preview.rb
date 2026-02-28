# Preview all emails at http://localhost:3000/rails/mailers/maintenance_mailer
class MaintenanceMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/maintenance_mailer/maintenance_due
  def maintenance_due
    MaintenanceMailer.maintenance_due
  end

  # Preview this email at http://localhost:3000/rails/mailers/maintenance_mailer/maintenance_overdue
  def maintenance_overdue
    MaintenanceMailer.maintenance_overdue
  end

  # Preview this email at http://localhost:3000/rails/mailers/maintenance_mailer/maintenance_completed
  def maintenance_completed
    MaintenanceMailer.maintenance_completed
  end

  # Preview this email at http://localhost:3000/rails/mailers/maintenance_mailer/job_assigned
  def job_assigned
    MaintenanceMailer.job_assigned
  end

end
