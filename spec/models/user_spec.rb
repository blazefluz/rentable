require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should have_secure_password }

    describe 'email uniqueness' do
      subject { build(:user, email: 'test@example.com', password: 'password123', name: 'Test User') }

      it 'validates uniqueness of email' do
        create(:user, email: 'test@example.com')
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to include('has already been taken')
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(customer: 0, staff: 1, admin: 2).with_prefix(:role) }
  end

  describe 'authentication' do
    let(:user) { create(:user, password: 'password123') }

    it 'authenticates with correct password' do
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'fails authentication with incorrect password' do
      expect(user.authenticate('wrong')).to be false
    end
  end

  describe '#generate_api_token' do
    let(:user) { build(:user) }

    it 'generates an API token on create' do
      user.save
      expect(user.api_token).to be_present
    end
  end

  describe 'roles' do
    it 'creates user with staff role by default' do
      user = create(:user)
      expect(user).to be_role_staff
    end

    it 'creates admin user' do
      admin = create(:user, role: :admin)
      expect(admin).to be_role_admin
    end

    it 'creates customer user' do
      customer = create(:user, role: :customer)
      expect(customer).to be_role_customer
    end
  end
end
