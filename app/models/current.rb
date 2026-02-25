class Current < ActiveSupport::CurrentAttributes
  attribute :tenant, :user

  # Convenience methods
  def self.tenant_id
    tenant&.id
  end

  def self.tenant_set?
    tenant.present?
  end
end
