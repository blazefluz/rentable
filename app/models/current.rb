class Current < ActiveSupport::CurrentAttributes
  attribute :instance, :user
  
  # Convenience methods
  def self.instance_id
    instance&.id
  end
  
  def self.tenant_set?
    instance.present?
  end
end
