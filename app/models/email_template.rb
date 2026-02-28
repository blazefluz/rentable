# frozen_string_literal: true

class EmailTemplate < ApplicationRecord
  include ActsAsTenant

  # Enums
  enum :category, {
    quote: 0,
    booking: 1,
    reminder: 2,
    marketing: 3,
    transactional: 4,
    customer_service: 5
  }

  # Associations
  belongs_to :company

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :category, presence: true
  validates :subject, presence: true
  validates :html_body, presence: true
  validates :variable_schema, presence: true
  validate :validate_variable_schema

  # Scopes
  scope :active_templates, -> { where(active: true) }
  scope :by_category, ->(cat) { where(category: cat) }

  # Callbacks
  before_validation :ensure_variable_schema

  # Instance methods
  def substitute_variables(template, variables = {})
    result = template.dup
    variables.each do |key, value|
      placeholder = "{{#{key}}}"
      result.gsub!(placeholder, value.to_s) if result.include?(placeholder)
    end
    result
  end

  def render_subject(variables = {})
    substitute_variables(subject, variables)
  end

  def render_html_body(variables = {})
    substitute_variables(html_body, variables)
  end

  def render_text_body(variables = {})
    return nil if text_body.blank?
    substitute_variables(text_body, variables)
  end

  def available_variables
    variable_schema&.keys || []
  end

  def preview(sample_variables = {})
    {
      subject: render_subject(sample_variables),
      html_body: render_html_body(sample_variables),
      text_body: render_text_body(sample_variables),
      variables_used: extract_variables_from_templates
    }
  end

  def extract_variables_from_templates
    variables = []
    [subject, html_body, text_body].compact.each do |template|
      variables += template.scan(/\{\{(\w+)\}\}/).flatten
    end
    variables.uniq
  end

  def missing_variables?(variables)
    required = extract_variables_from_templates
    (required - variables.keys.map(&:to_s)).present?
  end

  def clone_for_campaign(campaign_name)
    self.class.new(
      company: company,
      name: "#{name} - #{campaign_name}",
      category: category,
      subject: subject,
      html_body: html_body,
      text_body: text_body,
      variable_schema: variable_schema,
      active: active
    )
  end

  private

  def ensure_variable_schema
    self.variable_schema ||= {}
  end

  def validate_variable_schema
    return if variable_schema.blank?

    unless variable_schema.is_a?(Hash)
      errors.add(:variable_schema, 'must be a valid JSON object')
      return
    end

    # Validate each variable definition
    variable_schema.each do |key, definition|
      unless definition.is_a?(Hash)
        errors.add(:variable_schema, "variable '#{key}' must have a definition object")
      end
    end
  end
end
