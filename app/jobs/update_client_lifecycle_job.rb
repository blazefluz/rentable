class UpdateClientLifecycleJob < ApplicationJob
  queue_as :default

  def perform(client_id = nil)
    if client_id
      # Update specific client
      client = Client.find(client_id)
      update_client_lifecycle(client)
    else
      # Update all active clients
      Client.active.find_each do |client|
        update_client_lifecycle(client)
      end
    end
  end

  private

  def update_client_lifecycle(client)
    client.update_lifecycle_metrics!

    # Update churn risk
    calculated_risk = client.calculate_churn_risk
    client.update(churn_risk: calculated_risk) if client.churn_risk != calculated_risk

    # Update health score
    client.update(health_score: client.calculate_health_score)
  rescue => e
    Rails.logger.error "Failed to update lifecycle for client #{client.id}: #{e.message}"
  end
end
