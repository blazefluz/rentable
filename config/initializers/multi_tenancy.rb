# Multi-tenancy configuration for Rentable

# Manual tenant scoping module (since ActsAsTenant gem is not installed)
module ActsAsTenant
  module Errors
    class NoTenantSet < StandardError; end
  end

  mattr_accessor :current_tenant

  def self.with_tenant(tenant, &block)
    previous_tenant = current_tenant
    self.current_tenant = tenant
    yield
  ensure
    self.current_tenant = previous_tenant
  end

  # This method is called when included in a model
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # This is what gets called in models: acts_as_tenant(:company)
    def acts_as_tenant(tenant_key)
      tenant_id_key = "#{tenant_key}_id"

      # Add default scope to filter by current tenant
      default_scope -> {
        if ActsAsTenant.current_tenant
          where(tenant_id_key => ActsAsTenant.current_tenant.id)
        else
          all
        end
      }

      # Automatically set tenant on create
      before_validation(on: :create) do
        if ActsAsTenant.current_tenant && self.send(tenant_id_key).nil?
          self.send("#{tenant_id_key}=", ActsAsTenant.current_tenant.id)
        end
      end
    end
  end
end
