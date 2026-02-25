# app/jobs/send_payment_confirmation_job.rb
class SendPaymentConfirmationJob < ApplicationJob
  queue_as :default

  def perform(payment_id)
    payment = Payment.find(payment_id)
    booking = payment.booking

    begin
      BookingMailer.payment_received(booking, payment).deliver_now
      Rails.logger.info "Sent payment confirmation for booking #{booking.reference_number}"
    rescue => e
      Rails.logger.error "Failed to send payment confirmation: #{e.message}"
      raise
    end
  end
end
