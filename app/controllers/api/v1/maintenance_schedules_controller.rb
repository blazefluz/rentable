# app/controllers/api/v1/maintenance_schedules_controller.rb
module Api
  module V1
    class MaintenanceSchedulesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_maintenance_schedule, only: [:show, :update, :destroy, :complete]

      # GET /api/v1/maintenance_schedules
      def index
        @maintenance_schedules = MaintenanceSchedule
          .includes(:product, :assigned_to, :maintenance_logs)
          .where(company: current_company)

        # Filter by product if specified
        @maintenance_schedules = @maintenance_schedules.for_product(params[:product_id]) if params[:product_id].present?

        # Filter by assigned user if specified
        @maintenance_schedules = @maintenance_schedules.assigned_to_user(params[:assigned_to_id]) if params[:assigned_to_id].present?

        # Filter by status
        @maintenance_schedules = @maintenance_schedules.where(status: params[:status]) if params[:status].present?

        # Filter by enabled
        @maintenance_schedules = @maintenance_schedules.enabled if params[:enabled] == 'true'

        # Order by next due date
        @maintenance_schedules = @maintenance_schedules.order(:next_due_date)

        render json: {
          maintenance_schedules: @maintenance_schedules.map { |schedule| schedule_json(schedule) },
          meta: {
            total: @maintenance_schedules.count
          }
        }
      end

      # GET /api/v1/maintenance_schedules/due
      def due
        days = params[:days]&.to_i || 7
        @due_schedules = MaintenanceScheduleService.upcoming_maintenance(
          company: current_company,
          days: days
        )

        render json: {
          maintenance_schedules: @due_schedules.map { |schedule| schedule_json(schedule) },
          meta: {
            days: days,
            total: @due_schedules.count
          }
        }
      end

      # GET /api/v1/maintenance_schedules/overdue
      def overdue
        @overdue_schedules = MaintenanceScheduleService.overdue_maintenance(
          company: current_company
        )

        render json: {
          maintenance_schedules: @overdue_schedules.map { |schedule| schedule_json(schedule) },
          meta: {
            total: @overdue_schedules.count
          }
        }
      end

      # GET /api/v1/maintenance_schedules/:id
      def show
        render json: {
          maintenance_schedule: schedule_json(@maintenance_schedule, include_logs: true)
        }
      end

      # POST /api/v1/maintenance_schedules
      def create
        product = Product.find(params[:product_id])

        result = MaintenanceScheduleService.create_schedule(
          product: product,
          params: schedule_params,
          company: current_company
        )

        if result[:success]
          render json: {
            maintenance_schedule: schedule_json(result[:schedule]),
            message: 'Maintenance schedule created successfully'
          }, status: :created
        else
          render json: {
            errors: result[:errors].full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/maintenance_schedules/:id
      def update
        result = MaintenanceScheduleService.update_schedule(
          schedule: @maintenance_schedule,
          params: schedule_params
        )

        if result[:success]
          render json: {
            maintenance_schedule: schedule_json(result[:schedule]),
            message: 'Maintenance schedule updated successfully'
          }
        else
          render json: {
            errors: result[:errors].full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/maintenance_schedules/:id
      def destroy
        if @maintenance_schedule.destroy
          render json: {
            message: 'Maintenance schedule deleted successfully'
          }
        else
          render json: {
            errors: @maintenance_schedule.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/maintenance_schedules/:id/complete
      def complete
        result = MaintenanceScheduleService.complete_maintenance(
          schedule: @maintenance_schedule,
          completed_by: current_user,
          notes: params[:notes]
        )

        if result[:success]
          render json: {
            maintenance_schedule: schedule_json(result[:schedule]),
            maintenance_log: log_json(result[:log]),
            message: 'Maintenance completed successfully. Next due date calculated.'
          }
        else
          render json: {
            errors: result[:errors].full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def set_maintenance_schedule
        @maintenance_schedule = MaintenanceSchedule
          .includes(:product, :assigned_to, :maintenance_logs)
          .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Maintenance schedule not found' }, status: :not_found
      end

      def schedule_params
        params.require(:maintenance_schedule).permit(
          :name,
          :description,
          :frequency,
          :interval_value,
          :interval_unit,
          :assigned_to_id,
          :enabled,
          :next_due_date
        )
      end

      def schedule_json(schedule, include_logs: false)
        {
          id: schedule.id,
          product_id: schedule.product_id,
          product_name: schedule.product&.name,
          name: schedule.name,
          description: schedule.description,
          frequency: schedule.frequency,
          interval_value: schedule.interval_value,
          interval_unit: schedule.interval_unit,
          schedule_description: schedule.schedule_description,
          last_completed_at: schedule.last_completed_at,
          next_due_date: schedule.next_due_date,
          days_until_due: schedule.days_until_due,
          status: schedule.status,
          enabled: schedule.enabled,
          assigned_to: schedule.assigned_to ? user_json(schedule.assigned_to) : nil,
          overdue: schedule.overdue?,
          due_soon: schedule.due_soon?,
          created_at: schedule.created_at,
          updated_at: schedule.updated_at
        }.tap do |json|
          if include_logs
            json[:maintenance_logs] = schedule.maintenance_logs.recent.map { |log| log_json(log) }
          end
        end
      end

      def log_json(log)
        {
          id: log.id,
          completed_at: log.completed_at,
          performed_by: log.performed_by ? user_json(log.performed_by) : nil,
          notes: log.notes,
          created_at: log.created_at
        }
      end

      def user_json(user)
        {
          id: user.id,
          name: user.name,
          email: user.email
        }
      end

      def current_company
        current_user&.company || ActsAsTenant.current_tenant
      end
    end
  end
end
