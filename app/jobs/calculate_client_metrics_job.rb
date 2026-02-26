class CalculateClientMetricsJob < ApplicationJob
  queue_as :default

  def perform(client_id = nil, date = Date.yesterday)
    if client_id
      # Calculate for specific client
      client = Client.find(client_id)
      ClientMetric.calculate_for_client(client, date)
    else
      # Calculate for all active clients
      Client.active.find_each do |client|
        ClientMetric.calculate_for_client(client, date)
      end
    end
  end
end
