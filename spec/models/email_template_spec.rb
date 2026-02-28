# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailTemplate, type: :model do
  let(:company) { create(:company) }
  let(:email_template) { build(:email_template, company: company) }

  describe 'validations' do
    it { should validate_presence_of(:company) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:subject) }
    it { should validate_presence_of(:html_body) }
    it { should validate_presence_of(:category) }
  end

  describe 'associations' do
    it { should belong_to(:company) }
  end

  describe 'enums' do
    it do
      should define_enum_for(:category).with_values(
        booking: 0,
        quote: 1,
        reminder: 2,
        marketing: 3,
        transactional: 4
      )
    end
  end

  describe 'scopes' do
    before do
      ActsAsTenant.with_tenant(company) do
        @active_template = create(:email_template, active: true, company: company)
        @inactive_template = create(:email_template, active: false, company: company)
      end
    end

    it 'returns active templates' do
      ActsAsTenant.with_tenant(company) do
        expect(EmailTemplate.active).to include(@active_template)
        expect(EmailTemplate.active).not_to include(@inactive_template)
      end
    end
  end

  describe '#extract_variables_from_templates' do
    it 'extracts variables from subject and html_body' do
      template = build(:email_template,
                       subject: 'Quote {{quote_number}} for {{customer_name}}',
                       html_body: '<p>Hi {{customer_name}}, your total is {{total_amount}}</p>')

      variables = template.extract_variables_from_templates

      expect(variables).to contain_exactly('quote_number', 'customer_name', 'total_amount')
    end

    it 'returns unique variables' do
      template = build(:email_template,
                       subject: 'Quote for {{customer_name}}',
                       html_body: '<p>Hi {{customer_name}}</p>')

      variables = template.extract_variables_from_templates

      expect(variables).to eq(['customer_name'])
    end

    it 'returns empty array when no variables present' do
      template = build(:email_template,
                       subject: 'Static subject',
                       html_body: '<p>Static content</p>')

      variables = template.extract_variables_from_templates

      expect(variables).to be_empty
    end
  end

  describe '#available_variables' do
    it 'returns variables from variable_schema' do
      template = build(:email_template,
                       variable_schema: {
                         customer_name: { type: 'string', required: true },
                         quote_number: { type: 'string', required: true },
                         total_amount: { type: 'number', required: false }
                       })

      expect(template.available_variables).to contain_exactly('customer_name', 'quote_number', 'total_amount')
    end

    it 'returns empty array when variable_schema is nil' do
      template = build(:email_template, variable_schema: nil)

      expect(template.available_variables).to be_empty
    end
  end

  describe '#preview' do
    let(:template) do
      build(:email_template,
            subject: 'Quote {{quote_number}} for {{customer_name}}',
            html_body: '<p>Hi {{customer_name}}, your quote {{quote_number}} total is {{total}}.</p>',
            text_body: 'Hi {{customer_name}}, your quote {{quote_number}} total is {{total}}.')
    end

    it 'substitutes variables in all fields' do
      variables = {
        customer_name: 'Acme Corp',
        quote_number: 'Q-12345',
        total: '$1,000'
      }

      preview = template.preview(variables)

      expect(preview[:subject]).to eq('Quote Q-12345 for Acme Corp')
      expect(preview[:html_body]).to include('Hi Acme Corp')
      expect(preview[:html_body]).to include('quote Q-12345')
      expect(preview[:html_body]).to include('total is $1,000')
      expect(preview[:text_body]).to include('Hi Acme Corp')
    end

    it 'leaves placeholders when variables not provided' do
      variables = { customer_name: 'Acme Corp' }

      preview = template.preview(variables)

      expect(preview[:subject]).to eq('Quote {{quote_number}} for Acme Corp')
      expect(preview[:html_body]).to include('{{quote_number}}')
      expect(preview[:html_body]).to include('{{total}}')
    end
  end

  describe '#substitute_variables' do
    let(:template) { build(:email_template) }

    it 'replaces placeholders with string values' do
      text = 'Hello {{name}}, welcome to {{company}}!'
      variables = { name: 'John', company: 'Acme Corp' }

      result = template.substitute_variables(text, variables)

      expect(result).to eq('Hello John, welcome to Acme Corp!')
    end

    it 'handles numeric values' do
      text = 'Your total is {{amount}}'
      variables = { amount: 500 }

      result = template.substitute_variables(text, variables)

      expect(result).to eq('Your total is 500')
    end

    it 'is case-sensitive' do
      text = 'Hello {{Name}} and {{name}}'
      variables = { name: 'john' }

      result = template.substitute_variables(text, variables)

      expect(result).to eq('Hello {{Name}} and john')
    end
  end

  describe '#duplicate' do
    let(:template) { create(:email_template, company: company) }

    it 'creates a copy of the template' do
      ActsAsTenant.with_tenant(company) do
        expect {
          template.duplicate
        }.to change(EmailTemplate, :count).by(1)
      end
    end

    it 'appends (Copy) to the name' do
      ActsAsTenant.with_tenant(company) do
        copy = template.duplicate

        expect(copy.name).to eq("#{template.name} (Copy)")
      end
    end

    it 'sets the copy as inactive by default' do
      ActsAsTenant.with_tenant(company) do
        copy = template.duplicate

        expect(copy.active).to be false
      end
    end

    it 'copies all template content' do
      ActsAsTenant.with_tenant(company) do
        copy = template.duplicate

        expect(copy.subject).to eq(template.subject)
        expect(copy.html_body).to eq(template.html_body)
        expect(copy.text_body).to eq(template.text_body)
        expect(copy.category).to eq(template.category)
      end
    end
  end

  describe 'callbacks' do
    describe 'after_create :extract_and_store_variables' do
      it 'automatically extracts variables on create' do
        template = create(:email_template,
                          company: company,
                          subject: 'Hi {{name}}',
                          html_body: '<p>Your order {{order_id}} is ready</p>',
                          variable_schema: nil)

        expect(template.variable_schema).not_to be_nil
        expect(template.variable_schema.keys.map(&:to_s)).to contain_exactly('name', 'order_id')
      end
    end
  end
end
