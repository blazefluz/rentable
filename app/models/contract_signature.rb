class ContractSignature < ApplicationRecord
  belongs_to :contract
  belongs_to :user, optional: true

  # Enums
  enum :signer_role, {
    customer: 0,
    staff: 1,
    witness: 2,
    guarantor: 3,
    manager: 4,
    other: 5
  }, prefix: true

  enum :signature_type, {
    digital_signature: 0,    # Mouse/touch drawn signature
    typed_name: 1,           # Typed full name as signature
    uploaded_image: 2,       # Uploaded signature image
    electronic_consent: 3,   # Simple checkbox "I agree"
    biometric: 4            # Future: fingerprint/face ID
  }, prefix: true

  # Validations
  validates :signer_name, presence: true
  validates :signer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :signer_role, presence: true
  validates :signature_type, presence: true

  # Callbacks
  before_create :capture_metadata
  after_create :update_contract_status

  # Scopes
  scope :signed, -> { where.not(signed_at: nil) }
  scope :unsigned, -> { where(signed_at: nil) }
  scope :by_role, ->(role) { where(signer_role: role) if role.present? }
  scope :with_terms_accepted, -> { where(accepted_terms: true) }
  scope :pending, -> { where(signed_at: nil, deleted: false) }

  # Instance methods

  # Sign the contract
  def sign!(signature_data: nil, ip_address: nil, user_agent: nil, accept_terms: true)
    update!(
      signature_data: signature_data,
      signed_at: Time.current,
      accepted_terms: accept_terms,
      ip_address: ip_address || self.ip_address,
      user_agent: user_agent || self.user_agent,
      terms_version: contract.version
    )

    # Update contract status after signing
    contract.reload
    if contract.fully_signed?
      contract.mark_fully_signed!
    elsif contract.status_draft? || contract.status_pending_signature?
      contract.update!(status: :partially_signed)
    end

    true
  end

  # Add witness signature
  def add_witness!(witness_name:, witness_signature_data:)
    update!(
      witness_name: witness_name,
      witness_signature: witness_signature_data
    )
  end

  # Check if signed
  def signed?
    signed_at.present?
  end

  # Check if terms were accepted
  def terms_accepted?
    accepted_terms?
  end

  # Get time since signed
  def time_since_signed
    return nil unless signed?

    diff = Time.current - signed_at
    if diff < 1.hour
      "#{(diff / 60).to_i} minutes ago"
    elsif diff < 1.day
      "#{(diff / 3600).to_i} hours ago"
    else
      "#{(diff / 86400).to_i} days ago"
    end
  end

  # Verify signature integrity (basic check)
  def verify_signature
    return false unless signed?
    return false unless signature_data.present?

    # Check that signature data looks valid based on type
    case signature_type
    when 'digital_signature'
      # Should be SVG path data or base64 image
      signature_data.include?('data:image') || signature_data.start_with?('<svg')
    when 'typed_name'
      # Should match signer name
      signature_data.downcase.include?(signer_name.downcase.split.first)
    when 'uploaded_image'
      # Should be base64 image data
      signature_data.start_with?('data:image')
    when 'electronic_consent'
      # Should be confirmation text
      signature_data.include?('agree') || signature_data.include?('accept')
    else
      false
    end
  end

  # Generate signature proof document
  def generate_proof_document
    {
      contract_id: contract.id,
      contract_title: contract.title,
      signer_name: signer_name,
      signer_email: signer_email,
      signer_role: signer_role,
      signed_at: signed_at,
      ip_address: ip_address,
      user_agent: user_agent,
      terms_version: terms_version,
      accepted_terms: accepted_terms,
      signature_verified: verify_signature,
      witness_name: witness_name,
      timestamp: Time.current
    }
  end

  # Soft delete
  def soft_delete!
    update!(deleted: true)
  end

  private

  def capture_metadata
    # Capture metadata if not already set
    self.terms_version ||= contract.version
  end

  def update_contract_status
    # Update contract to pending_signature if it's still draft
    if contract.status_draft? && !contract.status_pending_signature?
      contract.update!(status: :pending_signature)
    end
  end
end
