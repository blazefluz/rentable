class EmailQueueService
  # Queue an email for sending
  def self.queue_email(recipient:, subject:, body:, metadata: {})
    EmailQueue.create!(
      recipient: recipient,
      subject: subject,
      body: body,
      metadata: metadata
    )
  end

  # Queue booking confirmation email
  def self.queue_booking_confirmation(booking)
    queue_email(
      recipient: booking.customer_email,
      subject: "Booking Confirmation - #{booking.reference_number}",
      body: render_booking_confirmation_body(booking),
      metadata: {
        type: 'booking_confirmation',
        booking_id: booking.id
      }
    )
  end

  # Queue payment received email
  def self.queue_payment_received(payment)
    booking = payment.booking
    queue_email(
      recipient: booking.customer_email,
      subject: "Payment Received - #{booking.reference_number}",
      body: render_payment_received_body(payment),
      metadata: {
        type: 'payment_received',
        payment_id: payment.id,
        booking_id: booking.id
      }
    )
  end

  # Queue password reset email
  def self.queue_password_reset(user)
    queue_email(
      recipient: user.email,
      subject: "Password Reset Request",
      body: render_password_reset_body(user),
      metadata: {
        type: 'password_reset',
        user_id: user.id
      }
    )
  end

  # Queue email verification
  def self.queue_email_verification(user)
    queue_email(
      recipient: user.email,
      subject: "Verify Your Email Address",
      body: render_email_verification_body(user),
      metadata: {
        type: 'email_verification',
        user_id: user.id
      }
    )
  end

  # Process queue (can be called from cron or background job)
  def self.process_queue
    EmailQueueProcessorJob.perform_now
  end

  private

  def self.render_booking_confirmation_body(booking)
    <<~BODY
      Hello #{booking.customer_name},

      Your booking has been confirmed!

      Booking Reference: #{booking.reference_number}
      Start Date: #{booking.start_date.strftime('%B %d, %Y')}
      End Date: #{booking.end_date.strftime('%B %d, %Y')}
      Total: #{booking.total_price.format}

      Thank you for your business!
    BODY
  end

  def self.render_payment_received_body(payment)
    booking = payment.booking
    <<~BODY
      Hello #{booking.customer_name},

      We have received your payment.

      Payment Amount: #{payment.amount.format}
      Booking Reference: #{booking.reference_number}
      Payment Date: #{payment.payment_date.strftime('%B %d, %Y')}

      Thank you!
    BODY
  end

  def self.render_password_reset_body(user)
    <<~BODY
      Hello #{user.name},

      You requested a password reset. Click the link below to reset your password:

      [Reset Password Link with token: #{user.reset_password_token}]

      This link will expire in 2 hours.

      If you didn't request this, please ignore this email.
    BODY
  end

  def self.render_email_verification_body(user)
    <<~BODY
      Hello #{user.name},

      Please verify your email address by clicking the link below:

      [Verification Link with token: #{user.verification_token}]

      Thank you!
    BODY
  end
end
