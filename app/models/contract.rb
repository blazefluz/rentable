class Contract < ApplicationRecord
  belongs_to :booking, optional: true
  has_many :contract_signatures, dependent: :destroy
  has_many :signers, through: :contract_signatures, source: :user

  # Enums
  enum :contract_type, {
    rental_agreement: 0,
    terms_and_conditions: 1,
    liability_waiver: 2,
    equipment_checklist: 3,
    damage_waiver: 4,
    nda: 5,
    service_agreement: 6,
    custom: 7
  }, prefix: true

  enum :status, {
    draft: 0,
    active: 1,
    pending_signature: 2,
    partially_signed: 3,
    fully_signed: 4,
    expired: 5,
    voided: 6,
    archived: 7
  }, prefix: true

  # Validations
  validates :title, presence: true
  validates :contract_type, presence: true
  validates :status, presence: true
  validates :version, presence: true

  # Scopes
  scope :active_contracts, -> { where(deleted: false, status: [:active, :pending_signature, :partially_signed, :fully_signed]) }
  scope :templates, -> { where(template: true, deleted: false) }
  scope :for_booking, ->(booking_id) { where(booking_id: booking_id, deleted: false) }
  scope :requiring_signature, -> { where(requires_signature: true, deleted: false) }
  scope :pending_signatures, -> { where(status: [:pending_signature, :partially_signed], deleted: false) }
  scope :fully_signed, -> { where(status: :fully_signed, deleted: false) }
  scope :expired, -> { where('expiry_date < ?', Date.today).where(deleted: false) }
  scope :by_type, ->(type) { where(contract_type: type) if type.present? }

  # Class methods
  def self.create_from_template(template_name, booking: nil, variables: {})
    template = templates.find_by(template_name: template_name)
    return nil unless template

    create!(
      booking: booking,
      contract_type: template.contract_type,
      title: template.title,
      content: substitute_variables(template.content, variables),
      version: template.version,
      requires_signature: template.requires_signature,
      status: :draft,
      variables: variables,
      effective_date: Date.today
    )
  end

  def self.substitute_variables(content, variables)
    result = content.dup
    variables.each do |key, value|
      result.gsub!("{{#{key}}}", value.to_s)
    end
    result
  end

  # Instance methods

  # Generate PDF document
  def generate_pdf!
    pdf_content = ContractPdfGenerator.new(self).generate
    filename = "contract_#{id}_#{Time.current.to_i}.pdf"
    filepath = Rails.root.join('tmp', 'contracts', filename)

    FileUtils.mkdir_p(File.dirname(filepath))
    File.binwrite(filepath, pdf_content)

    update!(pdf_file: filename)
    filepath
  end

  # Check if contract is fully signed
  def fully_signed?
    return false unless requires_signature?
    required_signatures_complete?
  end

  # Check if all required signatures are present
  def required_signatures_complete?
    required_roles = determine_required_roles
    signed_roles = contract_signatures.where.not(signed_at: nil).pluck(:signer_role).map(&:to_s)

    required_roles.all? { |role| signed_roles.include?(role) }
  end

  # Determine which roles need to sign
  def determine_required_roles
    case contract_type
    when 'rental_agreement', 'service_agreement'
      ['customer', 'staff']
    when 'liability_waiver', 'damage_waiver'
      ['customer']
    when 'nda'
      ['customer', 'witness']
    else
      ['customer']
    end
  end

  # Add signature request
  def request_signature(signer_name:, signer_email:, signer_role:, user: nil)
    contract_signatures.create!(
      user: user,
      signer_name: signer_name,
      signer_email: signer_email,
      signer_role: signer_role,
      accepted_terms: false
    )
  end

  # Check if expired
  def expired?
    expiry_date.present? && expiry_date < Date.today
  end

  # Check if effective
  def effective?
    return false if expired?
    return true if effective_date.nil?

    effective_date <= Date.today
  end

  # Mark as fully signed and update status
  def mark_fully_signed!
    update!(status: :fully_signed) if fully_signed?
  end

  # Void the contract
  def void!(reason: nil)
    update!(
      status: :voided,
      variables: variables.merge(void_reason: reason, voided_at: Time.current)
    )
  end

  # Archive the contract
  def archive!
    update!(status: :archived)
  end

  # Soft delete
  def soft_delete!
    update!(deleted: true)
  end

  # Get signing progress percentage
  def signing_progress
    return 100 if status_fully_signed?
    return 0 unless requires_signature?

    required_count = determine_required_roles.count
    signed_count = contract_signatures.where.not(signed_at: nil).count

    ((signed_count.to_f / required_count) * 100).to_i
  end

  # Get list of pending signers
  def pending_signers
    signed_emails = contract_signatures.where.not(signed_at: nil).pluck(:signer_email)
    contract_signatures.where(signed_at: nil)
      .where.not(signer_email: signed_emails)
      .select(:signer_name, :signer_email, :signer_role)
  end

  # Send signature reminders
  def send_signature_reminders!
    pending_signers.each do |signer|
      ContractMailer.signature_reminder(self, signer).deliver_later
    end
  end

  # Clone contract for new booking
  def clone_for_booking(new_booking)
    self.class.create!(
      booking: new_booking,
      contract_type: contract_type,
      title: title,
      content: content,
      version: version,
      requires_signature: requires_signature,
      status: :draft,
      variables: variables.except('void_reason', 'voided_at'),
      effective_date: Date.today
    )
  end
end
