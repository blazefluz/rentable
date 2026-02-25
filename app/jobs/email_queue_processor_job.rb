class EmailQueueProcessorJob < ApplicationJob
  queue_as :default

  # Process pending emails in the queue
  def perform
    EmailQueue.ready_to_send.find_each do |email|
      email.send_email!
    end

    # Retry failed emails that are eligible for retry
    EmailQueue.where(status: :failed)
              .where('attempts < ?', 5)
              .where('last_attempt_at < ?', 1.hour.ago)
              .find_each do |email|
      email.retry!
    end
  end
end
