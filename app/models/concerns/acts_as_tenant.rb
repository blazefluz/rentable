module ActsAsTenant
  extend ActiveSupport::Concern

  included do
    belongs_to :instance, optional: true
    
    # Default scope to current tenant
    default_scope { where(instance_id: Current.instance_id) if Current.tenant_set? }
    
    # Scope to get all records across tenants (for admin operations)
    scope :unscoped_by_tenant, -> { unscope(where: :instance_id) }
    scope :for_instance, ->(instance) { unscope(where: :instance_id).where(instance: instance) }
    
    # Automatically set instance on creation
    before_validation :set_current_instance, on: :create
    
    # Validate that instance is set
    validates :instance, presence: true, if: -> { Current.tenant_set? }
  end

  class_methods do
    # Disable tenant scoping for a block
    def without_tenant_scope(&block)
      unscoped_by_tenant.scoping(&block)
    end
    
    # Execute block in context of specific tenant
    def with_tenant(instance, &block)
      old_instance = Current.instance
      Current.instance = instance
      yield
    ensure
      Current.instance = old_instance
    end
  end

  private

  def set_current_instance
    self.instance ||= Current.instance if Current.tenant_set?
  end
end
