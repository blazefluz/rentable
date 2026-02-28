require 'rails_helper'

RSpec.describe MaintenanceSchedule, type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:user) { create(:user, company: company) }

  describe 'associations' do
    it { should belong_to(:product) }
    it { should belong_to(:company) }
    it { should belong_to(:assigned_to).class_name('User').optional }
    it { should have_many(:maintenance_logs).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:frequency) }
    it { should validate_presence_of(:interval_value) }
    it { should validate_presence_of(:interval_unit) }
    it { should validate_numericality_of(:interval_value).is_greater_than(0).only_integer }
    it { should validate_inclusion_of(:interval_unit).in_array(%w[hours days rentals]) }
  end

  describe 'enums' do
    it { should define_enum_for(:frequency).with_values(hours_based: 'hours_based', days_based: 'days_based', usage_based: 'usage_based').backed_by_column_of_type(:string).with_prefix }
    it { should define_enum_for(:status).with_values(scheduled: 'scheduled', in_progress: 'in_progress', completed: 'completed', overdue: 'overdue').backed_by_column_of_type(:string).with_prefix }
  end

  describe 'scopes' do
    let!(:enabled_schedule) { create(:maintenance_schedule, product: product, company: company, enabled: true) }
    let!(:disabled_schedule) { create(:maintenance_schedule, product: product, company: company, enabled: false) }
    let!(:due_soon_schedule) { create(:maintenance_schedule, product: product, company: company, next_due_date: 3.days.from_now, enabled: true) }
    let!(:overdue_schedule) { create(:maintenance_schedule, product: product, company: company, next_due_date: 2.days.ago, status: :scheduled, enabled: true) }

    describe '.enabled' do
      it 'returns only enabled schedules' do
        expect(MaintenanceSchedule.enabled).to include(enabled_schedule)
        expect(MaintenanceSchedule.enabled).not_to include(disabled_schedule)
      end
    end

    describe '.due_soon' do
      it 'returns schedules due within specified days' do
        ActsAsTenant.with_tenant(company) do
          expect(MaintenanceSchedule.due_soon(7)).to include(due_soon_schedule)
          expect(MaintenanceSchedule.due_soon(7)).not_to include(overdue_schedule)
        end
      end
    end

    describe '.overdue' do
      it 'returns schedules past due date' do
        ActsAsTenant.with_tenant(company) do
          expect(MaintenanceSchedule.overdue).to include(overdue_schedule)
          expect(MaintenanceSchedule.overdue).not_to include(due_soon_schedule)
        end
      end
    end
  end

  describe '#calculate_next_due_date' do
    context 'for hours_based frequency' do
      let(:schedule) { create(:maintenance_schedule, product: product, company: company, frequency: :hours_based, interval_value: 100, interval_unit: 'hours', last_completed_at: 2.days.ago) }

      it 'calculates next due date based on hours' do
        expected_date = 2.days.ago + 100.hours
        expect(schedule.calculate_next_due_date).to be_within(1.second).of(expected_date)
      end
    end

    context 'for days_based frequency' do
      let(:schedule) { create(:maintenance_schedule, product: product, company: company, frequency: :days_based, interval_value: 30, interval_unit: 'days', last_completed_at: 1.week.ago) }

      it 'calculates next due date based on days' do
        expected_date = 1.week.ago + 30.days
        expect(schedule.calculate_next_due_date).to be_within(1.second).of(expected_date)
      end
    end

    context 'for usage_based frequency' do
      let(:schedule) { create(:maintenance_schedule, product: product, company: company, frequency: :usage_based, interval_value: 50, interval_unit: 'rentals', last_completed_at: 1.week.ago) }

      it 'calculates next due date based on estimated usage' do
        # Should return a future date
        expect(schedule.calculate_next_due_date).to be > 1.week.ago
      end
    end
  end

  describe '#mark_overdue!' do
    let(:schedule) { create(:maintenance_schedule, product: product, company: company, next_due_date: 2.days.ago, status: :scheduled) }

    it 'marks schedule as overdue' do
      schedule.mark_overdue!
      expect(schedule.reload.status).to eq('overdue')
    end

    it 'does not mark completed schedules as overdue' do
      schedule.update(status: :completed)
      schedule.mark_overdue!
      expect(schedule.reload.status).to eq('completed')
    end
  end

  describe '#due_soon?' do
    it 'returns true if due within specified days' do
      schedule = create(:maintenance_schedule, product: product, company: company, next_due_date: 3.days.from_now)
      expect(schedule.due_soon?(7)).to be true
    end

    it 'returns false if due beyond specified days' do
      schedule = create(:maintenance_schedule, product: product, company: company, next_due_date: 10.days.from_now)
      expect(schedule.due_soon?(7)).to be false
    end

    it 'returns false if already past due' do
      schedule = create(:maintenance_schedule, product: product, company: company, next_due_date: 2.days.ago)
      expect(schedule.due_soon?(7)).to be false
    end
  end

  describe '#overdue?' do
    it 'returns true if past due date and not completed' do
      schedule = create(:maintenance_schedule, product: product, company: company, next_due_date: 2.days.ago, status: :scheduled)
      expect(schedule.overdue?).to be true
    end

    it 'returns false if completed' do
      schedule = create(:maintenance_schedule, product: product, company: company, next_due_date: 2.days.ago, status: :completed)
      expect(schedule.overdue?).to be false
    end

    it 'returns false if not yet due' do
      schedule = create(:maintenance_schedule, product: product, company: company, next_due_date: 2.days.from_now)
      expect(schedule.overdue?).to be false
    end
  end

  describe '#days_until_due' do
    it 'returns positive days for future due dates' do
      schedule = create(:maintenance_schedule, product: product, company: company, next_due_date: 5.days.from_now)
      expect(schedule.days_until_due).to be_within(1).of(5)
    end

    it 'returns negative days for past due dates' do
      schedule = create(:maintenance_schedule, product: product, company: company, next_due_date: 3.days.ago)
      expect(schedule.days_until_due).to be_within(1).of(-3)
    end
  end

  describe '#complete!' do
    let(:schedule) { create(:maintenance_schedule, product: product, company: company, next_due_date: Time.current, status: :in_progress) }

    it 'creates a maintenance log' do
      expect {
        schedule.complete!(completed_by: user, notes: 'Oil changed')
      }.to change { schedule.maintenance_logs.count }.by(1)
    end

    it 'updates last_completed_at' do
      schedule.complete!(completed_by: user, notes: 'Oil changed')
      expect(schedule.reload.last_completed_at).to be_present
      expect(schedule.last_completed_at).to be_within(1.second).of(Time.current)
    end

    it 'calculates and sets next_due_date' do
      old_due_date = schedule.next_due_date
      schedule.complete!(completed_by: user, notes: 'Oil changed')
      expect(schedule.reload.next_due_date).to be > old_due_date
    end

    it 'sets status to scheduled' do
      schedule.complete!(completed_by: user, notes: 'Oil changed')
      expect(schedule.reload.status).to eq('scheduled')
    end
  end

  describe '#schedule_description' do
    it 'returns human-readable description for hours_based' do
      schedule = build(:maintenance_schedule, frequency: :hours_based, interval_value: 100)
      expect(schedule.schedule_description).to eq('Every 100 hours')
    end

    it 'returns human-readable description for days_based' do
      schedule = build(:maintenance_schedule, frequency: :days_based, interval_value: 30)
      expect(schedule.schedule_description).to eq('Every 30 days')
    end

    it 'returns human-readable description for usage_based' do
      schedule = build(:maintenance_schedule, frequency: :usage_based, interval_value: 50)
      expect(schedule.schedule_description).to eq('Every 50 rentals')
    end
  end

  describe 'callbacks' do
    describe 'set_initial_due_date' do
      it 'sets next_due_date on create if not provided' do
        schedule = create(:maintenance_schedule, product: product, company: company, frequency: :days_based, interval_value: 30, next_due_date: nil)
        expect(schedule.reload.next_due_date).to be_present
      end

      it 'does not override next_due_date if provided' do
        custom_date = 10.days.from_now
        schedule = create(:maintenance_schedule, product: product, company: company, next_due_date: custom_date)
        expect(schedule.reload.next_due_date).to be_within(1.second).of(custom_date)
      end
    end

    describe 'check_and_mark_overdue' do
      it 'automatically marks as overdue when next_due_date changes to past' do
        schedule = create(:maintenance_schedule, product: product, company: company, next_due_date: 5.days.from_now, status: :scheduled)
        schedule.update(next_due_date: 2.days.ago)
        expect(schedule.reload.status).to eq('overdue')
      end
    end
  end
end
