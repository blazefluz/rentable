class ContractPdfGenerator
  require 'prawn'

  def initialize(contract)
    @contract = contract
  end

  def generate
    Prawn::Document.new do |pdf|
      # Header
      pdf.font_size 24
      pdf.text @contract.title, align: :center, style: :bold
      pdf.move_down 10

      # Contract metadata
      pdf.font_size 10
      pdf.text "Contract ID: #{@contract.id}", align: :right
      pdf.text "Version: #{@contract.version}", align: :right
      pdf.text "Type: #{@contract.contract_type.humanize}", align: :right
      pdf.text "Effective Date: #{@contract.effective_date}", align: :right if @contract.effective_date
      pdf.text "Expiry Date: #{@contract.expiry_date}", align: :right if @contract.expiry_date
      pdf.move_down 20

      # Booking information if associated
      if @contract.booking
        pdf.font_size 12
        pdf.text "Booking Information", style: :bold
        pdf.move_down 5
        pdf.font_size 10
        pdf.text "Booking Reference: #{@contract.booking.reference_number}"
        pdf.text "Customer: #{@contract.booking.customer_name}"
        pdf.text "Rental Period: #{@contract.booking.start_date.strftime('%B %d, %Y')} - #{@contract.booking.end_date.strftime('%B %d, %Y')}"
        pdf.move_down 20
      end

      # Contract content
      pdf.font_size 11
      pdf.text @contract.content, align: :justify

      pdf.move_down 30

      # Signature section
      if @contract.requires_signature?
        pdf.font_size 12
        pdf.text "Signatures", style: :bold
        pdf.move_down 10

        signatures = @contract.contract_signatures.signed.order(signed_at: :asc)
        if signatures.any?
          signatures.each do |sig|
            pdf.font_size 10
            pdf.text "#{sig.signer_role.humanize}: #{sig.signer_name}"
            pdf.text "Email: #{sig.signer_email}"
            pdf.text "Signed at: #{sig.signed_at.strftime('%B %d, %Y at %I:%M %p')}"
            pdf.text "IP Address: #{sig.ip_address}" if sig.ip_address

            if sig.witness_name.present?
              pdf.text "Witnessed by: #{sig.witness_name}"
            end

            pdf.move_down 15
          end
        else
          pdf.font_size 10
          pdf.text "Pending signatures..."
          pdf.move_down 10

          @contract.determine_required_roles.each do |role|
            pdf.text "#{role.humanize} signature: _____________________"
            pdf.text "Date: _____________________"
            pdf.move_down 15
          end
        end
      end

      # Footer with generation timestamp
      pdf.move_down 20
      pdf.font_size 8
      pdf.text "Generated on #{Time.current.strftime('%B %d, %Y at %I:%M %p')}", align: :center

      # Page numbers on all pages
      pdf.number_pages "Page <page> of <total>",
        at: [pdf.bounds.right - 150, 0],
        align: :right,
        size: 8
    end.render
  end
end
