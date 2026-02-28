# app/controllers/api/v1/products_controller.rb
module Api
  module V1
    class ProductsController < ApplicationController
      before_action :set_product, only: [:show, :update, :destroy, :availability, :attach_images, :remove_image, :transfer, :archive, :unarchive, :increment_stock, :decrement_stock, :restock, :maintenance_history, :override_maintenance]

      # GET /api/v1/products
      def index
        @products = Product.includes(:product_type, :storage_location).all

        # Active/inactive filter
        @products = @products.where(active: true, deleted: false) unless params[:include_inactive] == 'true'

        # Archived filter
        @products = @products.where(archived: false) unless params[:include_archived] == 'true'

        # Search filter
        @products = @products.search(params[:query]) if params[:query].present?

        # Category filter
        @products = @products.by_category(params[:category]) if params[:category].present?

        # Price range filter
        if params[:min_price].present?
          min_cents = (params[:min_price].to_f * 100).to_i
          @products = @products.where('daily_price_cents >= ?', min_cents)
        end
        if params[:max_price].present?
          max_cents = (params[:max_price].to_f * 100).to_i
          @products = @products.where('daily_price_cents <= ?', max_cents)
        end

        # Quantity filter (minimum available quantity)
        if params[:min_quantity].present?
          @products = @products.where('quantity >= ?', params[:min_quantity].to_i)
        end

        # Sorting
        sort_by = params[:sort_by] || 'created_at'
        sort_order = params[:sort_order] || 'desc'

        case sort_by
        when 'name'
          @products = @products.order(name: sort_order)
        when 'price'
          @products = @products.order(daily_price_cents: sort_order)
        when 'quantity'
          @products = @products.order(quantity: sort_order)
        when 'category'
          @products = @products.order(category: sort_order, name: :asc)
        else
          @products = @products.order(created_at: sort_order)
        end

        @products = @products.page(params[:page]).per(params[:per_page] || 25)

        render json: {
          products: @products.map { |p| product_json(p) },
          meta: pagination_meta(@products),
          filters_applied: {
            query: params[:query],
            category: params[:category],
            min_price: params[:min_price],
            max_price: params[:max_price],
            min_quantity: params[:min_quantity],
            sort_by: sort_by,
            sort_order: sort_order
          }
        }
      end

      # GET /api/v1/products/:id
      def show
        render json: {
          product: product_detail_json(@product)
        }
      end

      # POST /api/v1/products
      def create
        @product = Product.new(product_params)
        @product.company = ActsAsTenant.current_tenant if ActsAsTenant.current_tenant

        if @product.save
          render json: {
            product: product_detail_json(@product),
            message: "Product created successfully"
          }, status: :created
        else
          render json: {
            errors: @product.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/products/:id
      def update
        if @product.update(product_params)
          render json: {
            product: product_detail_json(@product),
            message: "Product updated successfully"
          }
        else
          render json: {
            errors: @product.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/products/:id
      def destroy
        @product.update(active: false)
        render json: {
          message: "Product archived successfully"
        }
      end

      # GET /api/v1/products/:id/availability
      def availability
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : start_date + 7.days

        checker = AvailabilityChecker.new(@product, start_date, end_date)

        render json: {
          product_id: @product.id,
          product_name: @product.name,
          total_quantity: @product.quantity,
          available_quantity: checker.available_quantity,
          is_available: checker.available?,
          date_range: {
            start: start_date,
            end: end_date
          },
          availability_by_date: checker.availability_by_date
        }
      end

      # POST /api/v1/products/:id/attach_images
      def attach_images
        if params[:images].present?
          @product.images.attach(params[:images])
          render json: {
            message: "Images attached successfully",
            images: @product.images.map { |img| { id: img.id, url: rails_blob_url(img) } }
          }
        else
          render json: { error: "No images provided" }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/products/:id/remove_image/:image_id
      def remove_image
        image = @product.images.find(params[:image_id])
        image.purge
        render json: { message: "Image removed successfully" }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Image not found" }, status: :not_found
      end

      # GET /api/v1/products/search_by_barcode/:barcode
      def search_by_barcode
        @product = Product.includes(:product_type, :storage_location)
                         .find_by(barcode: params[:barcode])

        if @product
          render json: {
            product: product_detail_json(@product),
            found: true
          }
        else
          render json: {
            found: false,
            message: "No product found with barcode: #{params[:barcode]}"
          }, status: :not_found
        end
      end

      # POST /api/v1/products/:id/transfer
      def transfer
        new_location = Location.find(params[:location_id])

        old_location = @product.storage_location
        @product.update!(storage_location: new_location)

        render json: {
          message: "Product transferred successfully",
          product: product_json(@product),
          transfer: {
            from: old_location ? { id: old_location.id, name: old_location.name, full_path: old_location.full_path } : nil,
            to: { id: new_location.id, name: new_location.name, full_path: new_location.full_path }
          }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Location not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # PATCH /api/v1/products/:id/archive
      def archive
        @product.update!(archived: true)
        render json: {
          message: "Product archived",
          product: product_json(@product)
        }
      end

      # PATCH /api/v1/products/:id/unarchive
      def unarchive
        @product.update!(archived: false)
        render json: {
          message: "Product unarchived",
          product: product_json(@product)
        }
      end

      # POST /api/v1/products/:id/increment_stock
      # Add stock for sale items
      def increment_stock
        unless @product.item_type_sale?
          return render json: {
            error: "Stock management is only available for sale items"
          }, status: :unprocessable_entity
        end

        quantity = params[:quantity].to_i

        if quantity <= 0
          return render json: {
            error: "Quantity must be greater than 0"
          }, status: :unprocessable_entity
        end

        @product.increment_stock!(quantity)

        render json: {
          message: "Stock increased by #{quantity}",
          product: stock_json(@product)
        }
      end

      # POST /api/v1/products/:id/decrement_stock
      # Remove stock for sale items (manual sale/damage/loss)
      def decrement_stock
        unless @product.item_type_sale?
          return render json: {
            error: "Stock management is only available for sale items"
          }, status: :unprocessable_entity
        end

        quantity = params[:quantity].to_i

        if quantity <= 0
          return render json: {
            error: "Quantity must be greater than 0"
          }, status: :unprocessable_entity
        end

        @product.decrement_stock!(quantity)

        render json: {
          message: "Stock decreased by #{quantity}",
          product: stock_json(@product)
        }
      rescue ActiveRecord::RecordInvalid => e
        render json: {
          error: e.message
        }, status: :unprocessable_entity
      end

      # POST /api/v1/products/:id/restock
      # Set stock to specific amount
      def restock
        unless @product.item_type_sale?
          return render json: {
            error: "Stock management is only available for sale items"
          }, status: :unprocessable_entity
        end

        new_stock = params[:stock_on_hand].to_i

        if new_stock < 0
          return render json: {
            error: "Stock cannot be negative"
          }, status: :unprocessable_entity
        end

        old_stock = @product.stock_on_hand
        @product.update!(stock_on_hand: new_stock)

        render json: {
          message: "Stock updated from #{old_stock} to #{new_stock}",
          product: stock_json(@product)
        }
      end

      # GET /api/v1/products/:id/maintenance_history
      # Show all maintenance schedules, logs, and jobs for this product
      def maintenance_history
        schedules = @product.maintenance_schedules
                           .includes(:assigned_to, :maintenance_logs)
                           .order(created_at: :desc)

        jobs = @product.maintenance_jobs
                      .includes(:assigned_to, :performed_by)
                      .order(scheduled_for: :desc)

        render json: {
          product: {
            id: @product.id,
            name: @product.name,
            maintenance_status: @product.maintenance_status,
            maintenance_override: @product.maintenance_override_by_id.present? ? {
              overridden_by: @product.maintenance_override_by&.name,
              reason: @product.maintenance_override_reason,
              overridden_at: @product.maintenance_override_at
            } : nil
          },
          maintenance_schedules: schedules.map { |schedule| maintenance_schedule_json(schedule) },
          maintenance_jobs: jobs.map { |job| maintenance_job_json(job) },
          summary: {
            total_schedules: schedules.count,
            active_schedules: schedules.where(enabled: true).count,
            overdue_schedules: schedules.where(enabled: true).where('next_due_date < ?', Time.current).count,
            total_jobs: jobs.count,
            pending_jobs: jobs.where(status: :pending).count,
            completed_jobs: jobs.where(status: :completed).count
          }
        }
      end

      # POST /api/v1/products/:id/override_maintenance
      # Allow admin to override maintenance requirements temporarily
      def override_maintenance
        unless current_user&.admin? || current_user&.manager?
          return render json: {
            error: "Only admins and managers can override maintenance requirements"
          }, status: :forbidden
        end

        unless params[:reason].present?
          return render json: {
            error: "Reason is required for maintenance override"
          }, status: :unprocessable_entity
        end

        @product.allow_maintenance_override!(
          user: current_user,
          reason: params[:reason]
        )

        render json: {
          message: "Maintenance override applied successfully",
          product: {
            id: @product.id,
            name: @product.name,
            maintenance_status: @product.maintenance_status,
            maintenance_override: {
              overridden_by: current_user.name,
              reason: params[:reason],
              overridden_at: @product.maintenance_override_at
            }
          },
          warning: "This override should only be used for emergency rentals. Please schedule maintenance as soon as possible."
        }
      rescue ActiveRecord::RecordInvalid => e
        render json: {
          errors: e.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      private

      def set_product
        @product = Product.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Product not found" }, status: :not_found
      end

      def product_params
        params.require(:product).permit(
          :name, :description, :category, :barcode,
          :daily_price_cents, :daily_price_currency,
          :weekly_price_cents, :weekly_price_currency,
          :sale_price_cents, :sale_price_currency,
          :value_cents, :mass, :asset_tag,
          :product_type_id, :storage_location_id,
          :quantity, :active, :archived, :show_public, :end_date,
          :item_type, :tracks_inventory, :stock_on_hand, :reorder_point,
          serial_numbers: [], custom_fields: {}, images: []
        )
      end

      def product_json(product)
        base_json = {
          id: product.id,
          name: product.name,
          description: product.description,
          category: product.category,
          barcode: product.barcode,
          asset_tag: product.asset_tag,
          item_type: product.item_type,
          daily_price: {
            amount: product.daily_price_cents,
            currency: product.daily_price_currency,
            formatted: product.daily_price&.format
          },
          weekly_price: {
            amount: product.weekly_price_cents,
            currency: product.weekly_price_currency,
            formatted: product.weekly_price&.format
          },
          value: {
            amount: product.value_cents,
            currency: product.daily_price_currency,
            formatted: Money.new(product.value_cents || 0, product.daily_price_currency).format
          },
          mass: product.mass,
          quantity: product.quantity,
          available_quantity: product.quantity, # Total quantity, use availability endpoint for date-specific checks
          active: product.active,
          archived: product.archived,
          show_public: product.show_public,
          product_type: product.product_type ? {
            id: product.product_type_id,
            name: product.product_type.name,
            full_name: product.product_type.full_name
          } : nil,
          storage_location: product.storage_location ? {
            id: product.storage_location_id,
            name: product.storage_location.name,
            full_path: product.storage_location.full_path
          } : nil,
          created_at: product.created_at,
          updated_at: product.updated_at
        }

        # Add sale price for sale items
        if product.item_type_sale?
          base_json[:sale_price] = {
            amount: product.sale_price_cents,
            currency: product.sale_price_currency,
            formatted: product.sale_price&.format
          }
        end

        # Add stock info for sale items
        if product.item_type_sale? && product.tracks_inventory?
          base_json[:stock] = {
            on_hand: product.stock_on_hand,
            reorder_point: product.reorder_point,
            out_of_stock: product.out_of_stock?,
            low_stock: product.low_stock?
          }
        end

        base_json
      end

      def product_detail_json(product)
        product_json(product).merge({
          serial_numbers: product.serial_numbers,
          custom_fields: product.custom_fields,
          end_date: product.end_date,
          images: product.images.attached? ? product.images.map { |img| rails_blob_url(img) } : [],
          product_type_detail: product.product_type ? {
            id: product.product_type.id,
            name: product.product_type.name,
            full_name: product.product_type.full_name,
            manufacturer: product.product_type.manufacturer&.name,
            category: product.product_type.category,
            description: product.product_type.description
          } : nil
        })
      end

      def stock_json(product)
        {
          id: product.id,
          name: product.name,
          item_type: product.item_type,
          stock_on_hand: product.stock_on_hand,
          reorder_point: product.reorder_point,
          tracks_inventory: product.tracks_inventory,
          out_of_stock: product.out_of_stock?,
          low_stock: product.low_stock?,
          sale_price: product.sale_price&.format,
          updated_at: product.updated_at
        }
      end

      def maintenance_schedule_json(schedule)
        {
          id: schedule.id,
          name: schedule.name,
          description: schedule.description,
          frequency: schedule.frequency,
          interval_value: schedule.interval_value,
          interval_unit: schedule.interval_unit,
          last_completed_at: schedule.last_completed_at,
          next_due_date: schedule.next_due_date,
          status: schedule.status,
          enabled: schedule.enabled,
          assigned_to: schedule.assigned_to ? {
            id: schedule.assigned_to.id,
            name: schedule.assigned_to.name
          } : nil,
          maintenance_logs_count: schedule.maintenance_logs.count,
          created_at: schedule.created_at
        }
      end

      def maintenance_job_json(job)
        {
          id: job.id,
          title: job.title,
          description: job.description,
          maintenance_type: job.maintenance_type,
          status: job.status,
          priority: job.priority,
          scheduled_for: job.scheduled_for,
          started_at: job.started_at,
          completed_at: job.completed_at,
          assigned_to: job.assigned_to ? {
            id: job.assigned_to.id,
            name: job.assigned_to.name
          } : nil,
          performed_by: job.performed_by ? {
            id: job.performed_by.id,
            name: job.performed_by.name
          } : nil,
          recurring: job.recurring,
          estimated_duration_hours: job.estimated_duration_hours,
          actual_duration_hours: job.actual_duration_hours,
          cost: job.total_cost_cents ? {
            amount: job.total_cost_cents,
            currency: job.total_cost_currency,
            formatted: Money.new(job.total_cost_cents, job.total_cost_currency || 'USD').format
          } : nil,
          created_at: job.created_at
        }
      end
    end
  end
end
