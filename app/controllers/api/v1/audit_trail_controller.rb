# app/controllers/api/v1/audit_trail_controller.rb
class Api::V1::AuditTrailController < ApplicationController
  # GET /api/v1/audit_trail
  # Get all version history across all models
  def index
    @versions = PaperTrail::Version.includes(:item)
                                   .order(created_at: :desc)
                                   .page(params[:page])
                                   .per(params[:per_page] || 50)

    # Filter by model type
    @versions = @versions.where(item_type: params[:item_type]) if params[:item_type].present?

    # Filter by date range
    @versions = @versions.where('created_at >= ?', params[:from]) if params[:from].present?
    @versions = @versions.where('created_at <= ?', params[:to]) if params[:to].present?

    # Filter by user (whodunnit)
    @versions = @versions.where(whodunnit: params[:user_id]) if params[:user_id].present?

    render json: {
      versions: @versions.map { |v| version_json(v) },
      meta: pagination_meta(@versions)
    }
  end

  # GET /api/v1/audit_trail/:model/:id
  # Get version history for a specific record
  def show
    model_class = params[:model].classify.constantize
    @record = model_class.find(params[:id])
    @versions = @record.versions.order(created_at: :desc)

    render json: {
      record: {
        type: params[:model],
        id: @record.id,
        current_state: @record.attributes
      },
      versions: @versions.map { |v| version_detail_json(v) },
      total_changes: @versions.count
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "#{params[:model]} not found" }, status: :not_found
  rescue NameError
    render json: { error: "Invalid model type" }, status: :bad_request
  end

  # POST /api/v1/audit_trail/:model/:id/revert/:version_id
  # Revert a record to a previous version
  def revert
    model_class = params[:model].classify.constantize
    @record = model_class.find(params[:id])
    @version = @record.versions.find(params[:version_id])

    previous_version = @version.reify
    if previous_version && previous_version.save
      render json: {
        message: "Successfully reverted to version #{@version.id}",
        record: @record.reload.attributes,
        reverted_at: Time.current
      }
    else
      render json: {
        error: "Failed to revert",
        errors: previous_version&.errors&.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Record or version not found" }, status: :not_found
  end

  # GET /api/v1/audit_trail/stats
  # Get audit trail statistics
  def stats
    render json: {
      total_changes: PaperTrail::Version.count,
      changes_today: PaperTrail::Version.where('created_at >= ?', Time.current.beginning_of_day).count,
      changes_this_week: PaperTrail::Version.where('created_at >= ?', 1.week.ago).count,
      changes_this_month: PaperTrail::Version.where('created_at >= ?', 1.month.ago).count,
      by_model: PaperTrail::Version.group(:item_type).count,
      by_event: PaperTrail::Version.group(:event).count,
      most_active_users: PaperTrail::Version.where.not(whodunnit: nil)
                                             .group(:whodunnit)
                                             .count
                                             .sort_by { |_, count| -count }
                                             .first(10)
                                             .to_h
    }
  end

  private

  def version_json(version)
    {
      id: version.id,
      event: version.event, # created, updated, destroyed
      item_type: version.item_type,
      item_id: version.item_id,
      whodunnit: version.whodunnit, # User ID who made the change
      created_at: version.created_at,
      changes_summary: changes_summary(version)
    }
  end

  def version_detail_json(version)
    version_json(version).merge(
      object: version.object ? JSON.parse(version.object) : nil,
      object_changes: version.object_changes ? JSON.parse(version.object_changes) : nil
    )
  end

  def changes_summary(version)
    return {} unless version.object_changes

    changes = JSON.parse(version.object_changes)
    changes.transform_values do |change_array|
      {
        from: change_array[0],
        to: change_array[1]
      }
    end
  rescue JSON::ParserError
    {}
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      next_page: collection.next_page,
      prev_page: collection.prev_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end
end
