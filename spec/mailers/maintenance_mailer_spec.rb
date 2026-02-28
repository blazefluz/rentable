require "rails_helper"

RSpec.describe MaintenanceMailer, type: :mailer do
  describe "maintenance_due" do
    let(:mail) { MaintenanceMailer.maintenance_due }

    it "renders the headers" do
      expect(mail.subject).to eq("Maintenance due")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "maintenance_overdue" do
    let(:mail) { MaintenanceMailer.maintenance_overdue }

    it "renders the headers" do
      expect(mail.subject).to eq("Maintenance overdue")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "maintenance_completed" do
    let(:mail) { MaintenanceMailer.maintenance_completed }

    it "renders the headers" do
      expect(mail.subject).to eq("Maintenance completed")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "job_assigned" do
    let(:mail) { MaintenanceMailer.job_assigned }

    it "renders the headers" do
      expect(mail.subject).to eq("Job assigned")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
